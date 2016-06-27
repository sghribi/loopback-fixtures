`#!/usr/bin/env node
`

optimist = require 'optimist'
app = require '../../../server/server'

run = ->
  app.loadFixtures()
  .then ->
    process.exit 0

argv = optimist.default
  append: false
  table: '/fixtures/data/'
.usage 'Usage: load-fixtures [options]'
.alias 'h', 'help'
.alias 'h', '?'
.boolean 'h'
.describe 'version', 'Print version info.'
.alias 'i', 'version'
.boolean 'version'
.argv

if argv.version
  console.log module.exports.version
  process.exit 0

if argv.help
  optimist.showHelp()
  process.exit 1

run()
