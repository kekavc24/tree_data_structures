part of 'avl_tree.dart';

/// Returns the intersection of 2 [AvlTree], that is, elements present in the
/// [firstTree] and [secondTree].
AvlTree<T> avlIntersection<T>(AvlTree<T> firstTree, AvlTree<T> secondTree) {
  final AvlTree(:_root, :comparator) = firstTree;
  return AvlTree._(
    _intersection(_root, secondTree._root, comparator),
    comparator,
  );
}

/// Performs the actual intersection exposed by [avlIntersection]
_AvlNode<T>? _intersection<T>(
  _AvlNode<T>? firstNode,
  _AvlNode<T>? secondNode,
  BinaryCompare<T, T> comparator,
) {
  if (firstNode == null || secondNode == null) return null;

  final _AvlNode(left: lSecond, value: secondVal, right: rSecond) = secondNode;

  /// Split the first node at the using the key from the second node.
  ///
  /// Unlike union where we don't care if the key was found, we very much need
  /// to know this.
  ///
  /// This enables us to join via a definite key or fall back to joining
  /// without a key for common elements.
  ///
  /// Essentially, we are selecting one tree and walking every non-nullable root
  /// node and checking if it's in the other tree by attempting to split it
  /// at the said node.
  ///
  /// If present, join the via the key. If not, select the largest value in
  /// the two subtrees if present and join them.
  final (lFirst, isPresent, rFirst) = _split(firstNode, secondVal, comparator);

  /// Immediately decompose the left and right subtree. Ensures, we don't
  /// prematurely join two trees with duplicates!
  ///
  /// Both operations can be parallel based on the paper, but Dart is
  /// single-threaded. Concurrency is an option but would require this
  /// function to be a `Future` (async).
  ///
  /// Perform sequential calls instead.
  final intersectLeft = _intersection(lFirst, lSecond, comparator);
  final intersectRight = _intersection(rFirst, rSecond, comparator);

  if (isPresent) {
    return _join(
      left: intersectLeft,
      key: secondVal,
      right: intersectRight,
      comparator: comparator,
    );
  }

  return _joinWithoutKey(
    left: intersectLeft,
    right: intersectRight,
    comparator: comparator,
  );
}
