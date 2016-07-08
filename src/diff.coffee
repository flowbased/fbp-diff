
clone = (obj) ->
  return JSON.parse(JSON.stringify(obj))
jsonEquals = (a, b) ->
  return JSON.stringify(a) == JSON.stringify(b)

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
iipEdgeEquals = (a, b) ->
  return connEquals(a.tgt, b.tgt) and jsonEquals(a.data, b.data)

# TODO: distinguish between just the IIP payload changing, and just target of the IIP
iipChanges = (from, to) ->
  changes = []
  # IIP diffing
  for edge in from
    found = to.filter (e) -> return iipEdgeEquals edge, e
    if found.length == 0
      # removed
      changes.push
        type: 'iip-removed'
        data: edge
    else if found.length == 1
      # FIXME: implement diffing of order changes for IIPs
    else
      throw new Error "Found duplicate matches for IIP: #{edge}\n #{found}"
  for edge in to
    found = from.filter (e) -> return iipEdgeEquals edge, e
    if found.length == 0
      # added
      changes.push
        type: 'iip-added'
        data: edge
    else if found.length == 1
      # FIXME: implement diffing of order changes for IIPs
    else
      throw new Error "Found duplicate matches for IIP: #{edge}\n #{found}"

  return changes

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

  changes = changes.concat iipChanges(fromIIPs, toIIPs)

  # TODO: implement diffing of connection metadata. Per top-level key?
  return changes

  # TODO: deduce when port was just renamed
portChanges = (from, to, kind) ->
  throw new Error "Unsupported exported port kind: #{kind}" if not (kind in ['inport', 'outport'])

  changes = []

  fromNames = Object.keys from
  toNames = Object.keys to

  for name, target of from
    existsNow = name in toNames
    if not existsNow
      # removed
      changes.push
        type: "exported-port-removed"
        kind: kind
        data:
          name: name
          target: target

  for name, target of to
    if name in fromNames
      fromTarget = from[name]
      if not connEquals(target, fromTarget)
        changes.push
          type: "exported-port-target-changed"
          kind: kind
          data:
            name: name
            target: target
          previous:
            target: fromTarget
    else
      # added
      changes.push
        type: "exported-port-added"
        kind: kind
        data:
          name: name
          target: target

  return changes

removeByPredicate = (array, predicate) ->
  removeIndices = []
  for item, idx in array
    removeIndices.push idx if predicate(item, idx, array)

  removed = []
  for item, idx in array
    if idx in removeIndices
      # removed, don't include
    else
      removed.push item

  return removed

findRenamedExports = (changes, kind) ->
  rewritten = changes

  findTargets = (type) ->
    c = changes.filter (c) -> c.type == type and c.kind == kind
    t = c.map (c) -> return "#{c.process}.#{c.port}"
    res =
      changes: c
      targets: t
    return res


  added = findTargets 'exported-port-added'
  removed = findTargets 'exported-port-removed'

  for target, targetIdx in removed.targets
    addedIdx = added.targets.indexOf target
    if addedIdx != -1
      # both added and removed exported port, targeting the same node+port was -> a rename
      a = added.changes[addedIdx]
      r = removed.changes[targetIdx]

      if not connEquals(a.data.target, r.data.target)
        throw new Error "Sanity check failed, rename match did not have same target"

      # rewrite changes
      rewritten = removeByPredicate rewritten, (item) ->
        exportedPort = (item.type == 'exported-port-added' or item.type == 'exported-port-removed')
        targetEquals = connEquals a.data.target, item.data.target
        return item.kind == kind and exportedPort and targetEquals

      rewritten.push
        type: 'exported-port-renamed'
        kind: kind
        data: a.data
        previous:
          name: r.data.name

  return rewritten
  
applyHeuristics = (changes) ->
  rewritten = clone changes
  rewritten = findRenamedExports(rewritten, 'inport')
  rewritten = findRenamedExports(rewritten, 'outport')

  return rewritten

# calculate a list of changes between @from and @to
calculateDiff = (from, to) ->

  # this is just the basics/dry-fact view. Any heuristics etc is applied afterwards
  changes = []

  # nodes added/removed
  changes = changes.concat processChanges(from.processes, to.processes)

  # edges added/removed
  changes = changes.concat connectionChanges(from.connections, to.connections)
  
  # exported port changes
  changes = changes.concat portChanges(from.inports, to.inports, 'inport')
  changes = changes.concat portChanges(from.outports, to.outports, 'outport')

  # FIXME: diff graph properties
  # TODO: support diffing of groups

  diff = 
    raw: changes
    changes: applyHeuristics changes
  return diff

formatEdge = (e) ->
  srcIndex = if e.src.index then "[#{e.src.index}]" else ""
  tgtIndex = if e.tgt.index then "[#{e.tgt.index}]" else ""
  return "#{e.src.process} #{e.src.port}#{srcIndex} -> #{e.tgt.port}#{tgtIndex} #{e.tgt.process}"
formatIIP = (e) ->
  tgtIndex = if e.tgt.index then "[#{e.tgt.index}]" else ""
  return "#{JSON.stringify(e.data)} -> #{e.tgt.port}#{tgtIndex} #{e.tgt.process}"
formatExport = (type, tgt, name) ->
  return "#{type.toUpperCase()}=#{tgt.process}.#{tgt.port}:#{name}"

# TODO: include connection index for edges and IIPs?
formatChangeTextual = (change) ->
  d = change.data
  old = change.previous
  switch change.type
    when 'process-added' then "+ #{d.name}(#{d.process.component})"
    when 'process-removed' then "- #{d.name}(#{d.process.component})"
    when 'process-component-changed' then "$component #{d.name}(#{d.component}) was (#{old.component})"
    when 'edge-added' then "+ #{formatEdge(d)}"
    when 'edge-removed' then "- #{formatEdge(d)}"
    when 'iip-added' then "+ #{formatIIP(d)}"
    when 'iip-removed' then "- #{formatIIP(d)}"
    when 'exported-port-added' then "+ #{formatExport(change.kind, d.target, d.name)}"
    when 'exported-port-removed' then "- #{formatExport(change.kind, d.target, d.name)}"
    when 'exported-port-target-changed' then ". #{formatExport(change.kind, d.target, d.name)} was #{formatExport(change.kind, old.target, d.name)}"
    when 'exported-port-renamed' then ".rename #{formatExport(change.kind, d.target, d.name)} was #{formatExport(change.kind, d.target, old.name)}"
    else
      throw new Error "Cannot format unsupported change type: #{change.type}"

# TODO: group changes
formatDiffTextual = (diff, options) ->
  lines = []
  for change in diff.changes
    lines.push formatChangeTextual change
  return lines.join('\n')

# TODO: validate graph against schema
readGraph = (contents, type, options) ->
  fbp = require 'fbp'
  if type == 'fbp'
    graph = fbp.parse contents, { caseSensitive: options.caseSensitive }
  else if type == 'object'
    graph = contents
  else
    graph = JSON.parse contents

  # Normalize optional params
  graph.inports = {} if not graph.inports?
  graph.outports = {} if not graph.outports?

  return graph

# TODO: support parsing up a diff from the textual output format?
# Mostly useful if/when one can apply diff as a patch

# diff two graphs
exports.diff = (from, to, options) ->
  options = normalizeOptions options

  f = readGraph from, options.fromFormat, options
  t = readGraph to, options.toFormat, options

  diff = calculateDiff f, t
  out = formatDiffTextual diff

  return out

normalizeOptions = (options) ->
  options = clone options
  options.format = 'object' if not options.format?
  options.fromFormat = options.format if not options.fromFormat?
  options.toFormat = options.format if not options.toFormat?
  options.caseSensitive = true if not options.caseSensitive?
  return options

# node.js only
readGraphFile = (filepath, options, callback) ->
  fs = require 'fs'
  path = require 'path'

  type = path.extname(filepath).replace('.', '')
  fs.readFile filepath, { encoding: 'utf-8' }, (err, contents) ->
    return callback err if err
    try
      graph = readGraph contents, type, options
    catch e
      return callback e
    return callback null, graph

diffFiles = (fromPath, toPath, options, callback) ->
  readGraphFile fromPath, options, (err, fromGraph) ->
    return callback err if err
    readGraphFile toPath, options, (err, toGraph) ->
      return callback err if err

      options.format = 'object' # already loaded
      out = exports.diff fromGraph, toGraph, options
      return callback null, out

exports.diffFiles = diffFiles

exports.main = main = () ->
  [_node, _script, from, to] = process.argv

  callback = (err, output) ->
    throw err if err
    console.log output

  options = {}
  options = normalizeOptions options
  return diffFiles from, to, options, callback

