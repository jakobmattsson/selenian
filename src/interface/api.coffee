fs = require 'fs'
path = require 'path'
wrench = require 'wrench'
_ = require 'underscore'
selenian = require '../implementation/selenian'
parser = require '../implementation/gherkinParser'
config = require '../implementation/load-config'

exports.load = config.createLoader({
  loadPlugin: null # not used. yet.
  userConfigPath: path.resolve(process.env.HOME, ".selenian")
})

exports.formatOutput = (stream, failures) ->
  stream.write('\n')

  if failures.length == 0
    stream.write("SUCCESS!\n")
    return

  stream.write('\n')
  stream.write("To reproduce the failures:\n")
  failures.forEach (x) ->
    stream.write("selenian --grep '^#{x.step.scenario.name}$'\n")

exports.run = ({ output, includeTags, excludeTags, source, environments, setupper, grep }, callback) ->

  log = (str) ->
    return if !output
    output.write(str ? '')
    output.write('\n')

  sources = wrench.readdirSyncRecursive(source).filter (x) -> path.extname(x) == '.feature'
  roots = sources.map (s) -> parser.parse(fs.readFileSync(path.resolve(source, s)))
  allFeatures = _.flatten(roots.map((x) -> x.features))

  tagFilter = (include, exclude) ->
    include ||= []
    exclude ||= []
    (s) -> (
      include.length == 0 ||
      _.intersection(s.tags, include).length > 0 ||
      _.intersection(s.feature.tags, include).length > 0
    ) && (
      _.intersection(s.tags, exclude).length == 0 &&
      _.intersection(s.feature.tags, exclude).length == 0
    )

  filteredFeatures = allFeatures.map (feature) ->
    name: feature.name
    tags: feature.tags
    scenarios: feature.scenarios.filter(tagFilter(includeTags, excludeTags)).filter (s) -> !grep? || s.name.match(grep)

  extendedEnvironments = environments.map (e) ->
    _.extend({}, e, {
      tests: filteredFeatures.map (feature) ->
        name: feature.name
        tags: feature.tags
        scenarios: feature.scenarios.filter(tagFilter(e.tags?.include, e.tags?.exclude))
    })

  selenian.run {
    output: output
    environments: extendedEnvironments
    setupper: setupper
  }, callback
