
clone = (obj) ->
  return JSON.parse(JSON.stringify(obj))

processChanges = (from, to) ->
  changes = []

  fromNames = Object.keys from
  toNames = Object.keys to

  for name, process of from
    if name not in toNames
      changes.push
        type: 'process-removed'
        data:
          name: name
          process: clone process

  for name, process of to
    if name in fromNames
      oldComponent = from[name].component
      if process.component != oldComponent
        changes.push
          type: 'process-component-changed'
          data:
            component: component
          previous:
            component: oldComponent
      # TODO: implement diffing of node metadata. Per top-level key?
    else
      changes.push
        type: 'process-added'
        data:
          name: name
          process: clone process

  return changes

connectionChanges = (from, to) ->
  # FIXME: implement diffing of edges
  # FIXME: implement diffing of IIPs
  # TODO: implement diffing of connection metadata. Per top-level key?
  return []

# calculate a list of changes between @from and @to
# this is just the basics/dry-fact view. Any heuristics etc is applied afterwards
calculateDiff = (from, to) ->
  changes = []

  # nodes added/removed
  changes = changes.concat processChanges(from.processes, to.processes)

  # edges added/removed
  changes = changes.concat connectionChanges(from.connections, to.connections)
  
  # FIXME: diff graph properties
  # FIXME: diff exported inport/outport changes
  # TODO: support diffing of groups

  diff = 
    changes: changes
  return diff

formatChangeTextual = (change) ->
  d = change.data
  old = change.previous
  switch change.type
    when 'process-added' then "+ #{d.name}(#{d.process.component})"
    when 'process-removed' then "- #{d.name}(#{d.process.component})"
    when 'process-component-changed' then "$component #{d.name}(#{d.process}) was (#{d.process})" # XXX: is this a good formatting?
    else
      throw new Error "Cannot format unsupported change type: #{change.type}"

# TODO: group changes
formatDiffTextual = (diff, options) ->
  lines = []
  for change in diff.changes
    lines.push formatChangeTextual change
  return lines.join('\n')

# TODO: validate graph against schema
readGraph = (contents, type) ->
  fbp = require 'fbp'
  if type == 'fbp'
    return fbp.parse contents
  else
    return JSON.parse contents

# TODO: support parsing up a diff from the textual output format?
# Mostly useful if/when one can apply diff as a patch

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

      diff = calculateDiff fromGraph, toGraph
      out = formatDiffTextual diff
      console.log out
