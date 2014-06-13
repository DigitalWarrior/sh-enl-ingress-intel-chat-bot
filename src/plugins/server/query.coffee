async = require 'async'

plugin = 

    name: 'query'

    init: (callback) ->

        Bot.Server.post '/query/:collection', AccessLevel.LEVEL_TRUSTED, 'Query database', (req, res) ->

            collection = req.params.collection

            query = req.body.query or {}
            fields = req.body.fields or {}

            c = Database.db.collection(collection).find(query, fields)
            c = c.sort(req.body.sort) if req.body.sort?
            c = c.skip(req.body.skip) if req.body.skip?

            if req.body.limit?
                c = c.limit(req.body.limit)
            else
                c = c.limit(500)

            c.toArray (err, docs) ->

                if err
                    res.jsonp {err: err.message}
                    return

                res.jsonp docs

        callback()

module.exports = plugin