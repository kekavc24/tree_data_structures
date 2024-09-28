import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:tree_data_structures/src/avl_tree/avl_tree.dart';

import '../helpers/helpers.dart';

void main() {
  late AvlTree<int> baseTree;
  late AvlTree<int> joinTree;

  setUpAll(() {
    baseTree = initializeTree();
    joinTree = initializeTree();
  });

  tearDown(() {
    baseTree.clear();
    joinTree.clear();
  });

  group('Join with key', () {
    test('Two empty trees at root', () {
      final joined = joinTrees(lower: baseTree, key: 0, upper: joinTree);

      check(joined.length).equals(1);
      check(joined.root).equals(0);
      check(joined.ordered()).deepEquals({0});
    });

    test('adds right node to right subtree of left node and rotates', () {
      insertAll([6, 4, 9, 8, 12], tree: baseTree);
      insertAll([16], tree: joinTree);

      final joined = joinTrees(lower: baseTree, key: 15, upper: joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {9, 6, 4, 8, 15, 12, 16},
      );
    });

    test('adds right node to right subtree of left node with no rotations', () {
      insertAll([6, 4, 2, 9], tree: baseTree);
      insertAll([16], tree: joinTree);

      final joined = joinTrees(lower: baseTree, key: 15, upper: joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {6, 4, 2, 15, 9, 16},
      );
    });

    test('adds right node to right subtree of left node after search', () {
      insertAll([6, 4, 9, 2, 8, 12, 7], tree: baseTree);
      insertAll([16], tree: joinTree);

      final joined = joinTrees(lower: baseTree, key: 15, upper: joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {6, 4, 2, 9, 8, 7, 15, 12, 16},
      );
    });

    test('adds left node to left subtree of right node with no rotations', () {
      insertAll([6], tree: baseTree);
      insertAll([12, 10, 15, 14, 18], tree: joinTree);

      final joined = joinTrees(lower: baseTree, key: 7, upper: joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {12, 7, 6, 10, 15, 14, 18},
      );
    });

    test('adds left node to left subtree of right node and rotates', () {
      insertAll([6], tree: baseTree);
      insertAll([12, 10, 15, 9], tree: joinTree);

      final joined = joinTrees(lower: baseTree, key: 7, upper: joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {9, 7, 6, 12, 10, 15},
      );
    });

    test('adds left node to left subtree of right node after search', () {
      insertAll([2], tree: baseTree);
      insertAll([12, 10, 15, 8, 17, 11, 9], tree: joinTree);

      final joined = joinTrees(lower: baseTree, key: 3, upper: joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {12, 8, 3, 2, 10, 9, 11, 15, 17},
      );
    });
  });

  group('Join without key', () {
    test('joins 2 tree without a key', () {
      insertAll([10, 6, 16, 2, 12, 9, 18], tree: baseTree);
      insertAll([30, 24, 36, 22, 32, 26, 38], tree: joinTree);

      check(
        joinTrees<int>(lower: baseTree, key: null, upper: joinTree).ordered(
          transversal: Transversal.preOrder,
        ),
      ).deepEquals({18, 10, 6, 2, 9, 16, 12, 30, 24, 22, 26, 36, 32, 38});
    });
  });

  group('Throws Error', () {
    test('throws a join error when values overlap with key', () {
      insertAll([2, 10], tree: baseTree);
      insertAll([7], tree: joinTree);

      check(() => joinTrees(lower: baseTree, key: 8, upper: joinTree))
          .throws<JoinError>()
        ..has((erro) => erro.key, 'key').equals('8')
        ..has((err) => err.lowerBound, 'lowerbound').equals('10')
        ..has((err) => err.upperBound, 'upperbound').equals('7')
        ..has((err) => err.toString(), 'toString').equals(
          'Cannot join 2 overlapping trees.'
          ' The key "8" must be greater than "10" and lower than'
          ' "7" based on the comparator provided',
        );
    });

    test(
      'throws a join error when values in two trees overlap without key',
      () {
        insertAll([2, 10], tree: baseTree);
        insertAll([7], tree: joinTree);

        check(() => joinTrees<int>(lower: baseTree, key: null, upper: joinTree))
            .throws<JoinError>()
          ..has((erro) => erro.key, 'key').isNull()
          ..has((err) => err.lowerBound, 'lowerbound').equals('10')
          ..has((err) => err.upperBound, 'upperbound').equals('7')
          ..has((err) => err.toString(), 'toString').equals(
            'Cannot join 2 overlapping trees. '
            'The lowerbound of "10" must be less than the upperbound'
            ' of "7"',
          );
      },
    );
  });
}
