import 'package:tree_data_structures/src/avl_tree/avl_tree.dart';

/// Inserts all [values] into the [tree]
void insertAll(List<int> values, {required AvlTree<int> tree}) {
  for (final value in values) {
    tree.insert(value);
  }
}
