express = require 'express'
util = require 'util'

module.exports = class App
  constructor : (port, callback) ->
    app = express()
    server = (require 'http').createServer app
    @io = (require 'socket.io').listen server

    @io.configure =>
      @io.set 'log level', 1
      @io.set "transports", ["xhr-polling"] # Heroku does not support websockets
      @io.set "polling duration", 10

    app.use require('connect-assets')()
    app.engine('.html', require('ejs').__express)
    app.use @rawBody

    # Express
    app.get '/', @index
    app.all '/:UUID/:type?/:response?', @catchRequest

    # Socket.IO
    @io.sockets.on 'connection', (socket) ->
      socket.emit "ready"
      socket.on "join", (data) ->
        socket.join data.room

    # Run the server
    server.listen port, callback

  # Renders the frontend
  index : (req, res) ->
    res.render 'index.ejs', {host: req.headers.host}

  # Catches the request
  catchRequest : (req, res) =>
    UUID = req.params.UUID
    request =
      method: req.method
      headers: req.headers
      query: req.query
      body: req.rawBody

    # Remove headers injected by Heroku
    herokuHeaders = [
      "x-forwarded-proto", "x-forwarded-port", 
      "x-forwarded-for", "x-heroku-queue-wait-time", 
      "x-heroku-queue-depth", "x-heroku-dynos-in-use",
      "x-request-start"
    ]
    if request.headers
      for header in herokuHeaders
        delete request.headers[header]

    # Send the request into the room 
    @displayRequest UUID, request

    # Send response, if requested
    if !req.params.type || !req.params.response
      res.send ""
      return
    type = req.params.type
    response = req.params.response
    if type == "json"
      try
        response = JSON.parse response
      catch e
        console.log e
    res.send response

  # Display a request in the frontend
  displayRequest : (UUID, request) ->
    @io.sockets.in(UUID).emit "request", request

  # Adds the rawBody field
  rawBody : (req, res, next) ->
    data = ''
    req.setEncoding 'utf8'
    req.on 'data', (chunk) ->
      data += chunk
    req.on 'end', ->
      req.rawBody = data
      next()
