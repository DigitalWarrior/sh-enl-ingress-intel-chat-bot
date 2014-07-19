storage = require(LIB_DIR + '/storage.js')('plugin.welcome')

plugin = 

    init: (callback) ->

        storage.fetch
            welcomedAgents: {}
        , ->

            if argv.debug
                storage.welcomedAgents = {}

            callback()

    test: (item) ->

        return true if item.markup?.TEXT1?.plain is 'has completed training.'
        return true if item.markup?.TEXT2?.plain is ' captured their first Portal.'
        return true if item.markup?.TEXT2?.plain is ' created their first Link.'

        return false

    process: (item, callback) ->

        if item.markup?.TEXT1?.plain is 'has completed training.'
            player = item.markup.SENDER1.plain
            player = player.substr 0, player.length - 2
        else
            player = item.markup.PLAYER1.plain

        # wait enough time
        setTimeout ->

            return if storage.welcomedAgents[player.toLowerCase()]?

            # get recent action
            Database.db.collection('Chat.Public').find
                'markup.PLAYER1.plain': player
                'markup.PORTAL1':
                    $exists: true
            .sort {time: -1}
            .limit 1
            .toArray (err, records) ->

                # recent action not found / no markups
                if err or not records
                    plugin.sayHello player
                else
                    plugin.sayHello player,
                        latE6: records[0].markup.PORTAL1.latE6
                        lngE6: records[0].markup.PORTAL1.lngE6

        , Config.Public.FetchInterval * 1.5

        callback()

    sayHello: (player, options) ->

        return if storage.welcomedAgents[player.toLowerCase()]?
        storage.welcomedAgents[player.toLowerCase()] = true
        storage.save() if not argv.debug

        FactionUtil.send Bot.getTemplate('welcome').fillPlayer(player).fillSmily().toString(), options

module.exports = plugin