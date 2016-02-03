angular.module('nemLogging').provider 'nemSimpleLogger',[ 'nemDebugProvider', (nemDebugProvider) ->

  nemDebug = nemDebugProvider.debug
  _debugCache = {}

  _fns = ['debug', 'info', 'warn', 'error']
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
    constructor: (@$log, @base, @namespace='', @currentLevel=LEVELS.error) ->
      if !_isValidLogObject(@$log)
        throw new Error('@$log is invalid')

      @doLog = true

      if @base != '' && @base[@base.length-1] != ':'
        @base += ':'
      if @namespace == ''
        augmentedNamespace = @base+':__default_namespace__:'
        forceDebugFileAndLine = true
      else
        if @namespace[@namespace.length-1] != ':'
          @namespace += ':'
        augmentedNamespace = @base+@namespace
      
      if !_debugCache[augmentedNamespace]?
        _debugCache[augmentedNamespace] = nemDebug(augmentedNamespace)
      @debugInstance = _debugCache[augmentedNamespace]

      # Overide logeObject.debug with a nemDebug instance; see: https://github.com/visionmedia/debug/blob/master/Readme.md
      @debug = (args...) =>
        if @doLog && LEVELS['debug'] >= @currentLevel && @debugInstance.enabled
          if typeof(args[0]) == 'function'
            args[0] = args[0]()
          @debugInstance(args...)
      for level in _fns.slice(1)
        do (level) =>
          @[level] = (args...) =>
            if @doLog && LEVELS[level] >= @currentLevel
              if typeof(args[0]) == 'function'
                args[0] = args[0]()
              @$log[level](args...)

      @LEVELS = LEVELS
      @nemDebug = nemDebug

    spawn: (namespace='', base=@base) ->
      if typeof(namespace) != 'string'
        throw new Error('Bad namespace given')
      return new Logger(@$log, base, @namespace+namespace, @currentLevel)
        
    isEnabled: (subNamespace='', opts={}) ->
      if !@doLog || LEVELS['debug'] < @currentLevel
        return false
      prefix = if !!opts.absoluteNamespace then '' else @base
      suffix = if subNamespace != '' && !subNamespace[subNamespace.length-1] == ':' then ':' else ''
      nemDebug.enabled(prefix+@namespace+subNamespace+suffix)
    
    enable: (namespaces, opts={}) ->
      if !namespaces
        return nemDebug.enable(null)
      prefix = if !!opts.absoluteNamespace then '' else @base
      names = namespaces.split(/[, ]/g)
      enableNames = []
      for name,i in names
        if name.length == 0
          continue
        minus = ''
        if name[0] == '-'
          name = name.substr(1)
          minus = '-'
        if name[name.length-1] == '*'
          enableNames.push(minus+prefix+name)
        else if name[name.length-1] == ':'
          enableNames.push(minus+prefix+name+'*')
        else
          enableNames.push(minus+prefix+name+':*')
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
