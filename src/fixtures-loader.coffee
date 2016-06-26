_ = require 'lodash'
async = require 'async'
faker = require 'faker'
fs = require 'fs'
loopback = require 'loopback'
merge = require 'merge'
path = require 'path'
q = require 'q'
YAML = require 'yamljs'

idKey = 'id'

module.exports =

  savedData: {}

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


  getRandomMatchingObject: (pattern) ->
    regex = new RegExp pattern
    objects = _.filter @savedData, (value, key) ->
      not _.isEmpty(key.match(regex))
    return _.sample objects


  replaceReferenceInObjects: (object) ->
    replacingReferenceInObjects = q.defer()

    _.each object, (value, key) =>
      if _.values(value)?[0] == '@'
        identifier = value.substring 1
        referencedObject = @getRandomMatchingObject identifier
        if referencedObject?[idKey]
          object[key] = referencedObject[idKey]
        else
          console.log '[ERROR] Please provide object for @' + identifier
          replacingReferenceInObjects.reject()
          return replacingReferenceInObjects.promise

    replacingReferenceInObjects.resolve()
    replacingReferenceInObjects.promise


  executeGenerators: (data) ->
    expandedData = {}

    _.each data, (object, identifier) ->
      # Try to identify "identifer{m..n}" pattern
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


  executeFaker: (data) ->
    _.each data, (object, identifier) ->
      _.each object, (value, key) ->
        try
          data[identifier][key] = faker.fake value
        catch e
          data[identifier][key] = value
    return data


  executeFunctions: (data) ->
    _.each data, (object, identifier) ->
      _.each object, (value, key) ->
        try
          fn = eval value
          data[identifier][key] = fn
        catch e
    return data


  applyHelpers: (data) ->
    # Repeat "identifier{a..b}"
    expandedData = @executeGenerators data
    # Execute faker {{name.lastname}} etc
    expandedData = @executeFaker expandedData
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
        .then =>
          # Save object in database
          models[modelName].create object, (err, savedObject) =>
            return nextObject(err) if err
            @savedData[identifier] = savedObject
            console.log "[#{modelName}] - #{identifier} imported (id : #{savedObject?[idKey]})"
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
