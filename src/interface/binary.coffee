process.on 'uncaughtException', (err) ->
  console.log('Uncaught exception!', err?.message || err)

optimist = require 'optimist'
selenian = require './api'
help = require '../implementation/help'

type = 'help' if optimist.argv.help
type = 'version' if optimist.argv.version

help.binaryMeta type, process.stdout, ->
  conf = selenian.load()
  conf.output = process.stdout
  selenian.run conf, (err, failures) ->
    if err?
      process.stdout.write(err)
      process.stdout.write('\n')
      process.exit(1)
      return

    selenian.formatOutput(failures)
    process.exit(if failures.length == 0 then 0 else 1)
