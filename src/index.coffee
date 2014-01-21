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

    class CacheModule
        # Extending cache modules needs to provide:
        # * madlib-settings instance for timeout values
        # * a unique name
        # * and the instance of the service to .call()
        #
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

        storeData: ( cacheKey, data ) ->
            now = @getNow()

            @cache.data[  cacheKey ] = data
            @cache.mtime[ cacheKey ] = now.getTime()

        getCacheKey: ( params ) ->
            # This method can be overridden by the cache module extender
            # to extract the correct cache key from the params or by some
            # other method
            #
            "default"

        getNow: () ->
            # The extending class can override this function to provide it's
            # own time provider. Must return a data object.
            #
            new Date()

        processData: ( data ) ->
            # The extending class can choose to alter or wrap the data in any way
            # it sees fit. It could add a convenience wrapper class for easy
            # value retrieval or pre-processing.
            #
            data

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