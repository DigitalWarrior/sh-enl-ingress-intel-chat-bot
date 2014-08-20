async = require 'async'

plugin = 

    name: 'realtimeNews'

    init: (callback) ->

        Bot.Server.get '/feed', AccessLevel.LEVEL_GUEST, 'Get latest activities (2 minutes)', (req, res) ->

            timestamp = Date.now() - 2 * 60 * 1000
            timestamp = parseInt(req.params.gt) if req.params.gt? and parseInt(req.params.gt) > timestamp

            Database.db.collection('Chat.Public').find
                'time':
                    $gte: timestamp
            .sort {time: 1}
            .toArray (err, activities) ->

                if err
                    res.jsonp {err: err.message}
                    return

                ret = []

                for act in activities
                    continue if act.plextType isnt 'SYSTEM_BROADCAST'
                    continue if act.team isnt 'ENLIGHTENED'

                    data = null

                    if act.markup.TEXT1.plain is ' captured '
                        data =
                            action: 'capture'
                            lat: act.markup.PORTAL1.latE6
                            lng: act.markup.PORTAL1.lngE6
                            time: act.time
                    else if act.markup.TEXT1.plain is ' destroyed an '
                        data =
                            action: 'destroy'
                            lat: act.markup.PORTAL1.latE6
                            lng: act.markup.PORTAL1.lngE6
                            time: act.time
                    else if act.markup.TEXT1.plain is ' deployed an '
                        data =
                            action: 'deploy'
                            lat: act.markup.PORTAL1.latE6
                            lng: act.markup.PORTAL1.lngE6
                            time: act.time
                    else if act.markup.TEXT1.plain is ' linked '
                        data = 
                            action: 'link'
                            src:
                                lat: act.markup.PORTAL1.latE6
                                lng: act.markup.PORTAL1.lngE6
                            dest:
                                lat: act.markup.PORTAL2.latE6
                                lng: act.markup.PORTAL2.lngE6
                            time: act.time

                    ret.push data if data

                res.jsonp ret

        callback()

module.exports = plugin