storage = require(LIB_DIR + '/storage.js')('plugin.train')

plugin = 

    init: (callback) ->

        storage.fetch
            rules: {}
        , ->

            callback()

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        r = FactionUtil.parseCallingBody item

        # train
        return true if /^train\s+\S+\s+\S+$/.test r.body

        # remove
        return true if /^train\s+\S+$/.test r.body

        for rule, response of storage.rules
            reg = new RegExp(rule, 'i')
            return true if reg.test r.body

        return false

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item

        # training mode
        match = r.body.match /^train\s+(\S+)\s+(\S+)$/
        if match
            try
                reg = new RegExp(match[1])
            catch e
                FactionUtil.send Bot.getTemplate('train.fail').fillPlayer(player).toString()
                return callback()
            storage.rules[match[1]] = match[2]
            FactionUtil.send Bot.getTemplate('train.ok').fillPlayer(player).toString()
            storage.save() if not argv.debug
            return callback()

        # removing mode
        match = r.body.match /^train\s+(\S+)$/
        if match
            delete storage.rules[match[1]]
            FactionUtil.send Bot.getTemplate('train.remove').fillPlayer(player).toString()
            storage.save() if not argv.debug
            return callback()

        # response
        for rule, response of storage.rules
            reg = new RegExp(rule, 'i')
            if reg.test r.body
                FactionUtil.send Bot.generateTemplate('@{player} ' + response).fillPlayer(player).fillSmily().toString()
                return callback()

        callback()

module.exports = plugin