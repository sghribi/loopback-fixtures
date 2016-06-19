fixtureLoader = require './fixtures-loader'
merge = require 'merge'
q = require 'q'

module.exports = (app, options) ->
  options = merge
    fixturePath: '/fixtures/data/'
    append: false
    autoLoad: false
  , options

  promises = []
  if not options.append
    promises.push fixtureLoader.purgeDatabase(app.models)
  promises.push fixtureLoader.loadFixtures(app.models, options.fixturePath)

  app.loadFixtures = ->
    promises.reduce q.when

  console.log 'Starting loading'

  if options.autoLoad
    app.loadFixtures()
    .then ->
      console.log 'Fixtures loaded!'
    .catch (err) ->
      console.log 'Errors on fixtures loading:', err
