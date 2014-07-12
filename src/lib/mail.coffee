nodemailer = require 'nodemailer'
lru = require 'lru-cache'
cache = lru
    max:    500
    maxAge: 60 * 60 * 1000  # 1hour

transport = nodemailer.createTransport 'SMTP',
    secureConnection: true
    host:   Config.Mail.Server
    port:   Config.Mail.Port
    auth:
        user:   Config.Mail.User
        pass:   Config.Mail.Pass

Mail = GLOBAL.Mail =
    
    send: (options, callback) ->

        if cache.has(options.text)
            callback new Error('ignored') if callback?
            return

        cache.set options.text, true

        transport.sendMail
            from:       Config.Mail.Nick + ' <' + Config.Mail.User + '>'
            to:         Config.Mail.Receiver
            subject:    options.subject
            html:       options.html
            text:       options.text
        , callback