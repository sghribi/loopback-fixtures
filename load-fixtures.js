#!/usr/bin/env node

var assert = require('assert');
var fs = require('fs');
var path = require('path');
var util = require('util');
var mkdirp = require('mkdirp');
var optimist = require('optimist');
var config = require('../lib/config.js');
var index = require('../index');
var log = require('../lib/log');
var pkginfo = require('pkginfo')(module, 'version');
var dotenv = require('dotenv');

//global declaration for detection like it's done in umigrate
dbm = require( '../' );
async = require( 'async' );

dotenv.load({ silent: true });

process.on('uncaughtException', function(err) {
  log.error(err.stack);
  process.exit(1);
});

var argv = optimist
  .default({
    append: false,
    table: '/fixtures/data/'
  })
  .usage('Usage: load-fixtures [options]')

  .describe('fixturePath', 'The directory containing your fixtures files.')
  .alias('m', 'fixturePath')
  .string('m')

  .describe('append', 'Append data instead of deleting all data.')
  .alias('a', 'append')
  .boolean('a')

  .alias('h', 'help')
  .alias('h', '?')
  .boolean('h')

  .describe('version', 'Print version info.')
  .alias('i', 'version')
  .boolean('version')

  .argv;

if (argv.version) {
  console.log(module.exports.version);
  process.exit(0);
}

if (argv.help || argv._.length === 0) {
  optimist.showHelp();
  process.exit(1);
}

global.fixturePath = argv.fixturePath;
global.append = argv.append;


function run() {
  optimist.showHelp();
  process.exit(1);
}

run();
