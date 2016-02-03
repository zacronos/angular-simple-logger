describe 'nemLogging.nemDebug', ->
  beforeEach ->
    angular.mock.module('nemLogging')
    inject (nemDebug, $log) =>
      @subject = nemDebug
      @$log = $log

  it 'window.debug is left untouched', ->
    expect(window.debug).not.toBe(@subject)

  describe 'as a service', ->
    it 'exists', ->
      expect(@subject).toBeDefined()

    it 'is Function', ->
      expect(typeof @subject).toBe('function')

    it 'has debug API', ->
      ['coerce', 'disable', 'enable', 'enabled', 'humanize'].forEach (fnName) =>
        expect(typeof @subject[fnName]).toBe('function')

  describe 'as a provider', ->
    beforeEach ->
      angular.module('nemLogging')
      .config (nemDebugProvider) ->

        @subject = nemDebugProvider.debug

      inject (nemSimpleLogger) =>
        @simpleLogger = nemSimpleLogger

    it 'exists', ->
      expect(@subject).toBeDefined()

    it 'is Function', ->
      expect(typeof @subject).toBe('function')

    it 'has debug API', ->
      ['coerce', 'disable', 'enable', 'enabled', 'humanize'].forEach (fnName) =>
        expect(typeof @subject[fnName]).toBe('function')

    describe 'spawn a debug level', ->
      it 'disabled logger', ->
        newLogger = @simpleLogger.spawn('worker:a')
        expect(newLogger.debug).toBeDefined()
        expect(newLogger.debugInstance.namespace).toBe('frontend:worker:a:')
        expect(newLogger.debugInstance.enabled).toBeFalsy()
        ['debug', 'info', 'warn', 'error'].forEach (fnName) ->
          expect(typeof newLogger[fnName]).toBe('function')

      it 'enabled logger', ->
        @simpleLogger.enable('worker')
        newLogger = @simpleLogger.spawn('worker:a')
        expect(newLogger.debugInstance.enabled).toBeTruthy()

      it 'disable an enabled logger', ->
        @simpleLogger.enable('worker:*')
        c = @simpleLogger.spawn('worker:c')
        #note this doesnt really work yet in visionmedia
        #https://github.com/visionmedia/debug/issues/150
        @subject.disable()
        d = @simpleLogger.spawn('worker:d')
        expect(c.debugInstance.enabled).toBeTruthy()
        expect(d.debugInstance.enabled).toBeTruthy()


      it 'underlying logger is still $log', ->
        #the ref is diff, but all logging functions are $log except debug
        newLogger = @simpleLogger.spawn('worker:b')
        expect(newLogger.$log == @$log).toBeTruthy()
