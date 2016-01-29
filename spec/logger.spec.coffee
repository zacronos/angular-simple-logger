###global spyOn:true, angular:true, inject:true, expect:true###
describe 'nemLogging.nemSimpleLogger', ->
  beforeEach ->
    @createSpyLogger = ->
      @log = ->
      @info = ->
      @debug = ->
      @warn = ->
      @error = ->

      spyOn(@, 'log')
      spyOn(@, 'info')
      spyOn(@, 'debug')
      spyOn(@, 'warn')
      spyOn(@, 'error')
      @

    $log = @createSpyLogger()
    @logger = $log

    angular.module('nemLogging').config ($provide) ->
      #decorate w/ spys
      $provide.decorator '$log', ($delegate) ->
        return $log

    angular.mock.module('nemLogging')
    inject (nemSimpleLogger) =>
      @subject = nemSimpleLogger

  it 'exists', ->
    expect(@subject).toBeDefined()

  describe 'default', ->
    ['info', 'warn', {called:'error'}, {called:'log'}].forEach (testName) ->
      {called} = testName
      testName = if typeof testName == 'string' then testName else testName.called
      it testName, ->
        @subject[testName]('blah')
        if called
          expect(@logger[testName]).toHaveBeenCalled()
          return expect(@logger[testName]).toHaveBeenCalledWith('blah')
        expect(@logger[testName]).not.toHaveBeenCalled()


  describe 'all on', ->
    beforeEach ->
      inject (nemSimpleLogger) =>
        nemSimpleLogger.currentLevel = nemSimpleLogger.LEVELS.debug
        @subject = nemSimpleLogger
    describe 'single arg', ->
      ['info', 'warn', 'error', 'log'].forEach (testName) ->
        it testName, ->
          @subject[testName]('blah')
          expect(@logger[testName]).toHaveBeenCalled()
          expect(@logger[testName]).toHaveBeenCalledWith('blah')

    describe 'multi arg', ->
      ['info', 'warn', 'error', 'log'].forEach (testName) ->
        it testName, ->
          @subject[testName]('blah','HI')
          expect(@logger[testName]).toHaveBeenCalled()
          expect(@logger[testName]).toHaveBeenCalledWith('blah', 'HI')

  describe 'all off', ->
    describe 'by LEVELS +1', ->
      beforeEach ->
        inject (nemSimpleLogger) =>
          nemSimpleLogger.currentLevel = nemSimpleLogger.LEVELS.log + 1
          @subject = nemSimpleLogger

      ['info', 'warn', 'error', 'log'].forEach (testName) ->
        it testName, ->
          @subject[testName]('blah')
          expect(@logger[testName]).not.toHaveBeenCalled()

    describe 'by doLog', ->
      beforeEach ->
        inject (nemSimpleLogger) =>
          nemSimpleLogger.doLog = false
          @subject = nemSimpleLogger

      ['info', 'warn', 'error', 'log'].forEach (testName) ->
        it testName, ->
          @subject[testName]('blah')
          expect(@logger[testName]).not.toHaveBeenCalled()

  describe 'spawn', ->
    beforeEach ->
      @newLogger = @subject.spawn()
      @newLog = @createSpyLogger()

    it 'can create a new logger', ->
      expect(@newLogger.debug).toBeDefined()
      expect(@newLogger != @subject).toBeTruthy()

    it 'underlying logger is still $log', ->
      expect(@newLogger.$log == @logger).toBeTruthy()

    describe 'Has Independent', ->
      it 'logLevels', ->
        @newLogger.currentLevel = @newLogger.LEVELS.debug
        expect(@newLogger.currentLevel != @subject.currentLevel).toBeTruthy()

  describe 'decorate', ->
    beforeEach ->
      angular.module('nemLogging')
      .config ($provide, nemSimpleLoggerProvider) ->
        #decorate w/ nemSimpleLogger which will call spys internally
        $provide.decorator nemSimpleLoggerProvider.decorator...

      inject ($log) =>
        @subject = $log

    it 'debug', ->
      @subject.debug('blah')
      expect(@logger.debug).toHaveBeenCalled()

    it 'error', ->
      @subject.error('blah')
      expect(@logger.error).toHaveBeenCalled()

    it 'info', ->
      @subject.info('blah')
      expect(@logger.info).toHaveBeenCalled()

    it 'warn', ->
      @subject.warn('blah')
      expect(@logger.warn).toHaveBeenCalled()
