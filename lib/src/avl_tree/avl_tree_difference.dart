part of 'avl_tree.dart';

/// Returns the difference of 2 [AvlTree]s, that is, elements in the
/// [firstTree] not present in the [secondTree].
AvlTree<T> avlDifference<T>(AvlTree<T> firstTree, AvlTree<T> secondTree) {
  final AvlTree(:_root, :comparator) = firstTree;
  return AvlTree._(
    _difference(_root, secondTree._root, comparator),
    comparator,
  );
}

/// Performs the actual set difference exposed by [avlDifference].
_AvlNode<T>? _difference<T>(
  _AvlNode<T>? firstNode,
  _AvlNode<T>? secondNode,
  BinaryCompare<T, T> comparator,
) {
  if (firstNode == null) {
    return null;
  } else if (secondNode == null) {
    return firstNode;
  }

  final _AvlNode(left: lSecond, value: secondVal, right: rSecond) = secondNode;

  /// Split the first node at the key to get rid of [secondVal] that is common.
  ///
  /// This is a coin-toss operation, if (not) present, repeat the operation with
  /// the two sub-branches of [firstNode] & [secondNode] since the split will
  /// give potentially equal sub-branches!
  final (lFirst, _, rFirst) = _split(firstNode, secondVal, comparator);

  /// Immediately decompose the left and right subtree. Ensures, we don't
  /// prematurely join two trees with duplicates!
  ///
  /// Both operations can be parallel based on the paper, but Dart is
  /// single-threaded. Concurrency is an option but would require this
  /// function to be a `Future` (async).
  ///
  /// Perform sequential calls instead.
  final diffLeft = _difference(lFirst, lSecond, comparator);
  final diffRight = _difference(rFirst, rSecond, comparator);

  return _joinWithoutKey(
    left: diffLeft,
    right: diffRight,
    comparator: comparator,
  );
}
