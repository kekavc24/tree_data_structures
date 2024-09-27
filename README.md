# tree_data_structures

This repository contains a collection of tree data structures I'm exploring. Included are:

1. [`AvlTree`](./lib/src/avl_tree/avl_tree.dart)
2. [`RadixTree`](./lib/src/radix_tree.dart)
3. [`PrintableTree`](./lib/src/printable_tree.dart)

## AvlTree

- Includes an `AvlTree` implementation that solely depends on the `comparator`
defined for a single instance of the tree. All exposed methods depend on the
`comparator` rather than a boolean `predicate`.

- Additional functionalities provided are as outlined by this [Research Paper](https://arxiv.org/abs/1602.02120) by `Guy Blelloch`, `Daniel Ferizovic` and
`Yihan Sun`.

- The implementation has some basic operations of an `AvlTree` (which canonically is also a `Set`) and separate (planned) implementations for:
  1. Joining 2 AvlTrees via a mutually exclusive key ✅
  2. Joining 2 AvlTree without key ❌
  3. Split an AvlTree via key ✅
  4. SplitLast ✅
  5. Insert via Split ❌
  6. Delete via Split ❌
  7. Union of 2 AvlTrees ❌ (Set operation)
  8. Intersection of 2 AvlTrees ❌ (Set operation)
  9. Difference of 2 AvlTrees ❌ (Set operation)

## [RadixTree](https://en.wikipedia.org/wiki/Radix_tree) (WIP)

A custom implementation of a prefix tree that uses:

1. A `HashMap` to store all the root nodes of the `RadixTree`.
2. An `AvlTree` to store all sub-nodes of a (root) node within a `RadixTree`.

## PrintableTree

A basic interface for displaying (debugging) any tree implemented. All trees
will explicitly implement this interface.
