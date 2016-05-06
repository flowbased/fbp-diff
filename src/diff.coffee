
# calculate a list of changes between @from and @to
calculateDiff = (from, to) ->
  return [] # FIXME: implement diffing

formatDiffTextual = (diff) ->
  return "" # FIXME: implement formatting

readGraph = (contents, type) ->
  fbp = require 'fbp'
  if type == 'fbp'
    return fbp.parse contents
  else
    return JSON.parse contents

# node.js only
readGraphFile = (filepath, callback) ->
  fs = require 'fs'
  path = require 'path'

  type = path.extname(filepath).replace('.', '')
  fs.readFile filepath, { encoding: 'utf-8' }, (err, contents) ->
    return callback err if err
    try
      graph = readGraph contents
    catch e
      return callback e
    return callback null, graph

exports.main = main = () ->
  [_node, _script, from, to] = process.argv

  callback = (err, output) ->
    throw err if err
    console.log output

  readGraphFile from, (err, fromGraph) ->
    return callback err if err
    readGraphFile to, (err, toGraph) ->
      return callback err if err

main() if not module.parent
