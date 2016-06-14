fixtureLoader = require './fixtures-loader'
merge = require 'merge'
q = require 'q'

module.exports = (app, options) ->
  options = merge
    fixturePath: '/fixtures/data/'
    append: false
  , options

  promises = []
  if not options.append
    promises.push fixtureLoader.purgeDatabase(app.models)
  promises.push (fixtureLoader.loadFixtures app.models, options.fixturePath)

  app.loadFixtures = ->
    q.all promises

  console.log 'Starting loading'
  app.loadFixtures()
  .then ->
    console.log 'Done !'
  .catch (err) ->
    console.log 'Erreurs : ', err
