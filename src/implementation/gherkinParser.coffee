gherkin = require 'gherkin'

exports.parse = (feat) ->

  lexerEn = gherkin.Lexer('en')
  data = []

  msgs = ['comment', 'tag', 'feature', 'background', 'scenario', 'scenario_outline', 'examples', 'step', 'doc_string', 'row', 'eof']
  listener = {}
  msgs.forEach (msg) ->
    listener[msg] = (args...) -> data.push({ type: msg, args })

  #formatter = require '../../node_modules/gherkin/lib/gherkin/formatter/json_formatter.js'
  #listener = new formatter(process.stdout)
  #listener.comment = ->
  #listener.tag = ->
  #listener.doc_string = ->
  #listener.row = ->

  lex = new lexerEn(listener)

  lex.scan(feat)

  root = { features: [] }
  nextTags = []

  data.forEach (d) ->
    if d.type == 'feature'
      root.features.push({
        name: d.args[1]
        scenarios: []
        tags: nextTags
      })
      nextTags = []
    else if d.type == 'scenario'
      currentFeature = root.features.slice(-1)[0]
      currentFeature.scenarios.push({
        feature: currentFeature
        name: d.args[1]
        steps: []
        tags: nextTags
      })
      nextTags = []
    else if d.type == 'step'
      currentScenario = root.features.slice(-1)[0].scenarios.slice(-1)[0]
      currentScenario.steps.push({
        scenario: currentScenario
        type: d.args[0]
        desc: d.args[1]
      })
      nextTags = []
    else if d.type == 'tag'
      nextTags.push(d.args[0])
    else if d.type not in ['comment', 'eof']
      console.log("missed", d.type)

  root
