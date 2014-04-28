# madlib-generic-cache
[![Build Status](https://travis-ci.org/Qwerios/madlib-generic-cache.svg?branch=master)](https://travis-ci.org/Qwerios/madlib-generic-cache) [![NPM version](https://badge.fury.io/js/madlib-generic-cache.png)](http://badge.fury.io/js/madlib-generic-cache) [![Built with Grunt](https://cdn.gruntjs.com/builtwith.png)](http://gruntjs.com/)

[![Npm Downloads](https://nodei.co/npm/madlib-generic-cache.png?downloads=true&stars=true)](https://nodei.co/npm/madlib-generic-cache.png?downloads=true&stars=true)

A generic cache module for in memory caching of data. Expiration times are configurable with madlib-settings. Basically it's a simple key/value store. Chances are you wan't to use [Backbone](http://backbonejs.org/) instead. Really...use Backbone models. This module is a bit of a relic from the past for us. It expects a service module to provide it's data (like Backbone fetch) with a single promise based 'call'.


## acknowledgments
The Marviq Application Development library (aka madlib) was developed by me when I was working at Marviq. They were cool enough to let me publish it using my personal github account instead of the company account. We decided to open source it for our mutual benefit and to ensure future updates should I decide to leave the company.


## philosophy
JavaScript is the language of the web. Wouldn't it be nice if we could stop having to rewrite (most) of our code for all those web connected platforms running on JavaScript? That is what madLib hopes to achieve. The focus of madLib is to have the same old boring stuff ready made for multiple platforms. Write your core application logic once using modules and never worry about the basics stuff again. Basics including XHR, XML, JSON, host mappings, settings, storage, etcetera. The idea is to use the tried and proven frameworks where available and use madlib based modules as the missing link.

Currently madLib is focused on supporting the following platforms:

* Web browsers (IE6+, Chrome, Firefox, Opera)
* Appcelerator/Titanium
* PhoneGap
* NodeJS


## installation
```bash
$ npm install madlib-generic-cache --save
```

## usage
```javascript
var CacheModule = require( "madlib-generic-cache" );
var settings    = require( "madlib-settings"      );

settings.set( "cacheModules",
{
    expiration:
    {
        // Set to undefined to not expire. Caching is in memory by default
        // so an app restart/page reload will still flush the cache.
        // CacheModules that have different expirations can be added here by name
        //
        "default":          1800000      // 30 minutes
    ,   "myCache":          undefined
    ,   "myOtherCache":     300000       // 5 minutes
    }
} );

var myService = function()
{
    this.call = function()
    {
        ...
    }
}
};

var myCache = new CacheModule( settings, "myCache", myService, "call" );

// Ask the cache to ensure the data is available and not expired yet
// Returns a promise
//
myCache.ensureAvailable()
.then( function( data )
{
    ...
} )
.done()
```