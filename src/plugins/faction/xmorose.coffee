plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        r = FactionUtil.parseCallingBody item
        return true if r.body.indexOf('多哥') > -1

        return false

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item
        FactionUtil.send Bot.getTemplate('xmorose').fillPlayer(r.player).fillSmily().toString()

        callback()

module.exports = plugin