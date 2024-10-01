import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:tree_data_structures/src/avl_tree/avl_tree.dart';

import '../helpers/helpers.dart';

void main() {
  late AvlTree<int> first;
  late AvlTree<int> second;

  setUpAll(() {
    first = initializeTree();
    second = initializeTree();
  });

  tearDown(() {
    first.clear();
    second.clear();
  });

  group('AvlTree difference', () {
    test('Returns all elements in a single tree if one is empty', () {
      final input = {1, 2, 3};
      insertAll(input, tree: first);

      check(avlDifference(first, second).ordered()).deepEquals(input);
    });

    test('Returns the difference between 2 AvlTrees', () {
      insertAll([1, 2, 3], tree: first);
      insertAll([2, 3, 4], tree: second);

      final expected = {1};
      final diff = avlDifference(first, second);

      check(diff.ordered()).deepEquals(expected);
      check(diff.length).equals(expected.length);
    });
  });

  group('AvlTree union', () {
    test('Returns all elements in a single tree if one is empty', () {
      final input = {1, 2, 3};
      insertAll(input, tree: first);

      check(avlUnion(first, second).ordered()).deepEquals(input);
    });

    test('Returns the union of 2 AvlTrees', () {
      final input = [1, 2, 3, 4, 5, 6];

      insertAll(input.take(3), tree: first);
      insertAll(input.skip(3), tree: second);

      final union = avlUnion(first, second);

      check(union.ordered()).deepEquals(input);
      check(union.length).equals(input.length);
    });
  });

  group('AvlTree intersection', () {
    test('Returns an empty tree if a single tree is empty', () {
      insertAll({1, 2, 3}, tree: first);
      check(avlIntersection(first, second).ordered()).isEmpty();
    });

    test('Returns the intersection of 2 AvlTrees', () {
      insertAll([1, 2, 3, 4], tree: first);
      insertAll([3, 4, 5, 6], tree: second);

      final expected = {3, 4};
      final intersection = avlIntersection(first, second);

      check(intersection.ordered()).deepEquals(expected);
      check(intersection.length).equals(expected.length);
    });
  });
}
