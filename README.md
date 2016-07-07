# fbp-diff

Diff utility for [FBP graphs](http://noflojs.org/documentation/json/),
making it easier to determine changes compare to using a naive textual diff of the JSON files.

## Status

**Prototype**

* `fbp-diff` can for give a primitive textual diff of node/connection/IIP changes
* `fbp-git-diff` can lookup diffs of a graph stored in git

## Installing

Note: You need to have [Node.js](https://nodejs.org) installed

Install locally (recommended)

    npm install fbp-diff

Alternative, install globally using NPM

    npm install -g fbp-diff

## Usage

Add the command-line tools to PATH (not needed if installed globally)

    export PATH=./node_modulex/.bin:$PATH

Diff between two graphs

    fbp-diff mygraph.json myothergraph.json

Diff between two versions of a graph stored in git

    fbp-git-diff master otherbranch ./graphs/MyGraph.json

## TODO

Also see [./doc/braindump.md](./doc/braindump.md)

### version 0.1 "minimally useful"

* Implement diffing of graph properties
* Implement diffing of exported in/outports

### Later

* Add a visual diffing tool
