(function() {
  (function(factory) {
    if (typeof exports === "object") {
      return module.exports = factory(require("madLib-console"), require("q"), require("madLib-object-utils"));
    } else if (typeof define === "function" && define.amd) {
      return define(["madLib-console", "q", "madLib-object-utils"], factory);
    }
  })(function(console, Q, objectUtils) {
    var CacheModule;
    return CacheModule = (function() {
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

      CacheModule.prototype.clearCache = function(key) {
        if ((key != null) && this.cache.data[key]) {
          delete this.cache.data[key];
          return delete this.cache.mtime[key];
        } else {
          this.cache.data = {};
          return this.cache.mtime = {};
        }
      };

      CacheModule.prototype.storeData = function(cacheKey, data) {
        var now;
        now = this.getNow();
        this.cache.data[cacheKey] = data;
        return this.cache.mtime[cacheKey] = now.getTime();
      };

      CacheModule.prototype.getCacheKey = function(params) {
        return "default";
      };

      CacheModule.prototype.getNow = function() {
        return new Date();
      };

      CacheModule.prototype.processData = function(data) {
        return data;
      };

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
