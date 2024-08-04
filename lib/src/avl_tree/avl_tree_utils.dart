part of 'avl_tree.dart';

/// Comparator function that conforms to the [Comparable] interface
typedef BinaryCompare<T, U> = int Function(T thiz, U that);

/// Comparator function that takes in a single value [T] but still conforms
/// to [Comparable].
typedef UnaryCompare<T> = int Function(T value);

/// Evaluates a value and return a [bool]
typedef Predicate<T> = bool Function(T value);

typedef _RootUpdateFunc<T> = void Function(_AvlNode<T>? node);

/// Returns the height of a nullable [_AvlNode]
int _height<T>(_AvlNode<T>? node) => node == null ? 0 : node.height;

/// Returns the count of nodes present at a nullable [_AvlNode]
int _numOfNodes<T>(_AvlNode<T>? node) => node == null ? 0 : node.count;

/// Searches an [AvlTree] for an [_AvlNode] where
/// `[searchFunc(needle, value) == 0]`
///
/// Returns a valid [_AvlNode] if found. Otherwise, `null` if not found or if
/// [start] is `null`.
_AvlNode<T>? _search<T>({
  required _AvlNode<T>? start,
  required T needle,
  required BinaryCompare<T, T> searchFunc,
}) {
  var valInHayStack = start;

  while (valInHayStack != null) {
    final _AvlNode<T>(:left, :right, :value) = valInHayStack;

    final comparison = searchFunc(needle, value);
    if (comparison == 0) break;

    valInHayStack = comparison < 0 ? left : right;
  }

  return valInHayStack;
}

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

/// Visits the nodes via [Transversal.inOrder]
void _inOrder<T>(
  Set<T> accumulator,
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
  Set<T> accumulator,
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
  Set<T> accumulator,
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
  Set<T> accumulator,
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

/// Updates the height of a node.
void _updateHeight<T>(_AvlNode<T>? node) {
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
int _checkBF<T>(_AvlNode<T>? node) {
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
void _rebalance<T>(
  _AvlNode<T> parent, {
  required BinaryCompare<T, T> comparator,
  required _RootUpdateFunc<T>? updateRoot,
}) {
  int balanceFactor = _checkBF(parent);
  if (_isBalanced(balanceFactor)) return;

  if (balanceFactor > 1) {
    _rotateChildRight(
      parent,
      comparator: comparator,
      updateRoot: updateRoot,
    );
  } else {
    _rotateChildLeft(
      parent,
      comparator: comparator,
      updateRoot: updateRoot,
    );
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
void _rotateChildRight<T>(
  _AvlNode<T> node, {
  required BinaryCompare<T, T> comparator,
  required _RootUpdateFunc<T>? updateRoot,
  bool checkRight = true,
}) {
  /// If [checkRight] is true, we need to check if we need to perform
  /// a `LEFT` rotation first if the BF is less than `0`, that is, `-1`.
  if (checkRight) {
    final _AvlNode<T>(:left) = node;

    // Means we have to perform a left rotation first
    if (left != null && _checkBF(left) < 0) {
      _rotateChildLeft(
        left,
        comparator: comparator,
        updateRoot: updateRoot,
        checkLeft: false,
      );
    }
  }

  final _AvlNode<T>(:left) = node;

  final temp = left!.right;
  node.left = temp;
  left.right = node;

  // The rotated node will become this node's parent
  if (temp != null) {
    _updateParent(
      node: left,
      updatedParent: temp,
      comparator: comparator,
      updateRoot: updateRoot,
    );
  }
  _updateParent(
    node: node,
    updatedParent: left,
    comparator: comparator,
    updateRoot: updateRoot,
  );

  _updateHeight(node);
  _updateHeight(left);
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
void _rotateChildLeft<T>(
  _AvlNode<T> node, {
  required BinaryCompare<T, T> comparator,
  required _RootUpdateFunc<T>? updateRoot,
  bool checkLeft = true,
}) {
  /// If [checkLeft] is false, we need to check if we need to perform
  /// a `RIGHT` rotation first if the BF is greater than `0`, that is, `1`.
  if (checkLeft) {
    final _AvlNode<T>(:right) = node;

    // Perform right rotation first
    if (right != null && _checkBF(right) > 0) {
      _rotateChildRight(
        right,
        comparator: comparator,
        updateRoot: updateRoot,
        checkRight: false,
      );
    }
  }

  // Destructure again just to be safe whether we rotated right or not.
  final _AvlNode<T>(:right) = node;

  final temp = right!.left;
  right.left = node;
  node.right = temp;

  // The rotated node will become this node's parent
  if (temp != null) {
    _updateParent(
      node: right,
      updatedParent: temp,
      comparator: comparator,
      updateRoot: updateRoot,
    );
  }
  _updateParent(
    node: node,
    updatedParent: right,
    comparator: comparator,
    updateRoot: updateRoot,
  );

  _updateHeight(node);
  _updateHeight(right);
}

/// Swaps the parent of two nodes.
///
/// If the [donor] node has no parent, the [receiver] is made the root node.
void _updateParent<T>({
  required _AvlNode<T> node,
  required _AvlNode<T> updatedParent,
  required BinaryCompare<T, T> comparator,
  required _RootUpdateFunc<T>? updateRoot,
}) {
  final tempParent = node.parent;

  node.parent = updatedParent;
  updatedParent.parent = tempParent;

  if (tempParent == null) {
    if (updateRoot != null) updateRoot(updatedParent);
    return;
  }

  if (comparator(tempParent.value, updatedParent.value) < 0) {
    tempParent.right = updatedParent;
  } else {
    tempParent.left = updatedParent;
  }
}

/// Returns the parent of the [node] at the root (a node with no parent) or
/// [node] if it is the root value.
_AvlNode<T> _nodeAtRoot<T>(_AvlNode<T> node) {
  var current = node;

  while (true) {
    final _AvlNode<T>(:parent) = current;
    if (parent == null) break;

    current = parent;
  }

  return current;
}
