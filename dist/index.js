/**
 *  angular-simple-logger
 *
 * @version: 0.1.7
 * @author: Nicholas McCready
 * @date: Fri Jan 29 2016 13:26:06 GMT-0500 (EST)
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
      function Logger($log1, base, namespace1) {
        var augmentedNamespace, fn, k, len1, level, ref;
        this.$log = $log1;
        this.base = base;
        this.namespace = namespace1 != null ? namespace1 : '';
        if (!_isValidLogObject(this.$log)) {
          throw new Error('@$log is invalid');
        }
        this.doLog = true;
        if (this.namespace !== '' && this.namespace[this.namespace.length - 1] !== ':') {
          this.namespace += ':';
        }
        augmentedNamespace = this.base + ':' + this.namespace;
        if (_debugCache[augmentedNamespace] == null) {
          _debugCache[augmentedNamespace] = nemDebug(augmentedNamespace);
        }
        this.debugInstance = _debugCache[augmentedNamespace];
        this.debug = (function(_this) {
          return function() {
            var args;
            args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
            if (_this.doLog && LEVELS['debug'] >= _this.currentLevel) {
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
        this.currentLevel = LEVELS.error;
      }

      Logger.prototype.spawn = function(namespace) {
        if (namespace == null) {
          namespace = '';
        }
        if (typeof namespace !== 'string') {
          throw new Error('Bad namespace given');
        }
        return new Logger(this.$log, this.base, this.namespace + namespace);
      };

      Logger.prototype.isEnabled = function(subNamespace) {
        var suffix;
        if (subNamespace == null) {
          subNamespace = '';
        }
        if (!this.doLog || LEVELS['debug'] < this.currentLevel) {
          return false;
        }
        suffix = subNamespace !== '' && !subNamespace.endsWith(':') ? ':' : '';
        return nemDebug.enabled(this.base + this.namespace + subNamespace + suffix);
      };

      Logger.prototype.enable = function(namespaces) {
        var enableNames, i, k, len1, name, names;
        names = namespaces.split(/[, ]/g);
        enableNames = [];
        for (i = k = 0, len1 = names.length; k < len1; i = ++k) {
          name = names[i];
          if (name.length === 0) {
            continue;
          }
          if (name[name.length - 1] === '*') {
            enableNames.push(this.base + ':' + name);
          } else if (name[name.length - 1] === ':') {
            enableNames.push(this.base + ':' + name + '*');
          } else {
            enableNames.push(this.base + ':' + name + ':*');
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
