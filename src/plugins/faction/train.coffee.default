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
        return 10 if /^train\s+\S+\s+\S+$/.test r.body

        # remove
        return 10 if /^train\s+\S+$/.test r.body

        for rule, response of storage.rules
            reg = new RegExp(rule, 'i')
            return 10 if reg.test r.body

        return false

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item

        # training mode
        match = r.body.match /^train\s+(\S+)\s+(\S+)$/
        if match
            try
                reg = new RegExp(match[1])
            catch e
                FactionUtil.send Bot.getTemplate('train.fail').fillPlayer(r.player).toString(), null, r.body
                return callback()
            storage.rules[match[1]] = match[2]
            FactionUtil.send Bot.getTemplate('train.ok').fillPlayer(r.player).toString(), null, r.body
            storage.save() if not argv.debug
            return callback()

        # removing mode
        match = r.body.match /^train\s+(\S+)$/
        if match
            delete storage.rules[match[1]]
            FactionUtil.send Bot.getTemplate('train.remove').fillPlayer(r.player).toString(), null, r.body
            storage.save() if not argv.debug
            return callback()

        # response
        for rule, response of storage.rules
            reg = new RegExp(rule, 'i')
            if reg.test r.body
                FactionUtil.send Bot.generateTemplate('@{player} ' + response).fillPlayer(r.player).fillSmily().toString(), null, r.body
                return callback()

        callback()

module.exports = plugin