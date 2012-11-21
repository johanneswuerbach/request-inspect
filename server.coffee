
express = require 'express'
util = require 'util'
app = express()
server = (require 'http').createServer app
io = (require 'socket.io').listen server

io.configure ->
  io.set 'log level', 1
  # Heroku doesn't support real websockets
  io.set "transports", ["xhr-polling"]
  io.set "polling duration", 10

server.listen (process.env.PORT || 3000)

app.use require('connect-assets')()
app.engine('.html', require('ejs').__express)
app.use ((req, res, next) ->
    data = ''
    req.setEncoding 'utf8'
    req.on 'data', (chunk) ->
       data += chunk

    req.on 'end', () ->
        req.rawBody = data
        next()
)

# Express
app.get '/', (req, res) ->
  res.render 'index.ejs', {host: req.headers.host}

app.all '/:UUID/:type?/:response?', (req, res) ->
  UUID = req.param "UUID"
  request =
    method: req.method
    headers: req.headers
    query: req.query
    body: req.rawBody

  # Clean headers
  herokuHeaders = [
    "x-forwarded-proto", 
    "x-forwarded-port", 
    "x-forwarded-for", 
    "x-heroku-queue-wait-time", 
    "x-heroku-queue-depth",
    "x-heroku-dynos-in-use",
    "x-request-start"
  ]

  if request.headers
    for header in herokuHeaders
      delete request.headers[header]

  io.sockets.in(UUID).emit "request", request

  if (req.param "type") && (req.param "response")
    type = req.param "type"
    response = req.param "response"
    if type == "json"
      try
        response = JSON.parse response
      catch e

    res.send response
  else
    res.send ""

# SocketIO
io.sockets.on 'connection', (socket) ->
  socket.emit "ready"
  socket.on "join", (data) ->
    socket.join data.room
