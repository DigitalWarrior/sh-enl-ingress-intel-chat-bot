async = require 'async'
requestFactory = require LIB_DIR + '/requestfactory.js'
request = requestFactory()

Munges = GLOBAL.Munges =
    Failed:    false
    Data:      null
    ActiveSet: 0

MungeDetector = GLOBAL.MungeDetector = 
    
    retryInterval: 0

    start: (delay) ->

        delay = Config.MungeDetector.FetchInterval if not delay?
        
        setTimeout ->

            MungeDetector.detect (err) ->

                if err

                    if MungeDetector.retryInterval is 0
                        MungeDetector.retryInterval = 5000
                    else
                        Mail.send
                            subject: '[SH-ENL-BOT] Failed to detect munge data'
                            text:    'munge detect failed.'

                        MungeDetector.retryInterval *= 2
                        if MungeDetector.retryInterval > Config.MungeDetector.MaxFetchInterval
                            MungeDetector.retryInterval = Config.MungeDetector.MaxFetchInterval

                    logger.info '[MungeDetector] Retry in %d ms', MungeDetector.retryInterval

                    MungeDetector.start MungeDetector.retryInterval
                else

                    MungeDetector.retryInterval = 0
                    MungeDetector.start()

        , delay

    detect: (callback) ->

        async.series [

            (callback) ->

                # 0. retrive munge data from database

                Database.db.collection('MungeData').findOne {_id: 'munge'}, (err, record) ->

                    if err
                        logger.error '[MungeDetector] Failed to read mungedata from database: %s', err.message
                        return callback err

                    if record?
                        Munges.Data = record.data
                        Munges.ActiveSet = record.index

                    callback()

            (callback) ->

                # 1. test by internal munge-set

                # No munges in database: skip this step
                if Munges.Data is null
                    callback()
                    return

                tryMungeSet (err) ->

                    if not err?
                        callback 'done'
                        return

                    logger.warn '[MungeDetector] Failed.'
                    callback()

            (callback) ->

                # 2. extract munge data from Ingress.com/intel

                logger.info '[MungeDetector] Trying to extract munge data from ingress.com/intel.'

                extractMunge (err) ->

                    if not err?
                        callback 'new'
                        return

                    logger.warn '[MungeDetector] Failed.'
                    callback()

            (callback) ->

                # :( no useable munge-set

                callback 'fail'

        ], (err) ->

            if err is 'done' or err is 'new'
                
                Munges.Failed = false

                if err is 'new'

                    Database.db.collection('MungeData').update {_id: 'munge'},
                        $set:
                            data:  Munges.Data
                            index: Munges.ActiveSet
                            #func:  Munges.NormalizeParamCount.body
                    , {upsert: true}
                    , (err) ->
                        
                        # ignore error

                        if err
                            logger.error '[MungeDetector] Failed to save mungedata: %s', err.message
                        
                        callback && callback()
                        return

                else

                    callback && callback()
                    return

            else

                Munges.Failed = true

                logger.error '[MungeDetector] Failed to detect munge data.'
                callback new Error('Munge detection failed')

tryMungeSet = (tryCallback) ->

    request.push
        action: 'getGameScore'
        data:   {}
        onSuccess: (response, callback) ->

            if not response? or response.length isnt 2
                
                callback()
                tryCallback && tryCallback new Error 'Failed to detect munge'

            else

                callback()
                tryCallback && tryCallback()

        onError: (err, callback) ->

            callback()
            tryCallback && tryCallback err

extractMunge = (callback) ->

    request.get '/jsc/gen_dashboard.js', (error, response, body) ->
        
        if error
            callback 'fail'
            return

        body = body.toString()

        try
            result = Utils.extractIntelData body
        catch err
            console.log err
            callback 'fail'
            return

        Munges.Data      = [result]
        Munges.ActiveSet = 0
        
        # test it
        tryMungeSet (err) ->

            if not err?
                callback()
                return

            callback 'fail'
