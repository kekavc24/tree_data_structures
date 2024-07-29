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
class CheekyAvlTree<T> implements PrintableTree {
  /// [comparator] - used to compare elements before insertion. The function
  /// is shadow definition of [Comparable].
  CheekyAvlTree({required this.comparator});

  ///
  final BinaryCompare<T, T> comparator;

  /// Node at the root of the tree
  _AvlNode<T>? _root;

  /// Count of elements
  int _count = 0;

  /// Returns the value at the root of the tree. Returns null if the tree is
  /// empty.
  T? get root => _root?.value;

  /// Returns the number of elements in this collection.
  int get length => _count;

  /// Returns the longest path to a leaf node.
  int get height => _height(_root);

  @override
  bool get isEmpty => _root == null;

  @override
  String get name => 'AvlTree';

  @override
  List<PrintableNode> get rootNodes => [if (!isEmpty) _root!];

  /// Removes all objects present in this tree.
  void clear() {
    _root = null;
    _count = 0;
  }

  /// Swaps an [CheekyAvlTree] with another without checking the [comparator]'s
  /// rules thus its cheekiness.
  ///
  /// It should be noted this method only swaps the reference of the [root]
  /// and [length]. The [comparator] remains unchanged. Ensure that both
  /// this tree and the [other] tree share the same [comparator] rules before
  /// swapping.
  void swapWith(CheekyAvlTree<T> other) {
    _root = other._root;
    _count = other._count;
  }

  /// Adds an value to the tree
  void insert(T value) {
    final newNode = _AvlNode(value);

    if (isEmpty) {
      _root = newNode;
      _count++;
      return;
    }

    if (_addNode(_root!, newNode)) _count++;
  }

  /// Returns the first element that matches the rules of the [uComparator]
  /// provided where `[uComparator(value) == 0]`.
  ///
  /// **Example**
  /// ```dart
  /// final tree = CheekyAvlTree<int>(comparator: (a, b) => a.compareTo(b))
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

    // Prefer left when deleting
    if (left != null) {
      // Get largest on left
      replacement = _deepest(left, checkLeft: false);

      /// Give the current [replacement]'s left child to node on [left] if
      /// we found a node greater than [left] in the subtree.
      if (!replacement.isLeaf &&
          comparator(left.value, replacement.value) != 0) {
        final temp = replacement.left;
        replacement.left = left;

        _addNode(left, temp!);
      }
      replacement.right = right;
      if (right != null) right.parent = replacement;
    } else if (right != null) {
      replacement = _deepest(right, checkLeft: true);

      /// Give the current [replacement]'s left child to node on [right] if
      /// we found a node lesser than [right] in the subtree.
      if (!replacement.isLeaf &&
          comparator(right.value, replacement.value) != 0) {
        final temp = replacement.right;
        replacement.right = right;

        _addNode(right, temp!);
      }
      replacement.left = left;
      if (left != null) left.parent = replacement;
    }

    if (replacement != null) {
      _swapParent(node, replacement);
      _rebalance(replacement);
    } else if (parent != null) {
      _markNullInParent(node, parent, searchFunc);
    }

    if (parent != null) _rebalance(parent);
    _count--;
    return true;
  }

  /// Returns the deepest element on either directions of a [node].
  ///
  /// If [checkLeft] is `true`, the smallest element will be returned.
  /// Otherwise, the largest element will be returned
  _AvlNode<T> _deepest(_AvlNode<T> node, {required bool checkLeft}) {
    final _AvlNode<T>(:left, :right) = node;
    final nodeToCheck = checkLeft ? left : right;
    if (nodeToCheck != null) return _deepest(nodeToCheck, checkLeft: checkLeft);
    return node;
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

  /// Checks the balance factor of a node
  int _checkBF(_AvlNode<T>? node) {
    if (node == null) return 0;
    final _AvlNode<T>(:left, :right) = node;
    final balanceFactor = _heightOfSubtree(left) - _heightOfSubtree(right);
    return balanceFactor;
  }

  /// Calculates the height of a subtree.
  int _heightOfSubtree(_AvlNode<T>? child) {
    if (child == null) return 0; // Not only null, non-existent
    final height = _height(child);
    return height + 1; // Include edge from parent
  }

  /// Returns the longest path from a node to a child that is a leaf.
  int _height(_AvlNode<T>? node) {
    if (node == null) return 0;

    final _AvlNode<T>(:left, :right, :isLeaf) = node;
    if (isLeaf) return 0;

    final height = max(_height(left), _height(right));
    return height + 1;
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
    final parentBF = _checkBF(parent);
    if (_isBalanced(parentBF)) return;

    if (parentBF > 1) {
      _rotateRight(parent);
    } else {
      _rotateLeft(parent);
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
  void _rotateRight(_AvlNode<T> node, {bool ignoreRightCheck = false}) {
    /// If [ignoreRightCheck] is false, we need to check if we need to perform
    /// a `LEFT` rotation first if the BF is less than `0`, that is, `-1`.
    if (!ignoreRightCheck) {
      final _AvlNode<T>(:left) = node;
      final leftBF = _checkBF(left);

      // Means we have to perform a left rotation first
      if (leftBF < 0) {
        _rotateLeft(left!, ignoreLeftCheck: true);
      }
    }

    final _AvlNode<T>(:left) = node;

    final temp = left!.right;
    node.left = temp;
    left.right = node;

    // The rotated node will become this node's parent
    if (temp != null) _swapParent(left, temp);
    _swapParent(node, left);
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
  void _rotateLeft(_AvlNode<T> node, {bool ignoreLeftCheck = false}) {
    /// If [ignoreLeftCheck] is false, we need to check if we need to perform
    /// a `RIGHT` rotation first if the BF is greater than `0`, that is, `1`.
    if (!ignoreLeftCheck) {
      final _AvlNode<T>(:right) = node;
      final rightBF = _checkBF(right);

      // Perform right rotation first
      if (rightBF > 0) {
        _rotateRight(right!, ignoreRightCheck: true);
      }
    }

    // Destructure again just to be safe whether we rotated right or not.
    final _AvlNode<T>(:right) = node;

    final temp = right!.left;
    right.left = node;
    node.right = temp;

    // The rotated node will become this node's parent
    if (temp != null) _swapParent(right, temp);
    _swapParent(node, right);
  }

  /// Swaps the parent of two nodes.
  ///
  /// If the [donor] node has no parent, the [receiver] is made the root node.
  void _swapParent(_AvlNode<T> donor, _AvlNode<T> receiver) {
    final tempParent = donor.parent;

    donor.parent = receiver;
    receiver.parent = tempParent;

    if (tempParent == null) {
      _root = receiver;
      return;
    }

    if (comparator(tempParent.value, receiver.value) < 0) {
      tempParent.right = receiver;
    } else {
      tempParent.left = receiver;
    }
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

/// A node within a [CheekyAvlTree].
class _AvlNode<T> implements PrintableNode {
  _AvlNode(this.value);

  final T value;

  _AvlNode<T>? parent;
  _AvlNode<T>? left;
  _AvlNode<T>? right;

  bool get isRoot => parent == null;

  @override
  bool get isLeaf => left == null && right == null;

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

/// Searches an [CheekyAvlTree] for an [_AvlNode] where
/// `[searchFunc(needle, value) == 0]`
///
/// Returns a valid [_AvlNode] if found. Otherwise, `null` if not found or if
/// [start] is `null`.
_AvlNode<T>? _search<T>(
  _AvlNode<T>? start,
  T needle,
  BinaryCompare<T, T> searchFunc,
) {
  if (start == null) return null;

  final _AvlNode<T>(:left, :right, :value, :isLeaf) = start;

  final comparison = searchFunc(needle, value);
  if (comparison == 0) return start; // Found match

  if (!isLeaf) {
    return _search(comparison < 0 ? left : right, needle, searchFunc);
  }

  return null; // No match & this node has no children
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
