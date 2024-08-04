import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:tree_data_structures/src/avl_tree/avl_tree.dart';

void main() {
  late AvlTree<int> avlTree;
  final defaultInput = [1, 2, 3];

  setUpAll(
    () => avlTree = AvlTree.empty(
      comparator: (thiz, that) => thiz.compareTo(that),
    ),
  );

  tearDown(() => avlTree.clear());

  void insertAll(List<int> values, [AvlTree? tree]) {
    for (final value in values) {
      (tree ?? avlTree).insert(value);
    }
  }

  group('Basic Functionality', () {
    test('Inserts values', () {
      insertAll(defaultInput);

      check(avlTree.ordered()).deepEquals(defaultInput);
    });

    test('Removes only value in tree', () {
      insertAll([1]);

      avlTree.remove(1);
      check(avlTree.isEmpty).isTrue();
    });

    test('Removes value', () {
      insertAll(defaultInput);

      avlTree.remove(3);
      check(avlTree.ordered()).deepEquals([1, 2]);
      check(avlTree.highest).isNotNull().equals(2);
    });

    test('Returns first match', () {
      insertAll(defaultInput); // Only has 1, 2, 3

      // All values are less than or equal to 3
      check(
        avlTree.firstWhere((value) {
          if (value < 3) return 0;
          return 0.compareTo(value); // Look for value less than 3
        }),
      ).isNotNull();

      // Has no value greater than 3
      check(
        avlTree.firstWhere((value) {
          if (value > 3) return 0;
          return 4.compareTo(value); // Look for value greater than 3
        }),
      ).isNull();
    });

    test('Contains value', () {
      insertAll(defaultInput);

      check(avlTree.contains(2)).isTrue();
      check(avlTree.contains(10)).isFalse();
    });

    test('Removes first match', () {
      insertAll(defaultInput);

      // No operation
      check(
        avlTree.removeFirstWhere(
          (value) {
            if (value == 0) return 0;
            return 0.compareTo(value);
          },
        ),
      ).equals((false, null));

      // Removes one in balanced AvlTree
      check(
        avlTree.removeFirstWhere(
          (value) {
            if (value < 2) return 0;
            return 1.compareTo(value);
          },
        ),
      ).equals((true, 1));
    });
  });

  group('Transversal', () {
    test('Depth-first inorder', () {
      insertAll(defaultInput);

      check(avlTree.ordered()).deepEquals(defaultInput);
    });

    test('Depth-first preorder', () {
      insertAll(defaultInput);

      check(
        avlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([2, 1, 3]);
    });

    test('Depth-first postorder', () {
      insertAll(defaultInput);

      check(
        avlTree.ordered(transversal: Transversal.postOrder),
      ).deepEquals([1, 3, 2]);
    });

    test('Breadth first', () {
      insertAll(defaultInput);

      check(
        avlTree.ordered(transversal: Transversal.breadthFirst),
      ).deepEquals([2, 1, 3]);
    });

    test('Filters elements', () {
      insertAll([...defaultInput, 8, 9, 10]);

      // Return only even
      check(
        avlTree.ordered(
          filter: (value) => value % 2 == 0,
        ),
      ).deepEquals([2, 8, 10]);
    });
  });

  group('Performs rotations', () {
    test('when left rotation is required', () {
      insertAll(defaultInput);

      check(
        avlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([2, 1, 3]);
    });

    test('when right rotation is required', () {
      insertAll([0, -1, -2]);

      check(
        avlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([-1, -2, 0]);
    });

    test('when left-right rotation is required', () {
      insertAll([5, 3, 4]);

      check(
        avlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([4, 3, 5]);
    });

    test('when right-left rotation is required', () {
      insertAll([5, 8, 7]);

      check(
        avlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([7, 5, 8]);
    });

    test('when an element is deleted', () {
      insertAll([6, 4, 9, 1, 5]);

      avlTree.remove(9);

      check(
        avlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([4, 1, 6, 5]);
    });
  });

  group('Join', () {
    final joinTree = AvlTree<int>.empty(
      comparator: (thiz, that) => thiz.compareTo(that),
    );

    tearDown(() => joinTree.clear());

    test('Two empty trees at root', () {
      final joined = joinTrees(avlTree, 0, joinTree);

      check(joined.length).equals(1);
      check(joined.root).equals(0);
      check(joined.ordered()).deepEquals({0});
    });

    test('adds right node to right subtree of left node and rotates', () {
      insertAll([6, 4, 9, 8, 12]);
      insertAll([16], joinTree);

      final joined = joinTrees(avlTree, 15, joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {9, 6, 4, 8, 15, 12, 16},
      );
    });

    test('adds right node to right subtree of left node with no rotations', () {
      insertAll([6, 4, 2, 9]);
      insertAll([16], joinTree);

      final joined = joinTrees(avlTree, 15, joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {6, 4, 2, 15, 9, 16},
      );
    });

    test('adds right node to right subtree of left node after search', () {
      insertAll([6, 4, 9, 2, 8, 12, 7]);
      insertAll([16], joinTree);

      final joined = joinTrees(avlTree, 15, joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {6, 4, 2, 9, 8, 7, 15, 12, 16},
      );
    });

    test('adds left node to left subtree of right node with no rotations', () {
      insertAll([6]);
      insertAll([12, 10, 15, 14, 18], joinTree);

      final joined = joinTrees(avlTree, 7, joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {12, 7, 6, 10, 15, 14, 18},
      );
    });

    test('adds left node to left subtree of right node and rotates', () {
      insertAll([6]);
      insertAll([12, 10, 15, 9], joinTree);

      final joined = joinTrees(avlTree, 7, joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {9, 7, 6, 12, 10, 15},
      );
    });

    test('adds left node to left subtree of right node after search', () {
      insertAll([2]);
      insertAll([12, 10, 15, 8, 17, 11, 9], joinTree);

      final joined = joinTrees(avlTree, 3, joinTree);

      check(
        joined.ordered(transversal: Transversal.preOrder),
      ).deepEquals(
        {12, 8, 3, 2, 10, 9, 11, 15, 17},
      );
    });

    test('throws a join error when values overlap', () {
      insertAll([2, 10]);
      insertAll([7], joinTree);

      check(() => joinTrees(avlTree, 8, joinTree)).throws<JoinError>()
        ..has((erro) => erro.key, 'key').equals('8')
        ..has((err) => err.lowerBound, 'lowerbound').equals('10')
        ..has((err) => err.upperBound, 'upperbound').equals('7')
        ..has((err) => err.toString(), 'toString').equals(
          'Cannot join 2 overlapping trees.'
          'The key "8" must be greater than "10" and lower than'
          ' "7" based on the comparator provided',
        );
    });
  });
}
