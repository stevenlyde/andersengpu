## Overview ##
Points-to analysis is a compiler technique aimed at identifying which variables/objects are pointed by the pointers of the input program. The results of this compiler phase are useful for program optimization, program verification, debugging and whole program comprehension.

The algorithm presented here is a GPU (parallel) implementation of the context and flow insensitive, inclusion-based points-to analysis described by Ben Hardekopf in his PLDI'07 paper `[1]`. Below we provide some basic information about our parallel analysis, please check out our PPoPP [paper](http://www.clip.dia.fi.upm.es/~mario/files/ppo112-mendezlojo.pdf) `[2]` for more technical details and experimental results.

You might also want to take a look at our [twin project](http://code.google.com/p/andersencpu/), in which we parallelize the same algorithm using multiple CPU cores: the approach is actually quite different!
  1. B. Hardekopf, C. Lin. _The Ant and the Grasshopper: Fast and Accurate Pointer Analysis for Millions of Lines of Code_. PLDI 2007.
  1. M. Méndez-Lojo, M. Burtscher, K. Pingali. _A GPU Implementation of a Inclusion-based Points-to Analysis_. PPoPP 2012.

## Algorithm ##
The input for the points-to algorithm is the program to be analyzed. The output is a map from pointer variables to the set of variables they might point to. The analysis proceeds as follows:
  1. Extract pointer statements, which for the C language are _x_=&_y_,_x_=_y_,_x_=`*`_y_, and `*`_x_=_y_.
  1. Create the initial constraint graph. Each node corresponds to a program variable, and each edge (_x,y_) indicates that _x_ and _y_ appear together in a statement. The edges are tagged with the type of the statement they come from. For instance, a copy instruction such as _x_=_y_ results on a copy<sup>-1</sup> edge from _x_ to _y_.
  1. Iterate over the graph until no _rewrite rule_ needs to be applied. A rewrite rule is just the addition of a new points-to<sup>-1</sup> or copy<sup>-1</sup> edge to the graph, whenever some precondition is met. You can find more about these preconditions in the paper - for now just assume that there are certain pairs of edges that fire the addition of a third edge to the constraint graph.

The following pseudo-code shows the iterative phase of the points-to algorithm.
```
01 while (graph changed)
02   foreach (variable x: graph)
03     foreach (variable y : copy neighbors of x)
04       add points-to neighbors of y to points-to neighbors of x     
05     foreach (variable y : load neighbors of x)
06       add points-to neighbors of y to copy neighbors of x
07     foreach (variable y : points-to neighbors of x)
08       add store neighbors of y to copy neighbors of x
09     graph changed if neighbors of x changed
```
Eventually, the algorithm will reach a fixpoint (=is not possible to apply any new rewrite rule), so we can read the solution out of the points-to edges of the graph.

**Example:** A program written in C contains the statements _v_=&_w_;_y_=&_z_;_x_=_y_;_x_=_v_. Because there are four pointer statements and five variables, we initialize (left-most subfigure below) the constraint graph by adding five nodes and four edges. The edges are labeled with their type: p means "points-to", while c<sup>-1</sup> means "reversed copy". Then we apply the copy rule (lines 03-04) twice to reach fixpoint (right-most subfigure). From the final graph we can infer that the variables that _x_ might point to are _{w,z}_.

<img src='http://www.clip.dia.fi.upm.es/~mario/images/web_sync_copy_inv_rule.png' height='120px' />

## Data Structure ##
The constraint multi-graph is implemented using _wide_ sparse bit vectors. Every node has a number of sparse bit vectors associated with it, each one representing a certain type of edges (points-to, copy<sup>-1</sup>, etc). Wide bit vectors turn out to be a good match for the SIMD architecture of modern GPUs: each thread in the warp can perform operations in a subset of neighbors in a completely independent fashion.

## Parallelism ##
At any point of time, we can apply any rewrite rule independently of the others. The good news is that, as long as there are no two concurrent rules working on the same node, we do not depend on synchronization: nodes only add outgoing edges to themselves! This algorithmic simplicity results on avoiding Compare and Swap operations (for adding edges), which are known to result on a substantial performance penalty.

## Usage ##
The following instructions have been tested on a Linux machine running Ubuntu 12.04 and using the CUDA 5 toolkit. Note that in my experiments I only used NVIDIA Fermi GPUs (in particular: Quadro 6000, Geforce 580, Tesla C2050).

### Compilation ###
The setup is very similar to that of the samples included in the CUDA SDK:
  * if you are running a 64 bits host OS, install the 32-bit versions of the Zlib and C++ libraries. For example, in Ubuntu 12.04 you would install the packages `lib32z1-dev` and `g++-multilib`
  * checkout the source (click on the "Source" link above for precise instructions), and go to `apps/andersen`
  * configure `CUDA_INSTALL_PATH` in the file `Makefile` so it points to the CUDA root directory
  * modify the `HEAP_SIZE_MB` variable in the file `andersen.h` to match the amount of memory available in your GPU
  * invoke `make`

### Running ###
  * go to `apps/andersen` if you are not already there :-)
  * invoke `./run.sh TEST REPS`, where `TEST` is the input program and `REPS` is the number of times we want to run the analysis. For instance, if we want to analyze the `python` interpreter, we would type
```
./run.sh python 1
```