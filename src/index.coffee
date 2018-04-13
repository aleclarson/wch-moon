moonc = require 'moonc'
path = require 'path'
wch = require 'wch'
fs = require 'fsx'

plugin = wch.plugin()

# TODO: Start the moonc process.
plugin.on 'run', ->

  files = plugin.watch 'src',
    fields: ['name', 'exists', 'new', 'mtime_ms']
    include: ['**/*.moon']
    exclude: ['__*__']

  files
    .filter (file) -> file.exists
    .read compile
    .save (file) -> file.dest
    .then (dest, file) ->
      wch.emit 'file:build', {file: file.path, dest}

  files
    .filter (file) -> !file.exists
    .delete getDest
    .then (dest, file) ->
      wch.emit 'file:delete', {file: file.path, dest}

# TODO: Kill the moonc process.
# plugin.on 'stop', ->

plugin.on 'add', (root) ->
  root.dest = path.dirname root.main or 'dist/init'
  root.getDest = getDest
  return

module.exports = plugin

#
# Helpers
#

{log} = plugin

getDest = (file) ->
  path.join @path, @dest, file.name.replace /\.moon$/, '.lua'

compile = (input, file) ->
  file.dest = @getDest file
  try mtime = fs.stat(file.dest).mtime.getTime()
  return if mtime and mtime > file.mtime_ms

  if log.verbose
    log.pale_yellow 'Transpiling:', file.path

  try output = await moonc.promise input
  catch err
    line = parseLine err
    if line is undefined
      wch.emit 'file:error',
        file: file.path
        message: err.message
      return

    last_column = input.split('\n')[line].length
    wch.emit 'file:error',
      file: file.path
      message: err.message
      location: [[line, 0], [line, last_column]]

    if log.verbose
      log.red 'Failed to compile:', file.path
      log.gray err.message
    return

parseLine = (err) ->
  if match = /\[([0-9]+)\]/.exec err.message
    return -1 + Number match[1]
