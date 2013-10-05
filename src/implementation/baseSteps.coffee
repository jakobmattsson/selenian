wdTools = require 'wd-tools'

propagate = (onErr, onSuccess) -> (err, rest...) -> if err? then onErr(err) else onSuccess(rest...)

exports.defineSteps = ({ step, browserName }) ->

  step /^I hover "([^"]*)" and click "([^"]*)"$/, (hoverSelector, clickSelector, callback) ->
    wdTools.hoverClick(@browser, browserName, hoverSelector, clickSelector, callback)

  step /^I wait (\d+) ms$/, (delay, callback) ->
    setTimeout(callback, delay)

  step /^I clear "([^"]*)"$/, (selector, callback) ->
    wdTools.getSingleElement @browser, selector, propagate callback, (element) ->
      element.clear(callback)

  step /^I type "([^"]*)" into "([^"]*)"$/, (text, selector, callback) ->
    wdTools.getSingleElement @browser, selector, propagate callback, (element) ->
      element.type(text, callback)

  step /^I click "([^"]*)"$/, (selector, callback) ->
    wdTools.getSingleElement @browser, selector, propagate callback, (element) ->
      element.click(callback)

  step /^I click "([^"]*)" with an offset of (\-?\d+) and (\-?\d+)$/, (selector, xoffsetString, yoffsetString, callback) ->
    x = parseInt(xoffsetString)
    y = parseInt(yoffsetString)
    wdTools.getSingleElement @browser, selector, propagate callback, (element) =>
      @browser.moveTo element, x, y, propagate callback, =>
        @browser.click(0, callback)

  step /^"([^"]*)" should have a css width of between (\d+) and (\d+) px$/, (selector, minString, maxString, callback) ->
    min = parseFloat(minString)
    max = parseFloat(maxString)
    wdTools.getElementWidths @browser, selector, propagate callback, (widths) ->
      if widths.every((w) -> w >= min && w <= max)
        callback()
      else
        callback("Expected css width #{min}-#{max} but got #{widths.join(', ')}")

  step /^"([^"]*)" should have a css width of (\d+) px$/, (selector, widthString, callback) ->
    width = parseFloat(widthString)
    wdTools.getElementWidths @browser, selector, propagate callback, (widths) ->
      if widths.every((w) -> w == width)
        callback()
      else
        callback("Expected css width #{width} but got #{widths.join(', ')}")

  step /^"([^"]*)" should match (\d+) (visible )?element(?:s)?(, before and after refresh)?$/, (selector, count, visible, afterRefresh, callback) ->
    getFunc = wdTools[if visible then 'getVisibleElementsUntil' else 'getElementsUntil']

    test = (callback) =>
      getFunc @browser, selector, ((e) -> e?.length?.toString() == count), propagate callback, (elements) ->
        if elements?.length?.toString() == count
          callback()
        else
          callback(new Error("Expected selector #{selector} to match #{count} elements, not #{elements.length}"))

    test propagate callback, =>
      if afterRefresh
        @browser.refresh propagate callback, ->
          test(callback)
      else
        callback()

  step /^I open "([^"]*)"$/, (url, callback) ->
    wdTools.goto @browser, url, callback

  step /^I refresh$/, (callback) ->
    @browser.refresh(callback)

  step /^I am redirected to a path that matches "([^"]*)"$/, (exp, callback) ->
    regexp = new RegExp(exp)
    wdTools.checkUrlPredicate @browser, ((url) -> url && url.match(regexp)), (matched, url) ->
      if !matched
        callback(new Error("Expected the url #{url} to match #{exp}"))
      else
        callback()

  step /^I am redirected to a path that starts with "([^"]*)"$/, (expectedUrl, callback) ->
    wdTools.resolveUrl @browser, expectedUrl, propagate callback, (expected) =>
      wdTools.checkUrlPredicate @browser, ((url) -> url && url.slice(0, expected.length) == expected), (matched, url) ->
        if !matched
          callback(new Error("Expected the url #{url} to start with #{expectedUrl}"))
        else
          callback()

  step /^I am redirected to "([^"]*)"$/, (expectedUrl, callback) ->
    wdTools.resolveUrl @browser, expectedUrl, propagate callback, (expected) =>
      wdTools.checkUrlPredicate @browser, ((url) -> url == expected), (matched, url) ->
        if !matched
          callback(new Error("Expected to be on the url #{expected} but got to #{url}"))
        else
          callback()
