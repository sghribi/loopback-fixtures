_ = require 'lodash'
async = require 'async'
fs = require 'fs'
loopback = require 'loopback'
merge = require 'merge'
path = require 'path'
q = require 'q'
YAML = require 'yamljs'

savedData = {}

module.exports =

  purgeDatabase: (models) ->
    promises = []
    _.forEach models, (model) =>
      promises.push @purgeModel(model)
    q.all promises

  purgeModel: (model) ->
    purgingModel = q.defer()
    model.destroyAll (err) ->
      if err
        purgingModel.reject err
      else
        purgingModel.resolve()
      purgingModel.promise


  replaceReferenceInObjects: (object) ->
    _.each object, (value, key) ->
      if _.values(value)?[0] == '@'
        identifier = value.replace '@', ''
        savedId = savedData?[identifier]?.id
        if savedId
          object[key] = savedId
        else
          console.log '[ERROR] Please provide object for @' + identifier
          process.exit 1

  applyHelpers: (data) ->
    expandedData = {}

    # Repeat "identifier{a..b}"
    _.each data, (object, identifier) ->
      regex = /(\w+)\{(\d+)..(\d+)\}$/
      match = identifier.match(regex)

      # If pattern detected
      if match?.length is 4
        identifier = match[1]
        min = parseInt match[2]
        max = parseInt match[3]

        # Duplicate object ...
        for i in [min..max]
          expandedData[identifier + i] = _.clone object
          # ... and replace {@} occurences
          _.each object, (value, key) ->
            if typeof value is 'string'
              newValue = value.replace '{@}', i.toString()
            else
              newValue = value
            expandedData[identifier + i][key] = newValue
      else
        expandedData[identifier] = object

    # Exec function
    _.each expandedData, (object, identifier) ->
      _.each object, (value, key) ->
        try
          fn = eval value
          expandedData[identifier][key] = fn
        catch e

    return expandedData

  loadFixtures: (models, fixturesPath, callback) ->
    # Get all yml files
    fixturePath = path.join process.cwd(), fixturesPath
    fixtureFolderContents = fs.readdirSync fixturePath
    fixtures = fixtureFolderContents.filter (fileName) ->
      fileName.match /\.yml$/

    # For each yml file
    async.eachSeries fixtures, (fixture, nextFile) =>
      fixtureData = YAML.load(fixturePath + fixture)

      # For each model in yml file
      async.eachOfSeries fixtureData, (modelData, modelName, nextModel) =>
        modelData = @applyHelpers modelData
        # For each object for this model
        async.eachOfSeries modelData, (object, identifier, nextObject) =>
        # Replace stored '@' references
          object = @replaceReferenceInObjects object
          # Save object in database
          models[modelName].create object, (err, savedObject) ->
            return nextObject(err) if err
            savedData[identifier] = savedObject
            console.log '[' + modelName + '] - ' + identifier + ' imported (id : ' + savedObject.id + ')'
            nextObject()
        , (err) ->
          return nextModel(err) if err
          nextModel()
      , (err) ->
        return nextFile(err) if err
        nextFile()
    , (err) ->
      return callback(err) if err
      callback()
