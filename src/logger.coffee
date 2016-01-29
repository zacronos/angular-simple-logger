angular.module('nemLogging').provider 'nemSimpleLogger',[ 'nemDebugProvider', (nemDebugProvider) ->

  nemDebug = nemDebugProvider.debug
  _debugCache = {}

  _fns = ['debug', 'info', 'warn', 'error', 'log']
  LEVELS = {}
  for val, key in _fns
    LEVELS[val] = key

  _isValidLogObject = (logObject) ->
    if !logObject
      return false
    for val in _fns
      if typeof(logObject[val]) != 'function'
        return false
    return true


  class Logger
    constructor: (@$log, @base, @namespace='') ->
      if !_isValidLogObject(@$log)
        throw new Error('@$log is invalid')

      @doLog = true

      if @namespace != '' && @namespace[@namespace.length-1] != ':'
        @namespace += ':'
      augmentedNamespace = @base+':'+@namespace
      if !_debugCache[augmentedNamespace]?
        _debugCache[augmentedNamespace] = nemDebug(augmentedNamespace)
      @debugInstance = _debugCache[augmentedNamespace]

      # Overide logeObject.debug with a nemDebug instance; see: https://github.com/visionmedia/debug/blob/master/Readme.md
      @debug = (args...) =>
        if @doLog && LEVELS['debug'] >= @currentLevel
          @debugInstance(args...)
      for level in _fns.slice(1)
        do (level) =>
          @[level] = (args...) =>
            if @doLog && LEVELS[level] >= @currentLevel
              @$log[level](args...)

      @LEVELS = LEVELS
      @currentLevel = LEVELS.error

    spawn: (namespace='') ->
      if typeof(namespace) != 'string'
        throw new Error('Bad namespace given')
      return new Logger(@$log, @base, @namespace+namespace)
        
    isEnabled: (subNamespace='') ->
      if !@doLog || LEVELS['debug'] < @currentLevel
        return false
      suffix = if subNamespace != '' && !subNamespace.endsWith(':') then ':' else ''
      nemDebug.enabled(@base+@namespace+subNamespace+suffix)
    
    enable: (namespaces) ->
      names = namespaces.split(/[, ]/g)
      enableNames = []
      for name,i in names
        if name.length == 0
          continue
        if name[name.length-1] == '*'
          enableNames.push(@base+':'+name)
        else if name[name.length-1] == ':'
          enableNames.push(@base+':'+name+'*')
        else
          enableNames.push(@base+':'+name+':*')
      nemDebug.enable(enableNames.join(','))

  @decorator = ['$log', ($delegate) ->
    #app domain logger enables all logging by default
    log = new Logger($delegate, 'frontend')
    log.currentLevel = LEVELS.debug
    log
  ]

  @$get = [ '$log', ($log) ->
    # console.log $log
    #default logging is error for specific domain
    new Logger($log, 'frontend')
  ]
  
  @
]
