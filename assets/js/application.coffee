#= require_tree .

generateUUID = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = Math.random()*16|0
    v = if c == 'x' then r else (r&0x3|0x8)
    v.toString(16)

getUUID = ->
  if !window.location.hash
    UUID = generateUUID()
    window.location.hash = "#{UUID}"
  else
    hash = window.location.hash
    hash.substring(1)

$ ->
  readyTmpl = Handlebars.compile($("#ready").html())
  requestTmpl = Handlebars.compile($("#request").html())

  socket = io.connect '/'
  socket.on 'ready', ->
    UUID = getUUID()
    socket.emit "join", {room: UUID}

    $(".requests").prepend(readyTmpl({url: "http://#{host}/#{UUID}"}))

  socket.on 'request', (data) ->
    console.log data
    headers = []
    for name, value of data.headers
      headers.push {name, value}
    data.headers = if headers.length > 0 then headers else null

    params = []
    for name, value of data.query
      params.push {name, value}
    data.query = if params.length > 0 then params else null

    $(".requests").prepend(requestTmpl({request: data}))