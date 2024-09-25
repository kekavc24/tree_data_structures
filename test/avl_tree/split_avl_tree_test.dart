import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:tree_data_structures/src/avl_tree/avl_tree.dart';

import '../helpers/avl_tree_helpers.dart';

void main() {
  const key = 5;
  late AvlTree<int> treeToSplit;

  setUpAll(() => treeToSplit = initializeTree());
  tearDown(() => treeToSplit.clear());

  group('Split via key', () {
    test('returns an empty trees if tree is empty', () {
      check(splitTree(treeToSplit, key))
        ..has((record) => record.isPresent, 'isPresent').isFalse()
        ..has((record) => record.left.isEmpty, 'left.isEmpty').isTrue()
        ..has((record) => record.right.isEmpty, 'right.isEmpty').isTrue();
    });

    test('splits a tree when key is present', () {
      insertAll([8, key, 11, 6, 9, 4, 14], tree: treeToSplit);

      final (:left, :isPresent, :right) = splitTree(treeToSplit, key);

      check(left.ordered()).deepEquals({4});
      check(isPresent).isTrue();
      check(right.ordered()).deepEquals({6, 8, 9, 11, 14});
    });

    test('splits a tree when key is absent', () {
      insertAll([8, 6, 11, 7, 9, 4, 14], tree: treeToSplit);

      final (:left, :isPresent, :right) = splitTree(treeToSplit, key);

      check(left.ordered()).deepEquals({4});
      check(isPresent).isFalse();
      check(right.ordered()).deepEquals({6, 7, 8, 9, 11, 14});
    });
  });
}
