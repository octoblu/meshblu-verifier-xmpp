_ = require 'lodash'
async = require 'async'
MeshbluXmpp = require 'meshblu-xmpp'
xml2js = require('xml2js').parseString

class Verifier
  constructor: ({@meshbluConfig, @onError, @nonce}) ->
    console.log {@meshbluConfig}
    @nonce ?= Date.now()

  _connect: (callback) =>
    console.log 'connect'
    @meshblu = new MeshbluXmpp @meshbluConfig
    @meshblu.connect callback

  _message: (callback) =>
    @meshblu.on 'message', ({data}) =>
      console.log 'got message'
      return callback new Error 'wrong message received' unless data?.payload == @nonce
      callback()

    message =
      devices: [@meshbluConfig.uuid]
      payload: @nonce

    @meshblu.message message, =>
      console.log 'sent message'

  # _register: (callback) =>
  #   @_connect()
  #   @meshblu.connect (error) =>
  #     return callback error if error?
  #
  #     @meshblu.once 'error', (data) =>
  #       callback new Error data
  #
  #     @meshblu.once 'registered', (data) =>
  #       @device = data
  #       @meshbluConfig.uuid = @device.uuid
  #       @meshbluConfig.token = @device.token
  #       @meshblu.close()
  #       @_connect()
  #       @meshblu.connect (error) =>
  #         return callback error if error?
  #         callback()
  #
  #     @meshblu.register type: 'meshblu:verifier'

  _update: (callback) =>
    params =
      $set:
        nonce: @nonce

    @meshblu.update @meshbluConfig.uuid, params, (error) =>
      return callback error if error?
      @meshblu.whoami (error, data) =>
        return callback new Error 'update failed' unless data?.nonce == @nonce
        callback null, data

  _whoami: (callback) =>
    console.log 'whoami'
    @meshblu.whoami callback

  # _unregister: (callback) =>
  #   return callback() unless @device?
  #   @meshblu.once 'unregistered', (data) =>
  #     callback null, data
  #
  #   @meshblu.removeAllListeners 'error'
  #   @meshblu.once 'error', (data) =>
  #     callback new Error data
  #
  #   @meshblu.unregister @device

  verify: (callback) =>
    async.series [
      @_connect
      # @_register
      @_whoami
      @_message
      @_update
      # @_unregister
    ], (error) =>
      @meshblu.close()
      callback error

module.exports = Verifier
