# fbp-diff

[![Greenkeeper badge](https://badges.greenkeeper.io/flowbased/fbp-diff.svg)](https://greenkeeper.io/)

Diff utility for [FBP graphs](http://github.com/flowbased/fbp),
making it easier to determine changes compare to using a naive textual diff of the JSON files.

FBP graphs are used to specify a [Flow-based programming (FBP)](https://en.wikipedia.org/wiki/Flow-based_programming)
or dataflow program, consisting of processes and connections between them.
The processes are nodes in the graph, and the connections are edges.

## Related

fbp-diff is used by [fbp-diffbot](https://github.com/jonnor/fbp-diffbot) to provide diffs on Github pull requests.

## Status

**Minimally useful**

* `fbp-diff` give a textual diff of node/connection/IIP changes, from a `.json` or `.fbp` file
* `fbp-git-diff` can lookup diffs of a graph stored in `git`
* `fbp-git-log` can show the diffs for graph across many `git` revisions

## Installing

Note: You need to have [Node.js](https://nodejs.org) installed

Install locally (recommended)

    npm install fbp-diff

Alternative, install globally using NPM

    npm install -g fbp-diff

## Command-line usage

Add the command-line tools to PATH (not needed if installed globally)

    export PATH=./node_modules/.bin:$PATH

Diff between two graphs

    fbp-diff mygraph.json myothergraph.json

Diff between two versions of a graph stored in git

    fbp-git-diff master otherbranch ./graphs/MyGraph.json

## API Usage

fbp-diff also provides a JavaScript API.

```javascript
var fbpDiff = require('fbp-diff');
var options = {
  // fromFormat: 'object', // don't parse fromGraph, it is a JS object of a graph (default)
  // toFormat: 'json', // parse toGraph .json format
  format: 'fbp' // specify toFormat and fromFormat in one go
};
var fromGraph = "'hello' -> concat(Concatinator)\n'world' -> concat -> IN (Print)";
var toGraph = "'hello' -> IN (Print)";
var diff = fbpDiff.diff(fromGraph, toGraph, options);
console.log(diff);
```

## TODO

Also see [./doc/braindump.md](./doc/braindump.md)

### version 0.1 "minimally useful"

* Implement diffing of graph properties
* Implement basic grouping/heuristics/context to make the diff easier to understand
* Support diffing of process/edge metadata
* Support diffing of connection order changes

### Later

* Add a visual diffing tool
* Add a color-based text formatter. Should support console+HTML/Markdown
* Add a --raw mode, which outputs the calculated diff as JSON

