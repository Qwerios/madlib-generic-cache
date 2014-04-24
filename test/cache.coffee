chai        = require "chai"
CacheModule = require "../lib/index.js"
settings    = require "madlib-settings"
Q           = require "q"

# Setup cache expirations settings
#
settings.set( "cacheModules",
    expiration:
        "default":          1800000
        "myCache":          undefined
)

# Fake service implementation
#
myService =
    fakeCall: () ->
        deferred = Q.defer()

        deferred.resolve(
            foo: "bar"
        )

        return deferred.promise

# Create our cache module
#
myCache = new CacheModule( settings, "myCache", myService, "fakeCall" )

describe( "CacheModule", () ->
    describe( "#ensureAvailable()", () ->
        it( "Should return test data", ( testCompleted ) ->

            myCache.ensureAvailable()
            .then( ( data ) =>
                chai.expect( data.foo ).to.eql( "bar" )
                testCompleted();
            ,   ( error ) =>
                chai.expect( true ).to.eql( false )
                testCompleted();
            )
            .done()
        )
    )
)