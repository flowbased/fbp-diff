
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
            component: process.component
            name: name
            process: process
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

isIIP = (conn) ->
  return conn.data?
isEdge = (conn) ->
  return not isIIP(conn)

# NOTE: does not take metadata into account
connEquals = (a, b) ->
  return a.process == b.process and a.port == b.port and a.index == b.index
edgeEquals = (a, b) ->
  return connEquals(a.tgt, b.tgt) and connEquals(a.src, b.src)

connectionChanges = (from, to) ->
  # A connection can either be an edge (between two processes), or an IIP
  fromEdges = from.filter isEdge
  toEdges = to.filter isEdge
  fromIIPs = from.filter isIIP
  toIIPs = to.filter isIIP

  changes = []

  # Edge diffing
  for edge in fromEdges
    found = toEdges.filter (e) -> return edgeEquals edge, e
    if found.length == 0
      # removed
      changes.push
        type: 'edge-removed'
        data: edge
    else if found.length == 1
      # FIXME: implement diffing of order changes for edges
    else
      throw new Error "Found duplicate matches for edge: #{edge}\n #{found}"

  for edge in toEdges
    found = fromEdges.filter (e) -> return edgeEquals edge, e
    if found.length == 0
      # added
      changes.push
        type: 'edge-added'
        data: edge
    else if found.length == 1
      # FIXME: implement diffing of order changes for edges
    else
      throw new Error "Found duplicate matches for edge: #{edge}\n #{found}"

  # FIXME: implement diffing of IIPs
  # TODO: implement diffing of connection metadata. Per top-level key?
  return changes

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

formatEdge = (e) ->
  srcIndex = if e.src.index then "[#{e.src.index}]" else ""
  tgtIndex = if e.tgt.index then "[#{e.src.index}]" else ""
  return "#{e.src.process} #{e.src.port} -> #{e.tgt.port} #{e.tgt.process}"

formatChangeTextual = (change) ->
  d = change.data
  old = change.previous
  switch change.type
    when 'process-added' then "+ #{d.name}(#{d.process.component})"
    when 'process-removed' then "- #{d.name}(#{d.process.component})"
    when 'process-component-changed' then "$component #{d.name}(#{d.component}) was (#{old.component})"
    when 'edge-added' then "+ #{formatEdge(d)}"
    when 'edge-removed' then "- #{formatEdge(d)}"
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
