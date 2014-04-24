( ( factory ) ->
    if typeof exports is "object"
        module.exports = factory(
            require "madlib-console"
            require "q"
            require "madlib-object-utils"
        )
    else if typeof define is "function" and define.amd
        define( [
            "madlib-console"
            "q"
            "madlib-object-utils"
        ], factory )

)( ( console, Q, objectUtils ) ->

    ###*
    #   A generic cache module for in memory caching of data. Expiration times are configurable with madlib-settings. Basically it's a simple key/value store.
    #   Chances are you want to use Backbone models instead of this.
    #
    #   @author     mdoeswijk
    #   @class      CacheModule
    #   @constructor
    #   @version    0.1
    ###
    class CacheModule

        ###*
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
        ###
        constructor: ( settings, cacheName, serviceHandler, serviceCallName = "call" ) ->
            # Initialise settings
            #
            settings.init( "cacheModules",
                expiration:
                    # Default expiration is 30 minutes
                    # Set to undefined to not expire
                    # CacheModules that have different expirations can be added here by their cacheName
                    #
                    "default": 1800000
            )
            @settings = settings

            # The private cache
            #
            @cache =
                data:   {}
                mtime:  {}
                name:   cacheName
            @service         = serviceHandler
            @serviceCallName = serviceCallName


        ###*
        #   Clears a part or all of the cache
        #
        #   @function clearCache
        #
        #   @params {String}    [key]       The key for the cache item to clear. If omitted the entire cache will be cleared
        #
        #   @return None
        #
        ###
        clearCache: ( key ) ->
            if key? and @cache.data[ key ]
                # Only clear a part of the cache
                #
                delete @cache.data[ key ]
                delete @cache.mtime[ key ]
            else
                # Clear the whole thing
                #
                @cache.data  = {}
                @cache.mtime = {}

        ###*
        #   Stores data in the cache by key
        #
        #   @function storeData
        #
        #   @params {String}    key         The key for the cache item
        #   @params {Mixed}     data        The data for the cache item
        #
        #   @return None
        #
        ###
        storeData: ( cacheKey, data ) ->
            now = @getNow()

            @cache.data[  cacheKey ] = data
            @cache.mtime[ cacheKey ] = now.getTime()

        ###*
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
        ###
        getCacheKey: ( params ) ->
            return "default"

        ###*
        #   The extending class can override this function to provide it's
        #   own time provider. Must return a date object.
        #
        #   @function getNow
        #
        #   @return {Date}    The current date/time
        #
        ###
        getNow: () ->
            return new Date()


        ###*
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
        ###
        processData: ( data ) ->
            return data

        ###*
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
        ###
        ensureAvailable: ( params ) ->
            console.log( "[#{@cache.name}] Checking data availability..." )

            # As usual we will return a promise
            #
            deferred = Q.defer()

            # Get the expiration time from the settings
            # There is a "default" and there may be a specific entry for this
            # named cache module.
            # A value of undefined means the cache never expires
            #
            expirationSettings = @settings.get( "cacheModules.expiration", {} )
            expirationTime     = objectUtils.getValue( @cache.name, expirationSettings, expirationSettings[ "default" ] )
            now                = @getNow()

            # The cacheKey is used to determine where in our data cache the data
            # is or will be stored. A service might be called with say a customer id
            # and the data for each customer will be cached and tracked separately.
            # Extending classes can override this function to indicate what this key is
            #
            cacheKey     = @getCacheKey( params )
            currentData  = @cache.data[  cacheKey ]
            currentMTime = @cache.mtime[ cacheKey ]

            # Check if there is data and if it has expired
            #
            if currentData? and ( ( expirationTime is undefined ) or ( now.getTime() - currentMTime ) < expirationTime )

                console.log( "[#{@cache.name}] Returning data from cache." )

                # Our cached data is valid and can be returned just like it would
                # from an XHR request
                #
                deferred.resolve( currentData )

            else
                console.log( "[#{@cache.name}] Retrieving data from service..." )

                # Call the service to retrieve our data
                #
                @service[ @serviceCallName ]( params )
                .then(
                    ( data ) =>
                        console.log( "[#{@cache.name}] Stored and returning data from service." )

                        # Process the reponse data
                        #
                        newData = @processData( data )

                        # Store the response data in the cache
                        #
                        @storeData( cacheKey, newData )

                        # Return the data to our caller
                        #
                        deferred.resolve( newData )

                ,   ( data ) =>
                        console.log( "[#{@cache.name}] Error retrieving data from service." )

                        # Propagate the error to the caller
                        #
                        deferred.reject( data )
                )
                .done();

            # Return our promise to the caller
            #
            return deferred.promise;
)