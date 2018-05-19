fixtureLoader = require './fixtures-loader'
merge = require 'merge'

module.exports = (app, options) ->
  options = merge
    fixturePath: '/fixtures/data/'
    append: false
    autoLoad: false
  , options

  loadFixtures = (opt)->
    if not options.append
      fixtureLoader.purgeDatabase app.models, opt
      .then ->
        console.log 'Data purged'
        fixtureLoader.loadFixtures app.models, options.fixturePath, opt
    else
      fixtureLoader.loadFixtures app.models, options.fixturePath, opt

  if options.autoLoad
    loadFixtures()

  app.loadFixtures = (opt) ->
    loadFixtures(opt)
