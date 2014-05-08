delayedQueue = require LIB_DIR + '/delayedqueue.js'
zlib = require 'zlib'
async = require 'async'
request = require 'request'

delayedRequestQueue = new delayedQueue (task) ->

    task()

, Config.Request.MinIntervalMS

delayedRequest =
    
    post: (options, callback) ->

        delayedRequestQueue.push ->
            request.post options, callback

    get: (options, callback) ->

        delayedRequestQueue.push ->
            request.get options, callback

class RequestFactory

    constructor: ->

        @max        = 0
        @done       = 0
        @munge      = null
        @cookies    = {}
        @cookieJar  = null

        for cookie in Config.Auth.CookieRaw.split(';')
            
            cookie = cookie.trim()
            continue if cookie.length is 0

            pair = cookie.split '='
            @cookies[pair[0]] = unescape pair[1]

        @resetCookies()

        @queue = async.queue (task, callback) =>

            task.before =>
                
                @post '/r/' + task.m, task.d, (error, response, body) =>

                    if error
                        logger.error error.stack

                    if task.emitted?
                        logger.warn '[DEBUG] Ignored reemitted event (Please report this in issue tracker)'
                        return

                    task.emitted = true

                    @done++

                    if not error
                        if body.error?
                            error = new Error(body.error)
                        else
                            error = @processResponse error, response, body

                    if error

                        task.error error, ->
                            task.response ->
                                callback()

                        return

                    task.success body, ->
                        task.response ->
                            callback()

        , Config.Request.MaxParallel

    resetCookies: =>

        @cookieJar = request.jar()

        for cookie in Config.Auth.CookieRaw.split(';')
            cookie = cookie.trim()
            if cookie.length isnt 0
                @cookieJar.setCookie request.cookie(cookie), 'http://www.ingress.com'

    generate: (options) =>

        activeMunge = Munges.Data[Munges.ActiveSet]
        normalizeFunc = Munges.NormalizeParamCount.func

        methodName = 'dashboard_' + options.action
        versionStr = 'version_parameter'

        methodName = activeMunge[methodName]
        versionStr = activeMunge[versionStr]

        post_data = Utils.requestDataMunge Utils.extend({method: methodName, version: versionStr}, options.data), activeMunge, normalizeFunc

        # return:
        return {
            m:        methodName
            d:        post_data
            before:   options.beforeRequest || (callback) -> callback()
            success:  options.onSuccess     || (body, callback) -> callback()
            error:    options.onError       || (error, callback) -> callback()
            response: options.afterResponse || (callback) -> callback()
        }

    push: (options) =>

        @max++
        task = @generate options
        @queue.push task
    
    unshift: (options) =>

        @max++
        task = @generate options
        @queue.unshift task

    post: (url, data, callback) =>

        delayedRequest.post

            url:        'http://www.ingress.com' + url
            body:       JSON.stringify data
            jar:        @cookieJar
            maxSockets: 50
            encoding:   null
            timeout:    20000
            headers:
                'Accept': 'application/json, text/javascript, */*; q=0.01'
                'Accept-Encoding': 'gzip,deflate'
                'Content-type': 'application/json; charset=utf-8'
                'Origin': 'http://www.ingress.com'
                'Referer': 'http://www.ingress.com/intel'
                'User-Agent': Config.Request.UserAgent
                'X-CSRFToken': @cookies.csrftoken

        , @_gzipDecode @_jsonDecode callback

    get: (url, callback) =>

        delayedRequest.get

            url:        'http://www.ingress.com' + url
            jar:        @cookieJar
            maxSockets: 50
            encoding:   null
            timeout:    20000
            headers:
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
                'Accept-Encoding': 'gzip,deflate'
                'Cache-Control': 'max-age=0'
                'Origin': 'http://www.ingress.com'
                'Referer': 'http://www.ingress.com/intel'
                'User-Agent': Config.Request.UserAgent

        , @_gzipDecode callback

    processResponse: (error, response, body) ->

        if typeof body is 'string'

            if body.indexOf('CSRF verification failed. Request aborted.') > -1
                logger.error '[ERROR] CSRF verification failed'
                return new Error 'CSRF verification failed'

            if body.indexOf('Sign in') > -1 or body.indexOf('User not authenticated') > -1
                logger.error '[ERROR] User not authenticated'
                return new Error 'Auth failed'

            if body.indexOf('but your computer or network may be sending automated queries') > -1
                logger.error '[ERROR] Request rejected'
                return new Error 'request rejected'
                
            return new Error 'unknown server response'

        return null

    _gzipDecode: (callback) ->

        return (error, response, buffer) ->

            if error?
                callback error, response
                return

            if response.headers['content-encoding']?

                encoding = response.headers['content-encoding']

                if encoding is 'gzip'

                    zlib.gunzip buffer, (err, body) ->
                        callback err, response, body && body.toString()
                    return

                else if encoding is 'deflate'

                    zlib.inflate buffer, (err, body) ->
                        callback err, response, body && body.toString()
                    return

            callback error, response, buffer && buffer.toString()

    _jsonDecode: (callback) ->

        return (error, response, body) ->

            if error?
                callback error, response
                return

            if response.headers['content-type']?

                if response.headers['content-type'].indexOf('json') > -1

                    try
                        decoded = JSON.parse body
                    catch err
                        callback err, response, body
                        return

                    callback err, response, decoded
                    return

            callback error, response, body

module.exports = ->

    return new RequestFactory()
