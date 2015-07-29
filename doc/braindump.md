# Desired information

Things that can change: nodes, connections, IIPs, inports, outports
Also meta-data about each of these, plus graph metadata.

Basic usage

    fbp-diff A.json B.fbp

Exit status should reflect whether there are changes or not

Maybe use heuristics to determine 'changes' from things that were both added and removed,
similar to how git does 'rewrote file 100%'.

## details mode:

    + 'IIP' -> foo
    + baz(BazComp)
    - bazbaz(BazComp)
    - foo CONN -> IN bar

How should these lines be sorted?
Ideally the adjacency would be taken into account. All 

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



Can perhaps use some code in Noflo.Graph and/or NoFlo.Journal?
https://github.com/noflo/noflo/blob/master/src/lib/Graph.coffee
https://github.com/noflo/noflo/blob/master/src/lib/Journal.coffee
Would then be beneficial if Journal and Graph was split out of NoFlo...

Other possibly useful libs

* Graph theory and visualization: http://js.cytoscape.org/#demos


# git integration

http://stackoverflow.com/questions/255202/how-do-i-view-git-diff-output-with-a-visual-diff-program
Might need some sniffing capability to determine whether a given .json file is a FBP graph or not.
`fbp-validate`?

# Ui/visualization

Would show a visual diff between two versions of a graph.
Should probably be a separate executable `fbp-visualdiff`.

Some prior art on visual diffing:

* Image diffs by Github, https://help.github.com/articles/rendering-and-diffing-images/
* Map diffs by Github, https://www.mapbox.com/blog/github-visual-diff/
* 3d file diffs by Github, https://github.com/blog/1633-3d-file-diffs

The onion-skinning approach might work well

Use the-graph to implement? https://github.com/the-grid/the-graph

Would be useful to have also on cmdline.
In interactive case, perhaps it can just spawn a browser which computes diff and displays?
For non-interactive

# Merge support?

Would have to both view/visualize the differences,
and allow to change.
Minimum viable: visualization of both original states (A, B) and resolved state (C) as image+editable JSON
Ideally this would be a part of workflow in Flowhub IDE

# Component diffing?

Should the tool also support diffing (text) components or only do graphs?
Would be mostly as fallback..
