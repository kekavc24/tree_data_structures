import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:tree_data_structures/src/cheeky_avl_tree.dart';

void main() {
  late CheekyAvlTree<int> cheekyAvlTree;
  final defaultInput = [1, 2, 3];

  setUpAll(
    () => cheekyAvlTree = CheekyAvlTree(
      comparator: (thiz, that) => thiz.compareTo(that),
    ),
  );

  tearDown(() => cheekyAvlTree.clear());

  void insertAll(List<int> values) {
    for (final value in values) {
      cheekyAvlTree.insert(value);
    }
  }

  group('Basic Functionality', () {
    test('Inserts values', () {
      insertAll(defaultInput);

      check(cheekyAvlTree.ordered()).deepEquals(defaultInput);
    });

    test('Removes value', () {
      insertAll(defaultInput);

      cheekyAvlTree.remove(3);
      check(cheekyAvlTree.ordered()).deepEquals([1, 2]);
    });

    test('Returns first match', () {
      insertAll(defaultInput); // Only has 1, 2, 3

      // All values are less than or equal to 3
      check(
        cheekyAvlTree.firstWhere((value) {
          if (value < 3) return 0;
          return 0.compareTo(value); // Look for value less than 3
        }),
      ).isNotNull();

      // Has no value greater than 3
      check(
        cheekyAvlTree.firstWhere((value) {
          if (value > 3) return 0;
          return 4.compareTo(value); // Look for value greater than 3
        }),
      ).isNull();
    });

    test('Contains value', () {
      insertAll(defaultInput);

      check(cheekyAvlTree.contains(2)).isTrue();
      check(cheekyAvlTree.contains(10)).isFalse();
    });

    test('Removes first match', () {
      insertAll(defaultInput);

      // No operation
      check(
        cheekyAvlTree.removeFirstWhere(
          (value) {
            if (value == 0) return 0;
            return 0.compareTo(value);
          },
        ),
      ).equals((false, null));

      // Removes one in balanced AvlTree
      check(
        cheekyAvlTree.removeFirstWhere(
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

      check(cheekyAvlTree.ordered()).deepEquals(defaultInput);
    });

    test('Depth-first preorder', () {
      insertAll(defaultInput);

      check(
        cheekyAvlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([2, 1, 3]);
    });

    test('Depth-first postorder', () {
      insertAll(defaultInput);

      check(
        cheekyAvlTree.ordered(transversal: Transversal.postOrder),
      ).deepEquals([1, 3, 2]);
    });

    test('Breadth first', () {
      insertAll(defaultInput);

      check(
        cheekyAvlTree.ordered(transversal: Transversal.breadthFirst),
      ).deepEquals([2, 1, 3]);
    });

    test('Filters elements', () {
      insertAll([...defaultInput, 8, 9, 10]);

      // Return only even
      check(
        cheekyAvlTree.ordered(
          filter: (value) => value % 2 == 0,
        ),
      ).deepEquals([2, 8, 10]);
    });
  });

  group('Performs rotations', () {
    test('when left rotation is required', () {
      insertAll(defaultInput);

      check(
        cheekyAvlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([2, 1, 3]);
    });

    test('when right rotation is required', () {
      insertAll([0, -1, -2]);

      check(
        cheekyAvlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([-1, -2, 0]);
    });

    test('when left-right rotation is required', () {
      insertAll([5, 3, 4]);

      check(
        cheekyAvlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([4, 3, 5]);
    });

    test('when right-left rotation is required', () {
      insertAll([5, 8, 7]);

      check(
        cheekyAvlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([7, 5, 8]);
    });

    test('when an element is deleted', () {
      insertAll([6, 4, 9, 1, 5]);

      cheekyAvlTree.remove(9);

      check(
        cheekyAvlTree.ordered(transversal: Transversal.preOrder),
      ).deepEquals([4, 1, 6, 5]);
    });
  });
}
