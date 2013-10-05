async = require 'async'
wd = require 'wd'
runr = require 'runr'
baseSteps = require './baseSteps'

propagate = (onErr, onSucc) -> (err, rest...) -> if err? then onErr(err) else onSucc(rest...)

setupBrowser = (host, { width, height, caps, wdArgs }, callback) ->
  caps ?= {}
  browser = wd.remote.apply(wd, wdArgs || [])
  browser.init caps, propagate callback, ->
    browser.get host, propagate callback, ->
      browser.setAsyncScriptTimeout 5000, propagate callback, ->
        browser.setWindowSize width, height, propagate callback, ->
          callback(null, browser)

exports.run = ({ output, tests, environments, testFolder, setupper }, callback) ->

  log = (args...) ->
    return if !output
    output.write(args.map((x) -> x ? '').join(' '))
    output.write('\n')

  failures = []

  killSelenium = runr.up 'selenium', { }, propagate callback, ->

    async.forEachSeries environments, (environment, callback) ->
      setupper.run {}, propagate callback, ({ host, destructor, beforeTest, afterTest }) ->
        log("running environemnt", environment)
        setupBrowser host, environment, propagate callback, (browser) ->

          funcs = []
          stepDef = (selector, handler) -> funcs.push({ selector, handler })
          baseSteps.defineSteps.call({ browser }, { step: stepDef, browserName: environment.browserName })

          async.forEachSeries tests, (feature, callback) ->
            log "FEATURE", feature.name, feature.tags

            async.forEachSeries feature.scenarios, (scenario, callback) ->
              log "  SCENARIO", scenario.name

              beforeTest scenario, browser, propagate callback, () ->
                async.forEachSeries scenario.steps, (step, callback) ->
                  log("    STEP", step.type, step.desc)

                  selected = funcs.filter((func) -> step.desc.match(func.selector))[0]

                  if !selected?
                    callback(new Error("No matching step"))
                  else
                    dasCallback = (err) ->
                      return callback() if !err?
                      callback({ err, step })

                    handler = selected.handler
                    matchArgs = step.desc.match(selected.selector).slice(1)
                    handler.apply({ browser }, matchArgs.concat(dasCallback))
                , (err) ->
                  failures.push(err) if err?
                  log("    ERROR: " + err.err?.message) if err?
                  afterTest(scenario, browser, callback)
            , callback
          , propagate callback, ->
            browser.quit propagate callback, ->
              destructor(callback)
    , propagate callback, ->
      killSelenium  propagate callback, ->
        callback(null, failures)
