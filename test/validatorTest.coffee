bodyParser = require 'body-parser'
chai = require 'chai'
express = require 'express'
http = require 'http'
request = require 'superagent'
validator = require 'validator'

should = chai.should()

port = 8989
host = 'http://localhost:' + port

log =
    err   : (obj) -> console.log JSON.stringify obj
    debug : (obj) -> console.log JSON.stringify obj

# Besides url and body there could also be query parameters.
# The test cases should be expanded to reflect this.
schema =
    '/test/:id'  :
        'GET'      :
            url      : ['id']
        'PUT'      :
            url      : ['id']
            body     : ['text']
    '/test/info' :
        'POST'     :
            body     : ['id', 'temp']

# There is no validator for 'text', i.e. as long as the parameter
# is there any value is accepted.
validators =
    id   : (x) ->
        return true unless validator.isInt x
        return true unless 1 <= x <= 2147483647
    temp : (x) ->
        return true unless validator.isFloat x
        return true unless -50 <= x <= 50

describe 'validator', ->
    validatorBase = require '../src/validator'
    validatorBase = validatorBase schema, validators, log

    server = undefined
    before () ->
        app = express()
        app.use bodyParser.json()
        app.use bodyParser.urlencoded extended : false

        # Be sure to put the actual paths, which are expanded here.
        # Otherwise the middleware has no access to the parameter.
        app.use ['/test/info', '/test/:id'], validatorBase.validate

        server = http
            .createServer app
            .listen port

        ack = (req, res) ->
            res.send {}

        app.post '/test/info', ack
        app.get '/test/:id', ack
        app.put '/test/:id', ack

    it '/test/:id get should work without parameters', (done) ->
        request
            .get host + '/test/17'
            .end (res) ->
                res.status.should.equal 200
                done()

    it '/test/:id get should fail with additional parameters', (done) ->
        request
            .get host + '/test/17'
            .query
                random : 'fail'
            .end (res) ->
                res.status.should.equal 400
                done()

    it '/test/:id get should fail with bad id', (done) ->
        request
            .get host + '/test/17a2'
            .end (res) ->
                res.status.should.equal 400
                done()

    it '/test/:id put should not work without body content', (done) ->
        request
            .put host + '/test/22'
            .send {}
            .end (res) ->
                res.status.should.equal 400
                done()

    it '/test/:id put should work with body containing text', (done) ->
        request
            .put host + '/test/22'
            .send
                text : 'anything goes here'
            .end (res) ->
                res.status.should.equal 200
                done()

    it '/test/info post should not work with only id', (done) ->
        request
            .post host + '/test/info'
            .send
                id : '1000'
            .end (res) ->
                res.status.should.equal 400
                done()

    it '/test/info post should not work with only temp', (done) ->
        request
            .post host + '/test/info'
            .send
                temp : -50
            .end (res) ->
                res.status.should.equal 400
                done()

    it '/test/info post should not work with wrong value for id', (done) ->
        request
            .post host + '/test/info'
            .send
                id   : 'bad'
                temp : -50
            .end (res) ->
                res.status.should.equal 400
                done()

    it '/test/info post should not work with wrong value for temp', (done) ->
        request
            .post host + '/test/info'
            .send
                id   : 1000
                temp : 50.01
            .end (res) ->
                res.status.should.equal 400
                done()

    it '/test/info post should work with proper input', (done) ->
        request
            .post host + '/test/info'
            .send
                id   : 1000
                temp : -50
            .end (res) ->
                res.status.should.equal 200
                done()

    after (done) ->
        # My stdout is not fast enough. :(
        setTimeout done, 500