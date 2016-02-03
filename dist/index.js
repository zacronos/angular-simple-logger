/**
 *  angular-simple-logger
 *
 * @version: 0.1.20
 * @author: Nicholas McCready
 * @date: Wed Feb 03 2016 11:38:03 GMT-0500 (EST)
 * @license: MIT
 */
var angular = require('angular');

angular.module('nemLogging', []);

angular.module('nemLogging').provider('nemDebug', function (){
  var ourDebug = null;
  ourDebug = require('debug');

  this.$get =  function(){
    //avail as service
    return ourDebug;
  };

  //avail at provider, config time
  this.debug = ourDebug;

  return this;
});
var slice = [].slice;

angular.module('nemLogging').provider('nemSimpleLogger', [
  'nemDebugProvider', function(nemDebugProvider) {
    var LEVELS, Logger, _debugCache, _fns, _isValidLogObject, j, key, len, nemDebug, val;
    nemDebug = nemDebugProvider.debug;
    _debugCache = {};
    _fns = ['debug', 'info', 'warn', 'error', 'log'];
    LEVELS = {};
    for (key = j = 0, len = _fns.length; j < len; key = ++j) {
      val = _fns[key];
      LEVELS[val] = key;
    }
    _isValidLogObject = function(logObject) {
      var k, len1;
      if (!logObject) {
        return false;
      }
      for (k = 0, len1 = _fns.length; k < len1; k++) {
        val = _fns[k];
        if (typeof logObject[val] !== 'function') {
          return false;
        }
      }
      return true;
    };
    Logger = (function() {
      function Logger($log1, base1, namespace1, currentLevel) {
        var augmentedNamespace, fn, forceDebugFileAndLine, k, len1, level, ref;
        this.$log = $log1;
        this.base = base1;
        this.namespace = namespace1 != null ? namespace1 : '';
        this.currentLevel = currentLevel != null ? currentLevel : LEVELS.error;
        if (!_isValidLogObject(this.$log)) {
          throw new Error('@$log is invalid');
        }
        this.doLog = true;
        if (this.base !== '' && this.base[this.base.length - 1] !== ':') {
          this.base += ':';
        }
        if (this.namespace === '') {
          augmentedNamespace = this.base + ':__default_namespace__:';
          forceDebugFileAndLine = true;
        } else {
          if (this.namespace[this.namespace.length - 1] !== ':') {
            this.namespace += ':';
          }
          augmentedNamespace = this.base + this.namespace;
        }
        if (_debugCache[augmentedNamespace] == null) {
          _debugCache[augmentedNamespace] = nemDebug(augmentedNamespace);
        }
        this.debugInstance = _debugCache[augmentedNamespace];
        this.debug = (function(_this) {
          return function() {
            var args;
            args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
            if (_this.doLog && LEVELS['debug'] >= _this.currentLevel && _this.debugInstance.enabled) {
              if (typeof args[0] === 'function') {
                args[0] = args[0]();
              }
              return _this.debugInstance.apply(_this, args);
            }
          };
        })(this);
        ref = _fns.slice(1);
        fn = (function(_this) {
          return function(level) {
            return _this[level] = function() {
              var args, ref1;
              args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
              if (_this.doLog && LEVELS[level] >= _this.currentLevel) {
                if (typeof args[0] === 'function') {
                  args[0] = args[0]();
                }
                return (ref1 = _this.$log)[level].apply(ref1, args);
              }
            };
          };
        })(this);
        for (k = 0, len1 = ref.length; k < len1; k++) {
          level = ref[k];
          fn(level);
        }
        this.LEVELS = LEVELS;
        this.nemDebug = nemDebug;
      }

      Logger.prototype.spawn = function(namespace, base) {
        if (namespace == null) {
          namespace = '';
        }
        if (base == null) {
          base = this.base;
        }
        if (typeof namespace !== 'string') {
          throw new Error('Bad namespace given');
        }
        return new Logger(this.$log, base, this.namespace + namespace, this.currentLevel);
      };

      Logger.prototype.isEnabled = function(subNamespace, opts) {
        var prefix, suffix;
        if (subNamespace == null) {
          subNamespace = '';
        }
        if (opts == null) {
          opts = {};
        }
        if (!this.doLog || LEVELS['debug'] < this.currentLevel) {
          return false;
        }
        prefix = !!opts.absoluteNamespace ? '' : this.base;
        suffix = subNamespace !== '' && !subNamespace[subNamespace.length - 1] === ':' ? ':' : '';
        return nemDebug.enabled(prefix + this.namespace + subNamespace + suffix);
      };

      Logger.prototype.enable = function(namespaces, opts) {
        var enableNames, i, k, len1, minus, name, names, prefix;
        if (opts == null) {
          opts = {};
        }
        if (!namespaces) {
          return nemDebug.enable(null);
        }
        prefix = !!opts.absoluteNamespace ? '' : this.base;
        names = namespaces.split(/[, ]/g);
        enableNames = [];
        for (i = k = 0, len1 = names.length; k < len1; i = ++k) {
          name = names[i];
          if (name.length === 0) {
            continue;
          }
          minus = '';
          if (name[0] === '-') {
            name = name.substr(1);
            minus = '-';
          }
          if (name[name.length - 1] === '*') {
            enableNames.push(minus + prefix + name);
          } else if (name[name.length - 1] === ':') {
            enableNames.push(minus + prefix + name + '*');
          } else {
            enableNames.push(minus + prefix + name + ':*');
          }
        }
        return nemDebug.enable(enableNames.join(','));
      };

      return Logger;

    })();
    this.decorator = [
      '$log', function($delegate) {
        var log;
        log = new Logger($delegate, 'frontend');
        log.currentLevel = LEVELS.debug;
        return log;
      }
    ];
    this.$get = [
      '$log', function($log) {
        return new Logger($log, 'frontend');
      }
    ];
    return this;
  }
]);
