shmock = require 'shmock'
Verifier = require '../src/verifier'
MockMeshbluXmpp = require './mock-meshblu-xmpp'

describe 'Verifier', ->
  beforeEach (done) ->
    @registerHandler = sinon.stub()
    @whoamiHandler = sinon.stub()
    @unregisterHandler = sinon.stub()
    @updateHandler = sinon.stub()
    @messageHandler = sinon.stub()

    onConnection = (socket) =>
      sendFrame = (event, data) ->
        socket.send JSON.stringify [event, data]

      socket.on 'message', ({data}) =>
        [event, data] = JSON.parse data

        if event == 'register'
          @registerHandler data, (response) ->
            return sendFrame 'error', response.error if response?.error?
            sendFrame 'registered', response

        if event == 'whoami'
          @whoamiHandler data, (response) ->
            return sendFrame 'error', response.error if response?.error?
            sendFrame 'whoami', response

        if event == 'update'
          @updateHandler data, (response) ->
            return sendFrame 'error', response.error if response?.error?
            sendFrame 'updated', response
            sendFrame 'whoami', data[1]['$set'] # crazy right!?

        if event == 'message'
          @messageHandler data, (response) ->
            return sendFrame 'error', response.error if response?.error?
            sendFrame 'message', response

        if event == 'unregister'
          @unregisterHandler data, (response) ->
            return sendFrame 'error', response.error if response?.error?
            sendFrame 'unregistered', response

        if event == 'identity'
          sendFrame 'ready', uuid: 'some-device', token: 'some-token'

      socket.on 'error', (error) ->
        throw error

      sendFrame 'identify'

    @meshblu = new MockMeshbluXmpp port: 0xd00d, onConnection: onConnection
    @meshblu.start done

  afterEach (done) ->
    @meshblu.stop => done()

  describe '-> verify', ->
    beforeEach ->
      @nonce = Date.now()
      meshbluConfig = hostname: 'localhost', port: 0xd00d, protocol: 'ws'
      @sut = new Verifier {meshbluConfig, @nonce}

    context 'when everything works', ->
      beforeEach ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @messageHandler.yields payload: @nonce
        @updateHandler.yields nonce: @nonce
        @unregisterHandler.yields null

      beforeEach (done) ->
        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@messageHandler).to.be.called
        expect(@updateHandler).to.be.called
        expect(@unregisterHandler).to.be.called

    context 'when register fails', ->
      beforeEach (done) ->
        @registerHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called

    context 'when whoami fails', ->
      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called

    context 'when message fails', ->
      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @messageHandler.yields null

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@messageHandler).to.be.called

    context 'when update fails', ->
      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @messageHandler.yields payload: @nonce
        @updateHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@updateHandler).to.be.called

    context 'when unregister fails', ->
      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @messageHandler.yields payload: @nonce
        @updateHandler.yields nonce: @nonce
        @unregisterHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@updateHandler).to.be.called
        expect(@unregisterHandler).to.be.called
