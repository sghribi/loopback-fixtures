fixtureLoader = require './fixtures-loader'

fixturePath = '/fixtures/data/'

module.exports = (app, options) ->
  fixtureLoader.loadFixtures app.models, fixturePath, (ern, result) ->
    console.log arguments
