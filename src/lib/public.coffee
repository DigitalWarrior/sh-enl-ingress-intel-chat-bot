PublicListener = GLOBAL.PublicListener =
    
    interval: 5000

    init: (callback) ->

        PublicListener.interval = Config.Public.FetchInterval
        callback()

    fetch: (callback) ->

        if argv.debug
            tracedays = Config.Faction.TraceDaysDebug
        else
            tracedays = Config.Faction.TraceDays

        Bot.exec
            argv:       ['--broadcasts', '--tracedays', tracedays]
            output:     true
        , callback

    start: ->

        Bot.exec
            argv:       ['--broadcasts']
            timeout:    Config.Public.MaxTimeout
            output:     true
        , (err, stdout, stderr) ->

            if err and err.message is 'stderr'
                PublicListener.interval *= 2
                if PublicListener.interval > Config.Public.MaxFetchInterval
                    PublicListener.interval = Config.Public.MaxFetchInterval
            else
                PublicListener.interval = Config.Public.FetchInterval

            setTimeout PublicListener.start, PublicListener.interval