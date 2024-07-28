/// Represents a basic tree which can be displayed as a string
abstract interface class PrintableTree<T> {
  /// Returns all root nodes for this tree. Ideally, this should be empty if
  /// [count] is `0`
  List<PrintableNode<T>> get rootNodes;

  /// Checks whether this tree has any [PrintableNode]s.
  bool get isEmpty => count == 0;

  /// Returns the number of [PrintableNode] in this tree
  int get count;

  /// Returns the name of this tree
  String get name;
}

/// Represents a node within a [PrintableTree]
abstract interface class PrintableNode<T> {
  /// Checks whether this is the last node in this tree
  bool get isLeaf;

  /// Returns the value stored at this node
  T get value;

  /// Returns the children of this node. Ideally, this should be empty if
  /// [isLeaf] is `true`
  List<PrintableNode<T>> get children;
}
