import 'package:tree_data_structures/src/avl_tree/avl_tree.dart';

/// Initializes an empty tree of type [int].
AvlTree<int> initializeTree() =>
    AvlTree.empty(comparator: (thiz, that) => thiz.compareTo(that));

/// Inserts all [values] into the [tree]
void insertAll(Iterable<int> values, {required AvlTree<int> tree}) {
  for (final value in values) {
    tree.insert(value);
  }
}
