part of 'avl_tree.dart';

final class JoinError extends Error {
  JoinError(this.key, this.lowerBound, this.upperBound);

  final String key;

  final String lowerBound;

  final String upperBound;

  @override
  String toString() {
    return 'Cannot join 2 overlapping trees.'
        'The key "$key" must be greater than "$lowerBound" and lower than'
        ' "$upperBound" based on the comparator provided';
  }
}

/// Performs a `join` operation on 2 sorted trees (sets), that is `AvlTree`s
/// [lower] and [upper] resulting in an entirely new `AvlTree`.
///
/// If:
///   - Height of [lower] is greater than height of [upper] + 1 then [upper]
///     joins [lower] in the `right-most` child whose height is less than or
///     equal to height of [upper] + 1.
///   - Height of [upper] is greater than height of [lower] + 1 then [lower]
///     joins [upper] in the `left-most` child whose height is less than or
///     equal to height of [lower] + 1.
///   - None of the above are satisfied, a new [AvlTree] is formed by joining
///     [lower] and [upper] with [key] as the root.
///
/// It is imperative that values in [lower] and [upper] do not overlap with the
/// key such that, `highest value` in [lower] `<` [key] `&&` `lowest value` in
/// [upper] `>` than [key].
///
/// Additionally, this function never checks that both [lower] and [upper]
/// share the same `comparator` [BinaryCompare]. It picks the `comparator`
/// from [lower].
///
/// The caller of this method must ensure that both these comparator are the
/// same. This method will not confirm that.
AvlTree<T> joinTrees<T>(AvlTree<T> lower, T key, AvlTree<T> upper) {
  final comparator = lower.comparator;

  // No overlaps for joins!
  _throwOnOverlap(
    lowerBound: lower.highest,
    upperBound: upper.lowest,
    comparator: comparator,
    key: key,
  );

  return AvlTree._(
    _join(
      left: lower._root,
      key: key,
      right: upper._root,
      comparator: comparator,
    ),
    comparator,
  );
}

/// Performs the actual join operation exposed by [joinTrees].
_AvlNode<T> _join<T>({
  required _AvlNode<T>? left,
  required T key,
  required _AvlNode<T>? right,
  required BinaryCompare<T, T> comparator,
}) {
  final hLeft = _height(left);
  final hRight = _height(right);

  /// If the size of the left subtree is greater than the right if we are to
  /// add a new node with root `k`, add it to the right of [left] and
  /// perform a rotation if needed.
  if (left != null && hLeft > (hRight + 1)) {
    return _joinRight(
      left: left,
      key: key,
      right: right,
      comparator: comparator,
    );
  } else if (right != null && hRight > (hLeft + 1)) {
    /// If the size of the right subtree is greater than the left if we are to
    /// add a new node with root `k` then add it on left of the [right] and
    /// perform rotation if needed.
    return _joinLeft(
      left: left,
      key: key,
      right: right,
      comparator: comparator,
    );
  }

  /// If above conditions are not satisfied, we can safely just create a new
  /// node with `k` as the root
  return _AvlNode.of(key, left: left, right: right);
}

/// Recursively looks for a `right` child in the [left] subtree whose height
/// is less than height of [right] `+ 1` and joins [right] to [left] at that
/// node.
///
/// Symmetric to [_joinLeft].
_AvlNode<T> _joinRight<T>({
  required _AvlNode<T> left,
  required T key,
  required _AvlNode<T>? right,
  required BinaryCompare<T, T> comparator,
}) {
  final _AvlNode<T>(left: lChild, value: keyPrime, right: rChild) = left;

  /// This is a fine-grained join on the left child via its `right` subtree.
  ///
  /// The [key] is always greater than any value in [left].
  ///
  /// Splitting the [left] child allows us to cherry-pick its `right child` and
  /// add it to a new node.
  ///
  /// The new node becomes its replacement, that is, `"join right"`, [right]
  /// joins the tree at the [rChild] using a [key] as the root such that:
  ///
  ///      A
  ///     / \     via key, `D` with [right], `E`
  ///    B   C
  ///
  ///               eventually becomes
  ///
  ///                    A
  ///                   / \
  ///                  B   D
  ///                     / \
  ///                    C   E
  ///
  /// Thus, the sorted nature of the `AvlTree` is respected when transversed
  /// `in-order`.
  if (_height(rChild) <= (_height(right) + 1)) {
    final joinedRight = _AvlNode.of(key, left: rChild, right: right);
    final fullJoin = _AvlNode.of(keyPrime, left: lChild, right: joinedRight);

    /// This condition attempts to counter-balance the new `joinedRight` being
    /// joined to the `lChild` via the existing root value as shown.
    ///
    ///       A
    ///      / \     via key, `F` with [right], `G`
    ///     B   C
    ///        / \
    ///       D   E
    ///
    ///   Results in:
    ///
    ///               A
    ///              / \
    ///             B   F    (height of `F` > height of `B` + 1)
    ///                / \
    ///               C   G
    ///              / \
    ///             D   E
    ///
    /// We attempt to perfom an `undo` operation to a rotation
    /// (balancing effect) that never happened but was `implicitly` done when
    /// joining the two nodes, that is, `C` and `G` via `F`.
    ///
    /// Rotating `C` back to `F` puts the tree in an imbalanced state that
    /// can either be fixed at node `A` or `C`. Allowing the node to be fully
    /// balanced if we go for it at node `A`. That is:
    ///
    /// Rotate `C` right:
    ///
    ///                 A
    ///                / \
    ///               B   C
    ///                  / \
    ///                 D   F
    ///                    / \
    ///                   E   G
    ///
    /// Rotate `C` left:
    ///
    ///               ------ C -----
    ///               |            |
    ///               A            F
    ///              / \          / \
    ///             B   D        E   G
    if (_height(joinedRight) > (_height(lChild) + 1)) {
      _rotateChildRight(joinedRight, comparator: comparator, updateRoot: null);
      _rotateChildLeft(fullJoin, comparator: comparator, updateRoot: null);
    }

    return _nodeAtRoot(fullJoin);
  }

  /// We recursively check the [rChild] for a node on the right that has
  /// a `height` < `height` of [right] + 1
  final rejoinedRight = _joinRight(
    left: rChild!,
    key: key,
    right: right,
    comparator: comparator,
  );

  final fullRejoin = _AvlNode.of(keyPrime, left: lChild, right: rejoinedRight);

  /// The [rejoinedRight] node is fully balanced. Thus, we need to perfom a
  /// single left rotation to ensure the [fullRejoin] will always remain
  /// balanced and not heavy on the newly added node.
  ///
  /// The `left` branch of [fullRejoin] will have no effect once rotation
  /// occurs as the `left` branch of [rejoinedRight] maintains the AvlTree
  /// rules such that:
  ///
  ///
  ///                 A
  ///                / \
  ///               B   C
  ///                  / \
  ///                 D   F
  ///                    / \
  ///                   E   G
  ///
  /// Rotate `C` left:
  ///
  ///               ------ C -----
  ///               |            |
  ///               A            F
  ///              / \          / \
  ///             B   D        E   G
  ///
  /// The function will never allow the `left` child to be heavier than the
  /// `right` child as that condition will always fail and cause a recursive
  /// call in an attempt to avoid it.
  ///
  /// This condition corrects any imbalance.
  if (_height(rejoinedRight) > (_height(lChild) + 1)) {
    _rotateChildLeft(fullRejoin, comparator: comparator, updateRoot: null);
  }

  return _nodeAtRoot(fullRejoin);
}

/// Recursively looks for a `left` child in the [right] subtree whose height
/// is less than height of [left] `+ 1` and joins [left] to [right] at that
/// node.
///
/// Symmetric to [_joinRight].
_AvlNode<T> _joinLeft<T>({
  required _AvlNode<T>? left,
  required T key,
  required _AvlNode<T> right,
  required BinaryCompare<T, T> comparator,
}) {
  final _AvlNode<T>(left: lChild, value: keyPrime, right: rChild) = right;

  /// This is a fine-grained join on the right child via its `left` subtree.
  ///
  /// The [key] is always less than any value in [right].
  ///
  /// Splitting the [right] child allows us to cherry-pick its `left child` and
  /// add it to a new node.
  ///
  /// The new node becomes its replacement, that is, `"join left"`, [left]
  /// joins the tree at the [lChild] using a [key] as the root such that:
  ///
  ///      C
  ///     / \
  ///    D   F       via key, `B` with [left], `A`
  ///       / \
  ///      E   G
  ///
  ///
  ///                   eventually becomes
  ///
  ///               ------ C -----
  ///               |            |
  ///               B            F
  ///              / \          / \
  ///             A   D        E   G
  if (_height(lChild) <= (_height(left) + 1)) {
    final joinedLeft = _AvlNode.of(key, left: left, right: lChild);
    final fullJoin = _AvlNode.of(keyPrime, left: joinedLeft, right: rChild);

    /// This condition attempts to counter-balance the new `joinedLeft` being
    /// joined to the `rChild` via the existing root as shown,
    ///
    ///           A
    ///          / \
    ///         B   C       via key, `E` with [left], `F`
    ///        /
    ///       D
    ///
    ///   Results in:
    ///
    ///                         A
    ///                        / \
    ///                      E    C
    ///                     / \
    ///                    F   B
    ///                       /
    ///                      D
    ///
    /// We attempt to perfom an `undo` operation to a rotation
    /// (balancing effect) that never happened but was `implicitly` done when
    /// joining the two nodes, that is, `B` and `F` via `E`.
    ///
    /// Rotating `B` back to `E` puts the tree in an imbalanced state that
    /// can either be fixed at node `A` or `B`. Allowing the node to be fully
    /// balanced if we go for it at node `A`. That is:
    ///
    /// Rotate `B` left, which is a `right-left` rotation on `D`:
    ///
    ///                      A
    ///                     / \
    ///                    D   C
    ///                   / \
    ///                 E    B
    ///                /
    ///               F
    ///
    /// Rotate `D` left:
    ///
    ///               ------ D -----
    ///               |            |
    ///               E            A
    ///              /            / \
    ///             F            B   C
    if (_height(joinedLeft) > (_height(rChild) + 1)) {
      _rotateChildLeft(joinedLeft, comparator: comparator, updateRoot: null);
      _rotateChildRight(fullJoin, comparator: comparator, updateRoot: null);
    }

    return _nodeAtRoot(fullJoin);
  }

  /// We recursively check the [lChild] for a node on the right that has
  /// a `height` < `height` of [left] + 1
  final rejoinedLeft = _joinLeft(
    left: left,
    key: key,
    right: lChild!,
    comparator: comparator,
  );

  final fullRejoin = _AvlNode.of(keyPrime, left: rejoinedLeft, right: rChild);

  /// The [rejoinedLeft] node is fully balanced. Thus, we need to perfom a
  /// single right rotation to ensure the [fullRejoin] will always remain
  /// balanced and not heavy on the newly added node.
  ///
  /// The `right` branch of [fullRejoin] will have no effect once rotation
  /// occurs as the `right` branch of [rejoinedRight] becomes its left
  /// branch maintains the AvlTree rules.
  ///
  /// The function will never allow the `left` child to be heavier than the
  /// `left` child of [right] as that condition will always fail and cause a
  /// recursive call in an attempt to avoid it.
  if (_height(rejoinedLeft) > (_height(rChild) + 1)) {
    _rotateChildRight(fullRejoin, comparator: comparator, updateRoot: null);
  }

  return _nodeAtRoot(fullRejoin);
}
