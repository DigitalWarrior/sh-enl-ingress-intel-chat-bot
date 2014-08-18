var Utils = GLOBAL.Utils = {

    extractIntelData: function(jsSource) {
        // To stay the same with IITC, we don't extract essential data directly,
        // instead, we build a virual environment, then call IITC functions.
        // 
        // Because of there are no `window` object in NodeJS, we need to expose
        // those global variables in order to let IITC functions work without
        // any modification.
        var window = {};
        var source = jsSource;

        // extract global variables
        var globalVars = [];

        var esprima = require('esprima');
        var escope = require('escope');

        var tree = esprima.parse(source);
        globalScope = escope.analyze(tree).scopes[0];
        globalScope.variables.forEach(function (v) {
            globalVars.push(v.identifiers[0].name);
        });

        // expose global variables
        globalVars.forEach(function(name) {
            source = source + ';window.' + name + ' = ' + name + ';';
        });

        // stimulate Google Map object
        source = 'var google={maps:{OverlayView:function(){}}};' + source;

        // execute JavaScript
        eval(source);
        Utils.extractFromStock(window);

        if (window.niantic_params.CURRENT_VERSION == undefined) {
            throw new Error('Failed to extract version');
        }

        return window.niantic_params;
    },

    // from IITC code
    extractFromStock: function(window) {
      var niantic_params = window.niantic_params = {}

      //TODO: need to search through the stock intel minified functions/data structures for the required variables
      // just as a *very* quick fix, test the theory with hard-coded variable names


      // extract the former nemesis.dashboard.config.CURRENT_VERSION from the code
      var reVersion = new RegExp('[a-z]=[a-z].getData\\(\\);[a-z].v="([a-f0-9]{40})";');


      var minified = new RegExp('^[a-zA-Z][a-zA-Z0-9]$');

      for (var topLevel in window) {
        if (minified.test(topLevel)) {
          // a minified object - check for minified prototype entries

          // the object has a prototype - iterate through the properties of that
          if (window[topLevel] && window[topLevel].prototype) {
            for (var secLevel in window[topLevel].prototype) {
              if (minified.test(secLevel)) {

                // looks like we've found an object of the format "XX.prototype.YY"...

                var item = window[topLevel].prototype[secLevel];

                if (item && typeof(item) == "function") {
                  // a function - test it against the relevant regular expressions
                  var funcStr = item.toString();

                  var match = reVersion.exec(funcStr);
                  if (match) {
                    //console.log('Found former CURRENT_VERSION in '+topLevel+'.prototype.'+secLevel);
                    niantic_params.CURRENT_VERSION = match[1];
                  }

                }

              }
            }

          }
        }
      }
    },

    //$.extend
    extend: function() {

        for (var i = 1; i < arguments.length; i++)
            for (var key in arguments[i])
                if (arguments[i].hasOwnProperty(key))
                    arguments[0][key] = arguments[i][key];

        return arguments[0];

    }

}