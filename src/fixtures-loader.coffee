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
    purgeModelPromises = []
    _.forEach models, (model) =>
      purgeModelPromises.push @purgeModel(model)
    q.all purgeModelPromises

  purgeModel: (model) ->
    purgingModel = q.defer()
    model.destroyAll (err) ->
      if err
        purgingModel.reject err
      else
        purgingModel.resolve()
      purgingModel.promise

  replaceReferenceInObjects: (object) ->
    replacingReferenceInObjects = q.defer()
    _.each object, (value, key) ->
      if _.values(value)?[0] == '@'
        identifier = value.replace '@', ''
        savedId = savedData?[identifier]?.id
        if savedId
          object[key] = savedId
        else
          replacingReferenceInObjects.reject '[ERROR] Please provide object for @' + identifier
    replacingReferenceInObjects.resolve()
    replacingReferenceInObjects.promise

  executeGenerators: (data) ->
    expandedData = {}
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
    return expandedData

  executeFunctions: (expandedData) ->
    _.each expandedData, (object, identifier) ->
      _.each object, (value, key) ->
        try
          fn = eval value
          expandedData[identifier][key] = fn
        catch e
    return expandedData

  applyHelpers: (data) ->
    # Repeat "identifier{a..b}"
    expandedData = @executeGenerators data
    # Exec function
    expandedData = @executeFunctions expandedData
    return expandedData

  loadYamlFixture: (models, fixtureData) ->
    loadingFixture = q.defer()
    # For each model in yml file
    async.eachOfSeries fixtureData, (modelData, modelName, nextModel) =>
      modelData = @applyHelpers modelData
      # For each object for this model
      async.eachOfSeries modelData, (object, identifier, nextObject) =>
        # Replace stored '@' references
        @replaceReferenceInObjects object
        .then ->
          # Save object in database
          models[modelName].create object, (err, savedObject) ->
            return nextObject(err) if err
            savedData[identifier] = savedObject
            console.log '[' + modelName + '] - ' + identifier + ' imported (id : ' + savedObject.id + ')'
            nextObject()
        .catch (err) ->
          nextObject err
      , (err) ->
        return nextModel(err) if err
        nextModel()
    , (err) ->
      if err
        loadingFixture.reject err
      else
        loadingFixture.resolve()
    loadingFixture.promise

  loadFixtures: (models, fixturesPath) ->
    # Get all yml files
    fixturePath = path.join process.cwd(), fixturesPath
    fixtureFolderContents = fs.readdirSync fixturePath
    fixtures = fixtureFolderContents.filter (fileName) ->
      fileName.match /\.yml$/

    loadingFixturesPromises = []

    # For each yml file
    _.each fixtures, (fixture) =>
      fixtureData = YAML.load(fixturePath + fixture)
      loadingFixturesPromises.push @loadYamlFixture models, fixtureData

    q.all loadingFixturesPromises
