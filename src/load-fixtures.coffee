#!/usr/bin/env node

require 'coffee-script/register'
optimist = require 'optimist'
app = require '../../../server/server'
fixtureLoader = require './fixtures-loader'

run = ->
  append = argv.append
  fixturePath = argv.fixturePath

  if not append
    fixtureLoader.purgeDatabase app.models
    .then ->
      console.log 'Data purged'
      fixtureLoader.loadFixtures app.models, fixturePath
    .then ->
      console.log 'Data successfully loaded'
      process.exit 0
    .catch (err) ->
      console.log 'Error on fixtures loading:', err
      process.exit 1

  else
    fixtureLoader.loadFixtures app.models, fixturePath
    .then ->
      console.log 'Data successfully loaded'
      process.exit 0
    .catch (err) ->
      console.log 'Error on fixtures loading:', err
      process.exit 1

argv = optimist.default
  append: false
  fixturePath: '/fixtures/data/'
.usage 'Usage: load-fixtures [options]'

.alias 'h', 'help'
.alias 'h', '?'
.boolean 'h'

.describe 'version', 'Print version info.'
.alias 'i', 'version'
.boolean 'version'

.describe 'append', 'Append data instead of deleting.'
.alias 'a', 'append'
.boolean 'append'

.describe 'fixturePath', 'Fixture path.'
.alias 'f', 'fixturePath'
.string 'fixturePath'

.argv

if argv.version
  console.log module.exports.version
  process.exit 0

if argv.help
  optimist.showHelp()
  process.exit 1

run()
