clean = require 'gulp-clean'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
concat = require 'gulp-concat'
gulp = require 'gulp'
mocha = require 'gulp-mocha'
plumber = require 'gulp-plumber'
runSequence = require 'run-sequence'

gulp.task 'watch', ['build'], ->
  gulp.watch 'src/**', ['build']

#gulp.task 'publish', (done) ->
#  runSequence 'build', 'test', 'npm-publish', done

gulp.task 'build', (done) ->
  runSequence 'clean', 'compile', done

gulp.task 'clean', ->
  gulp.src 'lib', read: false
  .pipe clean force: true

gulp.task 'compile', (done) ->
  runSequence 'coffeelint', 'coffee', done

gulp.task 'coffeelint', ->
  gulp.src 'src/**/*.coffee'
  .pipe(coffeelint())
  .pipe(coffeelint.reporter())

gulp.task 'coffee', ->
  gulp.src 'src/**/*.coffee'
  .pipe coffee bare: true
  .pipe gulp.dest 'lib/'

gulp.task 'test', ->
  gulp.src './test/{,**}/*.{json,coffee}', read: false
  .pipe plumber()
  .pipe mocha
    compilers: 'coffee:coffee-script'
    require: [
      'coffee-script/register'
    ]
