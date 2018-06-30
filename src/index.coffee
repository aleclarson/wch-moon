moonc = require 'moonc'
path = require 'path'
wch = require 'wch'
fs = require 'fsx'

# TODO: Start the moonc process.
module.exports = (log) ->
  debug = log.debug 'wch-moon'

  shortPath = (path) ->
    path.replace process.env.HOME, '~'

  parseLine = (err) ->
    if match = /\[([0-9]+)\]/.exec err.message
      return -1 + Number match[1]

  compile = (input, file) ->
    try mtime = fs.stat(file.dest).mtime.getTime()
    return if mtime and mtime > file.mtime_ms

    debug 'Transpiling:', shortPath file.path
    try
      output = await moonc.promise input
      if typeof output isnt 'string'
        throw Error 'moonc failed: ' + file.path
      return output

    catch err
      line = parseLine err
      if line is undefined
        wch.emit 'file:error',
          file: file.path
          message: err.message
        return

      wch.emit 'file:error',
        file: file.path
        line: line
        message: err.message

      log log.red('Failed to compile:'), shortPath file.path
      log log.gray err.stack
      return

  build = wch.pipeline()
    .read compile
    .save (file) -> file.dest
    .each (dest, file) ->
      wch.emit 'file:build', {file: file.path, dest}

  clear = wch.pipeline()
    .delete (file) -> file.dest
    .each (dest, file) ->
      wch.emit 'file:delete', {file: file.path, dest}

  watchOptions =
    only: ['*.moon']
    skip: ['**/__*__/**']
    fields: ['name', 'exists', 'new', 'mtime_ms']
    crawl: true

  attach: (pack) ->
    dest = path.dirname path.resolve pack.path, pack.main or 'dist/init'
    changes = pack.stream 'src', watchOptions
    changes.on 'data', (file) ->
      file.dest = path.join dest, file.name.replace /\.moon$/, '.lua'
      action = if file.exists then build else clear
      action.call pack, file

  stop: ->
    # TODO: Kill the moonc process.
