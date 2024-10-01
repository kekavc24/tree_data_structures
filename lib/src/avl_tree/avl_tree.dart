import 'dart:math';

import 'package:tree_data_structures/src/printable_tree.dart';

part 'avl_tree_difference.dart';
part 'avl_tree_intersection.dart';
part 'avl_tree_union.dart';
part 'avl_tree_utils.dart';
part 'join_avl_trees.dart';
part 'split_avl_tree.dart';

/// A basic implementation of an `AVL Tree` which is a self-balancing binary
/// search tree but with a cheeky trick.
///
/// See https://en.wikipedia.org/wiki/AVL_tree
class AvlTree<T> implements PrintableTree {
  AvlTree._(this._root, this.comparator) {
    if (_root == null) return;
    _updateHighLow(_root!.value);
  }

  /// [comparator] - used to compare elements before insertion. The function
  /// is shadow definition of [Comparable].
  AvlTree.empty({
    required BinaryCompare<T, T> comparator,
  }) : this._(null, comparator);

  factory AvlTree.of(
    T root, {
    required BinaryCompare<T, T> comparator,
    required Iterable<T> children,
  }) {
    final tree = AvlTree._(
      _AvlNode.of(root, left: null, right: null),
      comparator,
    );

    for (final value in children) {
      tree.insert(value);
    }

    return tree;
  }

  ///
  final BinaryCompare<T, T> comparator;

  /// Node at the root of the tree
  _AvlNode<T>? _root;

  T? _lowest;

  T? _highest;

  /// Returns the value at the root of the tree. Returns null if the tree is
  /// empty.
  T? get root => _root?.value;

  /// Returns the smallest value in the tree
  T? get lowest => _lowest;

  /// Returns the largest value in the tree
  T? get highest => _highest;

  /// Returns the number of elements in this collection.
  int get length => _numOfNodes(_root);

  /// Returns the longest path to a leaf node.
  int get height => _height(_root);

  @override
  bool get isEmpty => _root == null;

  @override
  String get name => 'AvlTree';

  @override
  List<PrintableNode> get rootNodes => [if (!isEmpty) _root!];

  /// Updates [_root] with [node] provided
  void _updateRoot(_AvlNode<T>? node) {
    if (node == null) {
      _lowest = null;
      _highest = null;
    }

    _root = node;
  }

  /// Updates the [_lowest] and/or [_highest] values in the tree
  void _updateHighLow(T value) {
    if (_lowest == null && _highest == null) {
      _lowest = value;
      _highest = value;
      return;
    }

    if (comparator(value, _lowest as T) < 0) {
      _lowest = value;
      return;
    }

    if (comparator(value, _highest as T) > 0) {
      _highest = value;
    }
  }

  void _overwriteLowHigh(T old, T potential) {
    if (comparator(old, _lowest as T) == 0) {
      _lowest = potential;
    } else if (comparator(old, _highest as T) == 0) {
      _highest = potential;
    }
  }

  /// Removes all objects present in this tree.
  void clear() => _updateRoot(null);

  /// Swaps an [AvlTree] with another without checking the [comparator]'s
  /// rules thus its cheekiness.
  ///
  /// It should be noted this method only swaps the reference of the [root]
  /// and [length]. The [comparator] remains unchanged. Ensure that both
  /// this tree and the [other] tree share the same [comparator] rules before
  /// swapping.
  void swapWith(AvlTree<T> other) => _updateRoot(other._root);

  /// Adds an value to the tree
  void insert(T value) {
    final newNode = _AvlNode(value);

    var didAdd = true;

    if (isEmpty) {
      _updateRoot(newNode);
    } else {
      didAdd = _addNode(_root!, newNode);
    }

    if (didAdd) _updateHighLow(value);
  }

  /// Returns the first element that matches the rules of the [uComparator]
  /// provided where `[uComparator(value) == 0]`.
  ///
  /// **Example**
  /// ```dart
  /// final tree = AvlTree<int>(comparator: (a, b) => a.compareTo(b))
  ///   ..insert(10)
  ///   ..insert(11)
  ///   ..insert(4)
  ///   ..insert(12)
  ///   ..insert(1)
  ///   ..insert(9)
  ///   ..insert(8)
  ///   ..insert(14)
  ///   ..insert(7);
  ///
  /// final value = avlTree.firstWhere((value) {
  ///   if (value < 10 && value > 4) return 0;
  ///
  ///   if (value <= 4) return 1;
  ///   return -1;
  /// });
  ///
  /// print(value); // Prints 8
  /// ```
  T? firstWhere(UnaryCompare<T> uComparator) {
    return _matchFirst(_root, uComparator)?.value;
  }

  /// Checks whether this [element] exists.
  ///
  /// If [searchFunc] is provided, elements are evaluated based on this
  /// [BinaryCompare] function. Otherwise, the default [BinaryCompare]
  /// function is used.
  bool contains(T element, [BinaryCompare<T, T>? searchFunc]) {
    return _search(
            start: _root,
            needle: element,
            searchFunc: searchFunc ?? comparator) !=
        null;
  }

  /// Removes an [element].
  ///
  /// If [searchFunc] is provided, elements are evaluated based on this
  /// [BinaryCompare] function. Otherwise, the default [BinaryCompare]
  /// function is used.
  ///
  /// Returns `true` if an element was removed. Otherwise, `false`.
  bool remove(T element, [BinaryCompare<T, T>? searchFunc]) {
    final removeFunc = searchFunc ?? comparator;
    final node = _search(
      start: _root,
      needle: element,
      searchFunc: removeFunc,
    );
    return _removeNode(node, removeFunc);
  }

  /// Removes the first element that matches the rules of the [uComparator]
  /// provided where `[uComparator(value) == 0]`.
  ///
  /// Returns a [bool] indicating whether the node was removed and the
  /// node removed if any.
  (bool didRemove, T? node) removeFirstWhere(UnaryCompare<T> uComparator) {
    final node = _matchFirst(_root, uComparator);
    return (
      _removeNode(node, (_, other) => uComparator(other)),
      node?.value,
    );
  }

  /// Returns a [List] of elements based on the [Transversal] order
  /// specified.
  ///
  /// If a [filter] is provided, only elements that evaluate to `true` are
  /// returned.
  Set<T> ordered({
    Transversal transversal = Transversal.inOrder,
    Predicate<T>? filter,
  }) {
    final ordered = <T>{};

    if (isEmpty) return ordered;

    final predicate = filter ?? (T value) => true;

    final _ = switch (transversal) {
      Transversal.preOrder => _preOrder(ordered, _root!, predicate),
      Transversal.postOrder => _postOrder(ordered, _root!, predicate),
      Transversal.inOrder => _inOrder(ordered, _root!, predicate),
      Transversal.breadthFirst => _breadthFirst(ordered, [_root!], predicate),
    };

    return ordered;
  }

  /// Recursively checks and adds a node at the relevant point in the tree
  bool _addNode(_AvlNode<T> parent, _AvlNode<T> child) {
    final _AvlNode(:value, :left, :right) = parent;

    _AvlNode<T>? target;

    final comparison = comparator(child.value, value);

    if (comparison == 0) return false; // No duplicates

    var didAdd = true;

    // Add to the left of tree
    if (comparison < 0) {
      if (left == null) {
        parent.left = child;
      } else {
        target = left;
      }
    } else {
      if (right == null) {
        parent.right = child;
      } else {
        target = right;
      }
    }

    if (target != null) {
      didAdd = _addNode(target, child);
    } else {
      child.parent = parent;
    }

    _updateHeight(parent);

    /// Insertion may cause the tree to be unbalanced. Attempt to rebalance if
    /// unbalanced
    _rebalance(
      parent,
      comparator: comparator,
      updateRoot: _updateRoot,
    );

    return didAdd;
  }

  /// Removes a node from the tree based on a [searchFunc].
  ///
  /// Returns `true` only if `[searchFunc(value, other) == 0]`. Otherwise,
  /// `false`.
  bool _removeNode(_AvlNode<T>? node, BinaryCompare<T, T> searchFunc) {
    if (node == null) return false;

    final _AvlNode<T>(:parent, :left, :right, :value) = node;

    _AvlNode<T>? replacement;

    // // Prefer left when deleting
    if (left != null) {
      replacement = _extractReplacement(node, highestOnLeft: true);

      /// Take over the left branch only if the `replacement` is not the value
      /// on the left. Access directly from node incase some rotations
      /// occurred.
      if (replacement != null &&
          comparator(node.left!.value, replacement.value) != 0) {
        replacement.left = node.left;
      }
    } else if (right != null) {
      replacement = _extractReplacement(node, highestOnLeft: false);

      /// Take over the right branch only if the `replacement` is not the value
      /// on the right. Access directly from node incase some rotations
      /// occurred.
      if (replacement != null &&
          comparator(node.right!.value, replacement.value) != 0) {
        replacement.right = node.right;
      }
    }

    final hasParent = parent != null;

    if (replacement != null) {
      _updateHeight(replacement);
      _stealParentAndDeScope(node, replacement, searchFunc);
      _rebalance(replacement, comparator: comparator, updateRoot: _updateRoot);
    } else if (hasParent) {
      // In case replacement is null, we mark the branch in parent as null
      _markNullInParent(node, parent, searchFunc);
    } else {
      /// This means this is the root value as it has no replacement and
      /// no parent either
      _updateRoot(null);
    }

    if (hasParent) {
      _overwriteLowHigh(value, parent.value);
      _updateHeight(parent);
      _rebalance(parent, comparator: comparator, updateRoot: _updateRoot);
    }

    return true;
  }

  /// Extracts the replacement of a deleted node from its subtree.
  ///
  /// If [highestOnLeft] is `true`, then the largest node on the left subtree
  /// of the [nodeToReplace] is extracted. Otherwise, the smallest node in
  /// right subtree is extracted.
  ///
  /// This function ensures the `parent` node of the extracted node is
  /// after the extraction.
  ///
  /// Returns `null` if the first node of either subtrees is `null`.
  _AvlNode<T>? _extractReplacement(
    _AvlNode<T> nodeToReplace, {
    required bool highestOnLeft,
  }) {
    final start = highestOnLeft ? nodeToReplace.left : nodeToReplace.right;

    /// If the starting point is null, we return null and allow the `remove`
    /// function to update parent accordingly
    if (start == null) return null;

    var replacement = start;
    final nodesToUpdateHeight = <_AvlNode<T>>[];

    // Walk the nodes iteratively
    while (true) {
      final _AvlNode(:left, :right) = replacement;

      /// If searching on left, we need to get the highest value on the left
      /// and lowest when searching right
      final next = highestOnLeft ? right : left;

      /// We found our value.
      if (next == null) break;
      nodesToUpdateHeight.add(replacement);
      replacement = next;
    }

    final _AvlNode(:left, :right, :parent) = replacement;

    /// We only update the `replacement` 's parent only if the node being
    /// removed is the parent of the replacement. Thus, we need to update
    /// height and set one of its children in its place, in that,
    ///   - The highest value on the left will only have a single child on the
    ///     left or null
    ///   - The lowest value on the right will only have a single child on the
    ///     right or null
    if (parent != null && comparator(nodeToReplace.value, parent.value) != 0) {
      if (highestOnLeft) {
        parent.right = left;
      } else {
        parent.left = right;
      }

      /// We update the parent's height first to immediately tee it up for
      /// any rebalancing we may need to do and remove it for any balancing
      /// that may be required of us
      nodesToUpdateHeight.removeLast();
      _updateHeight(parent);

      /// We can safely rebalance this node without affecting the node we
      /// are removing. Why?
      ///
      /// The parent is already balanced and any rotations will be isolated
      /// within it or with its subtree.
      _rebalance(parent, comparator: comparator, updateRoot: _updateRoot);

      /// After a successful rebalancing if any, update all heights of the
      /// remaining nodes. We update from last to top. Similar to updating
      /// height along the way as we bubble up our replacement.
      while (nodesToUpdateHeight.isNotEmpty) {
        _updateHeight(nodesToUpdateHeight.removeLast());
      }
    }

    /// Eagerly take the remaining node for value being replaced. If
    /// "originating" from the left, give it right and vice versa.
    if (highestOnLeft) {
      replacement.right = nodeToReplace.right;
    } else {
      replacement.left = nodeToReplace.left;
    }

    /// The caller of this method, that is, [_removeNode] will/should ensure
    /// the height is updated
    return replacement;
  }

  /// Returns the first node that matches the rules of the [uComparator]
  /// provided. May return null if not found.
  _AvlNode<T>? _matchFirst(_AvlNode<T>? node, UnaryCompare<T> uComparator) {
    if (node == null) return null;
    final _AvlNode<T>(:value, :left, :right) = node;

    final comparison = uComparator(value);
    if (comparison == 0) return node;

    return comparison < 0
        ? _matchFirst(left, uComparator)
        : _matchFirst(right, uComparator);
  }

  void _stealParentAndDeScope(
    _AvlNode<T> donor,
    _AvlNode<T> thief,
    BinaryCompare<T, T> compareFunc,
  ) {
    final stolenParent = donor.parent;

    thief.parent = stolenParent;

    if (stolenParent == null) return _updateRoot(thief);

    if (compareFunc(thief.value, stolenParent.value) > 0) {
      stolenParent.right = thief;
    } else {
      stolenParent.left = thief;
    }

    donor.parent = null;
    donor.left = null;
    donor.right = null;
  }

  /// Marks the position of [node] `null` only if the [parent] is not `null`.
  void _markNullInParent(
    _AvlNode<T> node,
    _AvlNode<T>? parent,
    BinaryCompare<T, T> compareFunc,
  ) {
    if (parent == null) return;

    if (compareFunc(node.value, parent.value) < 0) {
      parent.left = null;
    } else {
      parent.right = null;
    }
  }
}

/// A node within a [AvlTree].
class _AvlNode<T> implements PrintableNode {
  _AvlNode(this.value, {this.parent, this.left, this.right});

  /// Creates an [_AvlNode] with [value] as root and [left] as its left child
  /// and [right] as its right child.
  ///
  /// Automatically updates the [left] and [right] to point to the node created
  /// as their parent. The created node's [height] and [count] are also updated.
  factory _AvlNode.of(
    T value, {
    required _AvlNode<T>? left,
    required _AvlNode<T>? right,
  }) {
    final node = _AvlNode(value, left: left, right: right);
    left?.parent = node;
    right?.parent = node;

    _updateHeight(node);
    return node;
  }

  final T value;

  _AvlNode<T>? parent;
  _AvlNode<T>? left;
  _AvlNode<T>? right;

  /// The longest path to a leaf node
  int height = 0;

  /// Number of [_AvlNode] that are children of this node, including itself.
  int count = 1; // The current leaf node

  bool get isRoot => parent == null;

  @override
  bool get isLeaf => !hasLeft && !hasRight;

  bool get hasLeft => left != null;

  bool get hasRight => right != null;

  @override
  String get printableValue => toString();

  @override
  List<PrintableNode> get children => [
        if (hasLeft) left!,
        if (hasRight) right!,
      ];

  @override
  String toString() => '$value';
}
