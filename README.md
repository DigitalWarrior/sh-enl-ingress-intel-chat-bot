sh-enl-ingress-intel-chat-bot
=============================

An ingress chat bot developed by Shanghai Enlightened, based in ingress/intel.

Features:

- Send welcome message to new players

- Respond weather queries (China only)

- Fetch public activities

- API to query players' activity from fetched data

- API to query portals' history (capture/ADA/Jarvis events) from fetched data (experimental)

## Dependencies

- MongoDB

- Node.js

## Bootstrap

1. Clone repository and submodules

   ```bash
   git clone --recursive https://github.com/breeswish/sh-enl-ingress-intel-chat-bot.git
   ```

2. Configure

   Copy `config.cson.default` to `config.cson` and modify:
   
   - `Auth.CookieRaw`
   	 
     The ingress/intel cookie of the account.
     
     Notice: The account can be banned at anytime, so don't use your gaming account here.
   
   - `Database.ConnectString`
     
     If you have modified MongoDB port or auth settings, or want to use a different database name, please modify this field.
   
   - `Mail.*`
   
     The bot will send mails to notify you when there are something wrong.
   
   Copy `ingress-exporter/config.cson.default` to `ingress-exporter/config.cson` and modify:
   
   - `Region`
     
     The fetching region. See [How to generate polygon data via IITC drawtool](https://github.com/breeswish/ingress-exporter#how-to-generate-polygon-data-via-iitc-drawtool).
     
     Notice: The polygon region data will be finally simplified to a rectangle in the chat bot, so you needn't drawing polygon very carefully.
   
   - `Database.ConnectString`
     
     Keep consistent with the `ConnectString` in `config.cson`.

3. Enable your desired plugin in `src/plugins/faction`, as well as their template files in `src/templates` (copy, rename, and modify templates optionally)
   
   - `xmorose`
     
     Used by Shanghai Enlightened only.
     
     Template: `xmorose.cson`
   
   - `welcome`
     
     Welcome new agents.
     
     Template: `welcome.cson`
   
   - `hi`
     
     Respond hi when receiving hi/hello.
     
     Template: `hi.cson`
   
   - `ping`
     
     Respond pong when receiving ping.
     
     Template: `ping.cson`
   
   - `weather`
   
     Respond weather forecast and air quality (China only).
     
     Template: `weather.air.cson`, `weather.cson`
   
   - `train`
     
     Train bot.
     
     Syntax:
     
     Train: `@bot_name train RegExPattern ResponseString`
     
     Cancel: `@bot_name train RegExPattern`
     
     Template: `train.fail.cson`, `train.ok.cson`, `train.remove.cson`
   
   - `fallback`
     
     Some fallback responses.. (Chinese)
     
     Template: none
   
   - `auth`
     
     (experimental)
   
4. Install modules and compile files
   
   ```bash
   npm install -g grunt-cli
   npm install
   grunt
   cd ingress-exporter
   npm install
   grunt
   # cd ..
   ```
   
   Notice: You need to run `grunt` everytime you made changes (enable/disable plugin, modify template, modify config.cson)

5. Run

   ```bash
   node build/app.js
   ```
   
   Options:
   
   ```
   --auth false         Disable authentication when accessing APIs
   --debug true         Enable debug mode. In debug mode, messages won't be send
                        to real players
   ```

## API

```json
[
    {
        "method": "get",
        "path": "/manage/auth/tokens",
        "desciption": "List all tokens",
        "min_access_level": "LEVEL_ROOT"
    },
    {
        "method": "put",
        "path": "/manage/auth/:player/:level",
        "desciption": "Set access-level of all tokens of an agent",
        "min_access_level": "LEVEL_ROOT"
    },
    {
        "method": "post",
        "path": "/auth/token/:player",
        "desciption": "Generate a new token",
        "min_access_level": "LEVEL_GUEST"
    },
    {
        "method": "get",
        "path": "/auth/token/:token",
        "desciption": "Get detail of a token",
        "min_access_level": "LEVEL_GUEST"
    },
    {
        "method": "get",
        "path": "/help",
        "desciption": "Show help messages",
        "min_access_level": "LEVEL_GUEST"
    },
    {
        "method": "get",
        "path": "/portalhistory/:guid/:mintimestampms",
        "desciption": "Fetch the history of a protal",
        "min_access_level": "LEVEL_TRUSTED"
    },
    {
        "method": "post",
        "path": "/query/:collection",
        "desciption": "Query database",
        "min_access_level": "LEVEL_TRUSTED"
    },
    {
        "method": "get",
        "path": "/tracker/:player/:mintimestampms/:maxtimestampms",
        "desciption": "Track a player",
        "min_access_level": "LEVEL_TRUSTED"
    },
    {
        "method": "get",
        "path": "/tracker/:player/:page",
        "desciption": "Track a player",
        "min_access_level": "LEVEL_TRUSTED"
    }
]
```

## License

The MIT License (MIT)

Copyright (c) 2014 Breezewish