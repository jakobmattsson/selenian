_ = require 'underscore'
optimist = require 'optimist'
nconf = require 'nconf'
optionsCfg = require './options'

exports.createLoader = ({ loadPlugin, userConfigPath }) ->

  (options) ->

    argnames = _.pluck(optionsCfg, 'name')
    shortNames = _.pick(optimist.argv, argnames)

    nconf.overrides({ selenian: _.extend({}, options || {}, shortNames) }).argv()

    configs = nconf.get('selenian:configs') || 'package.json;config.json'

    configs.split(';').filter((x) -> x).forEach (file, i) ->
      nconf.file("file_#{i+1}", file)

    nconf.env('__')
    nconf.file("user", userConfigPath) if userConfigPath

    {
      source: nconf.get('selenian:source')
      setupper: nconf.get('selenian:setupper')
      includeTags: nconf.get('selenian:includeTags')
      excludeTags: nconf.get('selenian:excludeTags')
      grep: nconf.get('selenian:grep')
      environments: nconf.get('selenian:environments')
    }
