part of 'avl_tree.dart';

/// Returns the union of 2 [AvlTree], that is, all elements present in the
/// [firstTree] and [secondTree] ensuring no duplicates are present.
AvlTree<T> avlUnion<T>(AvlTree<T> firstTree, AvlTree<T> secondTree) {
  final AvlTree(:_root, :comparator) = firstTree;
  return AvlTree._(_union(_root, secondTree._root, comparator), comparator);
}

_AvlNode<T>? _union<T>(
  _AvlNode<T>? firstNode,
  _AvlNode<T>? secondNode,
  BinaryCompare<T, T> comparator,
) {
  if (firstNode == null) {
    return secondNode;
  } else if (secondNode == null) {
    return firstNode;
  }

  final _AvlNode(left: lSecond, value: secondVal, right: rSecond) = secondNode;

  /// Split the first node at the key.
  ///
  /// Essentially, we try to recursively get rid of the common element
  /// (`secondVal`) via [split] using key (gets rid of the key if present) then
  /// join them back via the said element whether present or not.
  final (lFirst, _, rFirst) = _split(firstNode, secondVal, comparator);

  /// Immediately decompose the left and right subtree. Ensures, we don't
  /// prematurely join two trees with duplicates!
  ///
  /// Both operations can be parallel based on the paper, but Dart is
  /// single-threaded. Concurrency is an option but would require this
  /// function to be a `Future` (async).
  ///
  /// Perform sequential calls instead.
  final unionLeft = _union(lFirst, lSecond, comparator);
  final unionRight = _union(rFirst, rSecond, comparator);

  return _join(
    left: unionLeft,
    key: secondVal,
    right: unionRight,
    comparator: comparator,
  );
}
