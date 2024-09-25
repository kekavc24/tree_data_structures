part of 'avl_tree.dart';

typedef SplitTree<T> = ({AvlTree<T> left, bool isPresent, AvlTree<T> right});
typedef _SplitNode<T> = (_AvlNode<T>? left, bool isPresent, _AvlNode<T>? right);

/// Splits an `AvlTree` [tree] using a [key].
///
/// Returns a [Record] of the [tree] split using the [key] such that:
///   - `left` represents the left subtree of the [key].
///   - `right` represents the right subtree of the [key].
///   - [bool] `isPresent` indicates whether the [key] was found within the
///     tree.
///
///
/// If:
///   1. The [key] is not present in the [tree] then `left` represents the
///      all values along the path less than the [key] and vice versa for the
///      `right`
///   2. The [key] is present then `left` is the left subtree and `right` is
///      the right subtree.
SplitTree<T> splitTree<T>(AvlTree<T> tree, T key) {
  final AvlTree(:comparator, :isEmpty, :_root) = tree;

  if (isEmpty) {
    return (
      left: AvlTree.empty(comparator: comparator),
      isPresent: false,
      right: AvlTree.empty(comparator: comparator),
    );
  }

  final (nodeOnLeft, isPresent, nodeOnRight) = _split(_root, key, comparator);
  return (
    left: AvlTree._(nodeOnLeft, comparator),
    isPresent: isPresent,
    right: AvlTree._(nodeOnRight, comparator),
  );
}

/// Performs the actual split operation exposed by [splitTree].
_SplitNode<T> _split<T>(
  _AvlNode<T>? node,
  T key,
  BinaryCompare<T, T> comparator,
) {
  if (node == null) return (null, false, null);

  final _AvlNode(:left, value: exposedVal, :right) = node;
  final comparison = comparator(key, exposedVal);

  if (comparison == 0) {
    return (left, true, right);
  } else if (comparison < 0) {
    // Follow the left path
    final (lLeftSplit, isPresent, rLeftSplit) = _split(left, key, comparator);

    return (
      lLeftSplit,
      isPresent,
      _join(
        left: rLeftSplit,
        key: exposedVal,
        right: right,
        comparator: comparator,
      ),
    );
  }

  // Follow the right path
  final (lRightSplit, isPresent, rRightSplit) = _split(right, key, comparator);

  return (
    _join(
      left: left,
      key: exposedVal,
      right: lRightSplit,
      comparator: comparator,
    ),
    isPresent,
    rRightSplit,
  );
}
