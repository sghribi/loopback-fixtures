_ = require 'lodash'
faker = require 'faker'
fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
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

    Promise.all loadingFixturesPromises


  purgeDatabase: (models) ->
    purgeModelPromises = []

    _.forEach models, (model) =>
      if model.hasOwnProperty 'destroyAll'
        purgeModelPromises.push @purgeModel(model)

    Promise.all purgeModelPromises


  purgeModel: (model) ->
    new Promise (resolve, reject) ->
      model.destroyAll (err) ->
        reject err if err
        resolve()


  getRandomMatchingObject: (pattern) ->
    regex = new RegExp pattern
    objects = _.filter @savedData, (value, key) ->
      not _.isEmpty(key.match(regex))
    return _.sample objects


  replaceReferenceInObjects: (object) ->
    new Promise (resolve, reject) =>

      _.each object, (value, key) =>
        if _.values(value)?[0] == '@'
          identifier = value.substring 1
          referencedObject = @getRandomMatchingObject "^"+identifier+"$"

          if referencedObject?[idKey]
            object[key] = referencedObject[idKey]
          else
            reject '[ERROR] Please provide object for @' + identifier

      resolve object


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
    fixtureData = _.map fixtureData, (data, index) ->
      fixtures: data
      name: index

    Promise.each fixtureData, (modelData) =>
      modelData.fixtures = @applyHelpers modelData.fixtures

      modelFixtures = _.map modelData.fixtures, (data, index) ->
        object: data
        identifier: index
      Promise.each modelFixtures, (fixture) =>
        @replaceReferenceInObjects fixture.object
        .then (object) ->
          models[modelData.name].create object
        .then (savedObject) =>
          @savedData[fixture.identifier] = savedObject
          console.log "[#{modelData.name}] - #{fixture.identifier} " +
                      "imported (id : #{savedObject?[idKey]})"
