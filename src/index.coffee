fixtureLoader = require './fixtures-loader'
merge = require 'merge'
q = require 'q'

module.exports = (app, options) ->
  options = merge
    fixturePath: '/fixtures/data/'
    append: false
    autoLoad: false
  , options

  loadFixtures = ->
    promises = []
    if not options.append
      promises.push fixtureLoader.purgeDatabase(app.models)
    promises.push fixtureLoader.loadFixtures(app.models, options.fixturePath)
    promises.reduce q.when

  console.log 'Starting loading'

  if options.autoLoad
    loadFixtures()

  app.loadFixtures = ->
    loadFixtures()
