fixtureLoader = require '../src/fixtures-loader'
sinon = require 'sinon'
sinonChai = require 'sinon-chai'
chai    = require 'chai'
expect  = chai.expect
chai.use(sinonChai)

describe 'loopback-fixtures', ->

  sandbox = null

  beforeEach (done) ->
    sandbox = sinon.sandbox.create()
    done()

  afterEach (done) ->
    sandbox.restore()
    done()

  describe 'getRandomMatchingObject method', ->
    fixtureLoader.savedData =
      group_yellow: id: 1
      group_red: id: 2
      blue_team: id: 3

    it 'should give a random matching object (2 results wildcard)', (done) ->
      pattern = 'group_*'
      object = fixtureLoader.getRandomMatchingObject pattern
      expect(object).to.be.oneOf [fixtureLoader.savedData.group_yellow, fixtureLoader.savedData.group_red]
      done()

    it 'should give a random matching object (1 result with wildcard)', (done) ->
      pattern = 'blue_.*'
      object = fixtureLoader.getRandomMatchingObject pattern
      expect(object).to.eql fixtureLoader.savedData.blue_team
      done()

    it 'should give a random matching object (1 result with exact pattern)', (done) ->
      pattern = 'blue_team'
      object = fixtureLoader.getRandomMatchingObject pattern
      expect(object).to.eql fixtureLoader.savedData.blue_team
      done()

    it 'should give a random matching object (no result)', (done) ->
      pattern = 'no_result.*'
      object = fixtureLoader.getRandomMatchingObject pattern
      expect(object).to.be.undefined
      done()


  describe 'replaceReferenceInObjects method', ->

    describe 'should call replaceReferenceInObjects with the right parameters', ->

      beforeEach (done) ->
        fixtureLoader.savedData =
          group_yellow: id: 1
          group_red: id: 2
          user: groupId: '@group_yellow'
        done()

      beforeEach (done) ->
        sandbox.stub(
          fixtureLoader
          'getRandomMatchingObject'
          (pattern) -> fixtureLoader.savedData.group_yellow
        )
        done()

      it 'with existing reference', ->
        fixtureLoader.replaceReferenceInObjects fixtureLoader.savedData.user
        .then ->
          expect(fixtureLoader.getRandomMatchingObject).to.have.been.calledWith '^group_yellow$'

      it 'and remplace reference key', ->
        fixtureLoader.replaceReferenceInObjects fixtureLoader.savedData.user
        .then ->
          expect(fixtureLoader.savedData.user.groupId).to.eql 1

    describe 'should call replaceReferenceInObjects with the right parameters', ->
      beforeEach (done) ->
        fixtureLoader.savedData =
          group_yellow: id: 1
          group_red: id: 2
          user: groupId: '@group_blue'
        done()

      beforeEach (done) ->
        sandbox.stub(
          fixtureLoader
          'getRandomMatchingObject'
          (pattern) -> undefined
        )
        done()

      it 'and raised error', (done) ->
        fixtureLoader.replaceReferenceInObjects fixtureLoader.savedData.user
        .then ->
          done(new Error 'it should not be called')
        .catch ->
          done()
        return
