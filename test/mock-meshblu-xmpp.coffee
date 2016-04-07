http = require 'http'
xmpp = require 'node-xmpp-server'

class MockMeshbluXmpp
  constructor: (options) ->
    {@onConnection, @port} = options

  start: (callback) =>
    @server = new xmpp.C2S.TCPServer
      port: 0xd00d
      domain: 'localhost'

    @server.on 'connection', @_onConnection

    @server.on 'listening', callback

  stop: (callback) =>
    @server.end callback

  _onConnection: (client) =>
    @onConnection client

module.exports = MockMeshbluXmpp
