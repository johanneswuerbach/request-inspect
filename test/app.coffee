rest = require 'restler'
sinon = require 'sinon'
chai = require "chai"
chai.use (require "sinon-chai")
should = chai.should()

App = require '../lib/app'

describe 'Server', ->
  app = null
  before (done) ->
    # Load server
    app = new App 5000, done

  describe '#index', ->

    it 'should return 200', (done) ->

      rest.get('http://localhost:5000').on 'complete', (data, res) ->
        res.statusCode.should.equal 200
        done()

  describe '#catchRequest', ->

    describe 'displaying the request', ->

      displayRequestSpy = null

      before ->
        displayRequestSpy = sinon.spy app, "displayRequest"

      it 'should forward request', (done) ->
        rest.get('http://localhost:5000/forward/?test=a').on 'complete', ->
          displayRequestSpy.should.have.been.calledWith "forward",
            body: ""
            headers:
              "accept": "*/*"
              "accept-encoding": "gzip, deflate"
              "connection": "keep-alive"
              "content-length": "0"
              "host": "localhost:5000"
              "user-agent": "Restler for node.js"
            method: "GET"
            query:
              test: "a"
          done()

      it 'should forward a post body', (done) ->
        post = {data: { a: 1, b: 2 }}
        rest.post('http://localhost:5000/post/', post).on 'complete', ->
          displayRequestSpy.should.have.been.calledWith "post",
            body: "a=1&b=2"
            headers:
              accept: "*/*"
              "accept-encoding": "gzip, deflate"
              connection: "keep-alive"
              "content-length": "7"
              "content-type": "application/x-www-form-urlencoded"
              host: "localhost:5000"
              "user-agent": "Restler for node.js"
            method: "POST"
            query: {}
          done()

      it 'should remove the headers injected by Heroku', (done) ->
        options =
          headers:
            "x-forwarded-proto": "x"
            "x-forwarded-port": "y"
        rest.get('http://localhost:5000/injected/', options).on 'complete', ->
          displayRequestSpy.should.have.been.calledWith "injected",
            body: ""
            headers:
              "accept": "*/*"
              "accept-encoding": "gzip, deflate"
              "connection": "keep-alive"
              "content-length": "0"
              "host": "localhost:5000"
              "user-agent": "Restler for node.js"
            method: "GET"
            query: {}
          done()

    describe 'sending the response', ->

      it 'should return a plain response', (done) ->
        plainResponseUrl = 'http://localhost:5000/test/plain/*TEST*'
        rest.get(plainResponseUrl).on 'complete', (data) ->
          data.should.equal "*TEST*"
          done()

      it 'should return a json response', (done) ->
        test = JSON.stringify {test: true, service: "works"}
        encodedJSON = encodeURIComponent test
        jsonResponseUrl = 'http://localhost:5000/test/json/' + encodedJSON
        rest.get(jsonResponseUrl).on 'complete', (data) ->
          JSON.stringify(data).should.equal test
          done()
