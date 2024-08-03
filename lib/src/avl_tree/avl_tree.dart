import 'dart:math';

import 'package:tree_data_structures/src/printable_tree.dart';

/// Comparator function that conforms to the [Comparable] interface
typedef BinaryCompare<T, U> = int Function(T thiz, U that);

/// Comparator function that takes in a single value [T] but still conforms
/// to [Comparable].
typedef UnaryCompare<T> = int Function(T value);

/// Evaluates a value and return a [bool]
typedef Predicate<T> = bool Function(T value);

/// Depth first tranversal techniques
enum Transversal {
  /// Visits root -> left -> right
  preOrder,

  /// Visits left -> root -> right. Always returns a sorted output based on
  /// an ordering
  inOrder,

  /// Visits left -> right -> root
  postOrder,

  /// Visits all nodes at a level before proceeding
  breadthFirst,
}

/// A basic implementation of an `AVL Tree` which is a self-balancing binary
/// search tree but with a cheeky trick.
///
/// See https://en.wikipedia.org/wiki/AVL_tree
class AvlTree<T> implements PrintableTree {
  /// [comparator] - used to compare elements before insertion. The function
  /// is shadow definition of [Comparable].
  AvlTree({required this.comparator});

  ///
  final BinaryCompare<T, T> comparator;

  /// Node at the root of the tree
  _AvlNode<T>? _root;

  /// Returns the value at the root of the tree. Returns null if the tree is
  /// empty.
  T? get root => _root?.value;

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

  /// Removes all objects present in this tree.
  void clear() => _root = null;

  /// Swaps an [AvlTree] with another without checking the [comparator]'s
  /// rules thus its cheekiness.
  ///
  /// It should be noted this method only swaps the reference of the [root]
  /// and [length]. The [comparator] remains unchanged. Ensure that both
  /// this tree and the [other] tree share the same [comparator] rules before
  /// swapping.
  void swapWith(AvlTree<T> other) => _root = other._root;

  /// Adds an value to the tree
  void insert(T value) {
    final newNode = _AvlNode(value);

    if (isEmpty) {
      _root = newNode;
      return;
    }

    _addNode(_root!, newNode);
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
    return _search(_root, element, searchFunc ?? comparator) != null;
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
    final node = _search(_root, element, removeFunc);
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
  List<T> ordered({
    Transversal transversal = Transversal.inOrder,
    Predicate<T>? filter,
  }) {
    final ordered = <T>[];

    if (_root == null) return ordered;

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
      _addNode(target, child);
    } else {
      child.parent = parent;
    }

    _updateHeight(parent);

    /// Insertion may cause the tree to be unbalanced. Attempt to rebalance if
    /// unbalanced
    _rebalance(parent);
    return true;
  }

  /// Removes a node from the tree based on a [searchFunc].
  ///
  /// Returns `true` only if `[searchFunc(value, other) == 0]`. Otherwise,
  /// `false`.
  bool _removeNode(_AvlNode<T>? node, BinaryCompare<T, T> searchFunc) {
    if (node == null) return false;

    final _AvlNode<T>(:parent, :left, :right) = node;

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
      _rebalance(replacement);
    } else if (hasParent) {
      // In case replacement is null, we mark parent as null
      _markNullInParent(node, parent, searchFunc);
    }

    if (hasParent) {
      _updateHeight(parent);
      _rebalance(parent);
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

    // Walk the nodes iteratively
    while (true) {
      final _AvlNode(:left, :right) = replacement;

      /// If searching on left, we need to get the highest value on the left
      /// and lowest when searching right
      final next = highestOnLeft ? right : left;

      /// We found our value.
      if (next == null) break;
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

      _updateHeight(parent);

      /// We can safely rebalance this node without affecting the node we
      /// are removing. Why?
      ///
      /// The parent is already balanced and any rotations will be isolated
      /// within it or with its subtree.
      _rebalance(parent);
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

  /// Updates the height of a node.
  void _updateHeight(_AvlNode<T>? node) {
    if (node == null) return;
    final _AvlNode<T>(:left, :right, :isLeaf) = node;

    if (isLeaf) {
      node.height = 0;
      node.count = 1;
      return;
    }

    node.height = max(_height(left), _height(right)) + 1;
    node.count = _numOfNodes(left) + _numOfNodes(right) + 1;
  }

  /// Checks the balance factor of a node
  int _checkBF(_AvlNode<T>? node) {
    if (node == null) return 0;

    final _AvlNode<T>(:hasLeft, :hasRight, :left, :right) = node;
    final hLeft = hasLeft ? _height(left) + 1 : 0;
    final hRight = hasRight ? _height(right) + 1 : 0;
    return hLeft - hRight;
  }

  /// Returns whether a node is balanced.
  ///
  /// A node is balanced if its balance factor is `-1`, `0` or `1`.
  bool _isBalanced(int balanceFactor) {
    return switch (balanceFactor) {
      0 || -1 || 1 => true,
      _ => false,
    };
  }

  /// Rebalances a node if unbalanced.
  void _rebalance(_AvlNode<T> parent) {
    int balanceFactor = _checkBF(parent);
    if (_isBalanced(balanceFactor)) return;

    if (balanceFactor > 1) {
      _rotateChildRight(parent);
    } else {
      _rotateChildLeft(parent);
    }
  }

  /// Rotates the child on the left and places it at its parent's position
  /// and its parent on the right of the child.
  ///
  /// If the child is balanced with a BF of `0` or `1` i.e share same sign then
  /// a single `RIGHT` rotation is perfomed
  ///
  /// ```text
  ///           A
  ///         /               B
  ///       B       =>      /  \
  ///     /               C     A
  ///   C
  /// ```
  ///
  /// If the child is balanced with a BF of `-1` then a `LEFT-RIGHT` rotation
  /// is perfomed
  ///
  /// ```text
  ///
  ///           A                 A
  ///         /                 /             C
  ///       B       =>        C       =>    /  \
  ///        \              /             A     B
  ///         C           B
  /// ```
  void _rotateChildRight(_AvlNode<T> node, {bool ignoreRightCheck = false}) {
    /// If [ignoreRightCheck] is false, we need to check if we need to perform
    /// a `LEFT` rotation first if the BF is less than `0`, that is, `-1`.
    if (!ignoreRightCheck) {
      final _AvlNode<T>(:left) = node;

      // Means we have to perform a left rotation first
      if (left != null && _checkBF(left) < 0) {
        _rotateChildLeft(left, ignoreLeftCheck: true);
      }
    }

    final _AvlNode<T>(:left) = node;

    final temp = left!.right;
    node.left = temp;
    left.right = node;

    // The rotated node will become this node's parent
    if (temp != null) _updateParent(node: left, updatedParent: temp);
    _updateParent(node: node, updatedParent: left);

    _updateHeight(node);
    _updateHeight(left);
    _updateHeight(left.parent);
  }

  /// Rotates the child on the right and places it at its parent's position
  /// and its parent on the left of the child.
  ///
  /// If the child is balanced with a BF of `0` or `1` i.e share same sign then
  /// a single `LEFT` rotation is perfomed
  ///
  /// ```text
  ///   A
  ///    \                  B
  ///     B       =>      /  \
  ///      \            A     C
  ///       C
  /// ```
  ///
  /// If the child is balanced with a BF of `-1` then a `RIGHT-LEFT` rotation
  /// is perfomed
  ///
  /// ```text
  ///   A              A
  ///    \              \                 C
  ///     B       =>     C       =>     /  \
  ///    /                \           A     B
  ///  C                   B
  ///
  /// ```
  void _rotateChildLeft(_AvlNode<T> node, {bool ignoreLeftCheck = false}) {
    /// If [ignoreLeftCheck] is false, we need to check if we need to perform
    /// a `RIGHT` rotation first if the BF is greater than `0`, that is, `1`.
    if (!ignoreLeftCheck) {
      final _AvlNode<T>(:right) = node;

      // Perform right rotation first
      if (right != null && _checkBF(right) > 0) {
        _rotateChildRight(right, ignoreRightCheck: true);
      }
    }

    // Destructure again just to be safe whether we rotated right or not.
    final _AvlNode<T>(:right) = node;

    final temp = right!.left;
    right.left = node;
    node.right = temp;

    // The rotated node will become this node's parent
    if (temp != null) _updateParent(node: right, updatedParent: temp);
    _updateParent(node: node, updatedParent: right);

    _updateHeight(node);
    _updateHeight(right);
    _updateHeight(right.parent); // Parent of rotated node
  }

  /// Swaps the parent of two nodes.
  ///
  /// If the [donor] node has no parent, the [receiver] is made the root node.
  void _updateParent({
    required _AvlNode<T> node,
    required _AvlNode<T> updatedParent,
  }) {
    final tempParent = node.parent;

    node.parent = updatedParent;
    updatedParent.parent = tempParent;

    if (tempParent == null) {
      _root = updatedParent;
      return;
    }

    if (comparator(tempParent.value, updatedParent.value) < 0) {
      tempParent.right = updatedParent;
    } else {
      tempParent.left = updatedParent;
    }
  }

  void _stealParentAndDeScope(
    _AvlNode<T> donor,
    _AvlNode<T> thief,
    BinaryCompare<T, T> compareFunc,
  ) {
    final stolenParent = donor.parent;

    thief.parent = stolenParent;

    if (stolenParent == null) {
      _root = thief;
      return;
    }

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
  _AvlNode(this.value);

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
  String toString() => '$value';

  @override
  String get printableValue => toString();

  @override
  List<PrintableNode> get children => [
        if (left != null) left!,
        if (right != null) right!,
      ];
}

/// Returns the height of a nullable [_AvlNode]
int _height<T>(_AvlNode<T>? node) => node == null ? 0 : node.height;

/// Returns the count of nodes present at a nullable [_AvlNode]
int _numOfNodes<T>(_AvlNode<T>? node) => node == null ? 0 : node.count;

/// Searches an [AvlTree] for an [_AvlNode] where
/// `[searchFunc(needle, value) == 0]`
///
/// Returns a valid [_AvlNode] if found. Otherwise, `null` if not found or if
/// [start] is `null`.
_AvlNode<T>? _search<T>(
  _AvlNode<T>? start,
  T needle,
  BinaryCompare<T, T> searchFunc,
) {
  var valInHayStack = start;

  while (valInHayStack != null) {
    final _AvlNode<T>(:left, :right, :value) = valInHayStack;

    final comparison = searchFunc(needle, value);
    if (comparison == 0) break;

    valInHayStack = comparison < 0 ? left : right;
  }

  return valInHayStack;
}

/// Visits the nodes via [Transversal.inOrder]
void _inOrder<T>(
  List<T> accumulator,
  _AvlNode<T> parent,
  Predicate<T> filter,
) {
  final _AvlNode(:value, :left, :right) = parent;

  if (left != null) {
    _inOrder(accumulator, left, filter);
  }

  if (filter(value)) accumulator.add(value);

  if (right != null) {
    _inOrder(accumulator, right, filter);
  }
}

/// Visits the nodes via [Transversal.preOrder]
void _preOrder<T>(
  List<T> accumulator,
  _AvlNode<T> parent,
  Predicate<T> filter,
) {
  final _AvlNode(:value, :left, :right) = parent;

  if (filter(value)) accumulator.add(value);

  if (left != null) {
    _preOrder(accumulator, left, filter);
  }

  if (right != null) {
    _preOrder(accumulator, right, filter);
  }
}

/// Visits the nodes via [Transversal.postOrder]
void _postOrder<T>(
  List<T> accumulator,
  _AvlNode<T> parent,
  Predicate<T> filter,
) {
  final _AvlNode(:value, :left, :right) = parent;

  if (left != null) {
    _postOrder(accumulator, left, filter);
  }

  if (right != null) {
    _postOrder(accumulator, right, filter);
  }

  if (filter(value)) accumulator.add(value);
}

/// Visits the node via [Transversal.breadthFirst]
void _breadthFirst<T>(
  List<T> accumulator,
  List<_AvlNode<T>> queue,
  Predicate<T> filter,
) {
  final breadthQueue = List.from(queue);

  while (breadthQueue.isNotEmpty) {
    final _AvlNode<T>(:value, :left, :right) = breadthQueue.removeAt(0);
    if (filter(value)) accumulator.add(value);

    if (left != null) breadthQueue.add(left);
    if (right != null) breadthQueue.add(right);
  }
}
