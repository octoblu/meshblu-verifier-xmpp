http = require 'http'
xmpp = require 'faye-xmpp'

class MockMeshbluXmpp
  constructor: (options) ->
    {@onConnection, @port} = options

  start: (callback) =>
    @server = http.createServer()
    @server.on 'upgrade', @_onUpgrade
    @server.listen @port, callback

  stop: (callback) =>
    @server.close callback

  _onUpgrade: (request, socket, body) =>
    return unless xmpp.isxmpp request

    ws = new xmpp request, socket, body
    @onConnection ws

module.exports = MockMeshbluXmpp
