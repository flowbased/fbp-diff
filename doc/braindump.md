
# Basics

* Should be able to be used as library, including in Flowhub.
* Should be usable on command-line, both interactively and in scripts.

# Desired information

Things that can change: nodes, connections, IIPs, inports, outports.
Also meta-data about each of these, plus graph metadata.

Basic usage

    fbp-diff A.json B.fbp

Exit status should reflect whether there are changes or not

Maybe use heuristics to determine 'changes' from things that were both added and removed,
similar to how git does 'rewrote file 100%'.

Example includes:

- group changes
- node id changed
- component type changed (and possibly node id at same time)

Showing meta-data changes (or only 'real changes') should probably be an option.

## details mode:

    + 'IIP' -> foo
    + baz(BazComp)
    - bazbaz(BazComp)
    - foo CONN -> IN bar

How should these lines be sorted?
Ideally the adjacency of graph would be taken into account, so related changes are grouped together.
Most changes are relative to a particular *node*, so sorting by affected source/target might be an OK starting point.
It is also relatively common for graphs to 'flow' left-to-right, so that is ideally respected too.

## summary mode:
    
Many changes

    Added N nodes, M connections, L IIPs, 
    Removed ...

One/few changes

    Removed IIP 'ss' -> a

Should it always be a one-liner, like git log --pretty=oneline?

## stat mode:

For ease of parsing with other tools. One line per

    Nodes added: N
    Nodes removed: M
    Connections added: M
    ...

# Implementation

Can perhaps use some code in [Noflo.Graph](https://github.com/noflo/noflo/blob/master/src/lib/Graph.coffee)
and/or [NoFlo.Journal](https://github.com/noflo/noflo/blob/master/src/lib/Journal.coffee)?
Would then be beneficial if Journal and Graph was split out of NoFlo...

Other possibly useful libs

* Graph theory and visualization, [Cytoscape](http://js.cytoscape.org/#demos)


# git integration

Custom git diff/merge tools hwoto: [1](http://stackoverflow.com/questions/255202/how-do-i-view-git-diff-output-with-a-visual-diff-program)
Might need some sniffing capability to determine whether a given .json file is a FBP graph or not. `fbp-validate`?

Let Flowhub store a textual diff and/or summary into git commits?
Appended in message and/or a [git note](https://www.kernel.org/pub/software/scm/git/docs/git-notes.html).
Could be useful to look at git logs/history and understand changes without using fbp-diff, for instance in Github

# Ui/visualization

Would show a visual diff between two versions of a graph.
Should probably be a separate executable `fbp-visualdiff`.

Would need to respect the node position metadata left by Flowhub.

Some prior art on visual diffing:

* Image diffs by Github, https://help.github.com/articles/rendering-and-diffing-images/
* Map diffs by Github, https://www.mapbox.com/blog/github-visual-diff/
* 3d file diffs by Github, https://github.com/blog/1633-3d-file-diffs

The `onion skinning` approach might work OK.

A challenging is that node positions tend to change a bit.
If  they have moved a lot, it may be hard to spot what actually changed. Connections/nodes etc
Would be nice to be able to 'trace' / 'animate' the movements.
Remove/add goes to 0/100% opacity over ~half range of slider, movements animate to/from position over whole range?

Use [the-graph](https://github.com/the-grid/the-graph) to implement?

Would be useful to have also on cmdline.
In interactive case, perhaps it can just spawn a browser which computes diff and displays?
For non-interactive, just run&render with PhantomJS?
Or use a node.js compatible visualizer, maybe using node-canvas etc?

# Applying diffs

The inverse to a `diff` command is `patch`.
Could we store/output our diffs in a way they can be applied as a patch?
Would allow to apply the change of one git commit (which only stores textual differences) to another version of a graph.
It could also assist in automated merge handling, as a textual merge conflict might resolve as a FBP diff+patch.

Some changes might also apply to other, similar graphs: Starting to look more like general refactoring support.
Might require generalizations though, like `-+ *(Component) *(NewComponent)` to match regardless of node name.
Some more refactoring ideas found here: https://github.com/jonnor/projects/tree/master/fbp-meta

# Merge conflicts

In text-based diffing, a merge conflict occurs if two changes are done to the same lines of text/code.
This is a very loose definition, for instance, a change of function name in one changeset
can easily break another changeset (referring the old function name).
It only considers the data-format, not the semantics of the data.

One could to the same with FBP graphs, only consider the validity of the JSON when determining whether a merge is conflicting or not.
But one still needs to decide on granularity. Are two changes in `connections` always conflicting, since its one ordered collection?
Or are only changes which cause changes in ordering. Or only changes to the same connection object?
Operational transforms might allow to automatically handle some cases which would seem to be conflicting naively.

A more semantically aware approach is also possible.
`connections`, `inports` and so on refer to `nodes` (and the `ports` of the `Component` the node is).


One would also have to decide if the merging should consider `metadata` or not.
Some metadata is more volatile, and less semantically important that others.
Consider difference between node position (updated whenever moving things around in Flowhub),
and `guv` autoscaling config for instance.

# .fbp roundtrips?

Currently the FBP library parses .fbp into a JSON representation, but there is no .fbp renderer.
It would be nice to allow to get a patched .fbp file as .fbp, with minimal changes.

Also, during parsing, some information is currently lost. Notably comments, and formatting
(whether connections are on one line, split over multiple, where component instance is specified...).
There is also no group concept, though probably one could have based on text-blocks delimited by a whitespace-only line?
Comments could maybe be put in group, node, connection metadata?


# Merge support?

Would have to both view/visualize the differences, and allow to change the graph to get to resolved state.
Minimum viable: visualization of both original states (A, B) and resolved states (C) as image+editable JSON
Ideally this would be a part of workflow in Flowhub IDE

# Component diffing?

Should the tool also support diffing (text) components or only do graphs?
Would be mostly as fallback... Perhaps better to error out, and leave this to tools dedicated to the purpose.

# Filtering?

If one is only interested in changes affecting a particular *node* (or *component*),
perhaps one could specify that as a filter. Exit status would also reflect.
