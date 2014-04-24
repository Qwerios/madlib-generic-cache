(function() {
  (function(factory) {
    if (typeof exports === "object") {
      return module.exports = factory(require("madlib-console"), require("q"), require("madlib-object-utils"));
    } else if (typeof define === "function" && define.amd) {
      return define(["madlib-console", "q", "madlib-object-utils"], factory);
    }
  })(function(console, Q, objectUtils) {
    /**
    #   A generic cache module for in memory caching of data. Expiration times are configurable with madlib-settings. Basically it's a simple key/value store.
    #   Chances are you want to use Backbone models instead of this.
    #
    #   @author     mdoeswijk
    #   @class      CacheModule
    #   @constructor
    #   @version    0.1
    */

    var CacheModule;
    return CacheModule = (function() {
      /**
      #   The class constructor.
      #
      #   @function constructor
      #
      #   @params {Object}    settings            A madlib-settings instance
      #   @params {String}    cacheName           The name of the cache. Used to retrieve expiration settings and logging purposes
      #   @params {Function}  serviceHandler      The 'service' instance providing the data for the cache
      #   @params {String}    [serviceCallName]   The name of the method to call on the serviceHandler. Defaults to 'call'
      #   @params
      #
      #   @return None
      #
      */

      function CacheModule(settings, cacheName, serviceHandler, serviceCallName) {
        if (serviceCallName == null) {
          serviceCallName = "call";
        }
        settings.init("cacheModules", {
          expiration: {
            "default": 1800000
          }
        });
        this.settings = settings;
        this.cache = {
          data: {},
          mtime: {},
          name: cacheName
        };
        this.service = serviceHandler;
        this.serviceCallName = serviceCallName;
      }

      /**
      #   Clears a part or all of the cache
      #
      #   @function clearCache
      #
      #   @params {String}    [key]       The key for the cache item to clear. If omitted the entire cache will be cleared
      #
      #   @return None
      #
      */


      CacheModule.prototype.clearCache = function(key) {
        if ((key != null) && this.cache.data[key]) {
          delete this.cache.data[key];
          return delete this.cache.mtime[key];
        } else {
          this.cache.data = {};
          return this.cache.mtime = {};
        }
      };

      /**
      #   Stores data in the cache by key
      #
      #   @function storeData
      #
      #   @params {String}    key         The key for the cache item
      #   @params {Mixed}     data        The data for the cache item
      #
      #   @return None
      #
      */


      CacheModule.prototype.storeData = function(cacheKey, data) {
        var now;
        now = this.getNow();
        this.cache.data[cacheKey] = data;
        return this.cache.mtime[cacheKey] = now.getTime();
      };

      /**
      #   This method can be overridden by the cache module extender
      #   to extract the correct cache key from the request parameters
      #   or by some other method.
      #
      #   @function getCacheKey
      #
      #   @params {Object}    params      The request parameters
      #
      #   @return {String}    The key for the cache item
      #
      */


      CacheModule.prototype.getCacheKey = function(params) {
        return "default";
      };

      /**
      #   The extending class can override this function to provide it's
      #   own time provider. Must return a date object.
      #
      #   @function getNow
      #
      #   @return {Date}    The current date/time
      #
      */


      CacheModule.prototype.getNow = function() {
        return new Date();
      };

      /**
      #   The extending class can choose to alter or wrap the data in any way
      #   it sees fit. It could add a convenience wrapper class for easy
      #   value retrieval or pre-processing.
      #
      #
      #   @function processData
      #
      #   @params {Mixed}     data      The response data from the service call
      #
      #   @return {Mixed}    The processed data
      #
      */


      CacheModule.prototype.processData = function(data) {
        return data;
      };

      /**
      #   Asks the cache to ensure it's data is available. Returns a promise
      #   with the requested data that resolves when the data is ready.
      #   Uses madlib-settings for expiration time settings.
      #
      #   @function ensureAvailable
      #
      #   @params {Object}    params  The request parameters for the service call
      #
      #   @return {Promise}    A promise that resolves when the data from the cache is available
      #
      */


      CacheModule.prototype.ensureAvailable = function(params) {
        var cacheKey, currentData, currentMTime, deferred, expirationSettings, expirationTime, now,
          _this = this;
        console.log("[" + this.cache.name + "] Checking data availability...");
        deferred = Q.defer();
        expirationSettings = this.settings.get("cacheModules.expiration", {});
        expirationTime = objectUtils.getValue(this.cache.name, expirationSettings, expirationSettings["default"]);
        now = this.getNow();
        cacheKey = this.getCacheKey(params);
        currentData = this.cache.data[cacheKey];
        currentMTime = this.cache.mtime[cacheKey];
        if ((currentData != null) && ((expirationTime === void 0) || (now.getTime() - currentMTime) < expirationTime)) {
          console.log("[" + this.cache.name + "] Returning data from cache.");
          deferred.resolve(currentData);
        } else {
          console.log("[" + this.cache.name + "] Retrieving data from service...");
          this.service[this.serviceCallName](params).then(function(data) {
            var newData;
            console.log("[" + _this.cache.name + "] Stored and returning data from service.");
            newData = _this.processData(data);
            _this.storeData(cacheKey, newData);
            return deferred.resolve(newData);
          }, function(data) {
            console.log("[" + _this.cache.name + "] Error retrieving data from service.");
            return deferred.reject(data);
          }).done();
        }
        return deferred.promise;
      };

      return CacheModule;

    })();
  });

}).call(this);
