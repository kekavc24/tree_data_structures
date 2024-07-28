/// Represents a basic tree which can be displayed as a string
abstract interface class PrintableTree<T> {
  /// Returns all root nodes for this tree. Ideally, this should be empty if
  /// [count] is `0`
  List<PrintableNode<T>> get rootNodes;

  /// Checks whether this tree has any [PrintableNode]s.
  bool get isEmpty;

  /// Returns the name of this tree
  String get name;
}

/// Represents a node within a [PrintableTree]
abstract interface class PrintableNode<T> {
  /// Checks whether this is the last node in this tree
  bool get isLeaf;

  /// Returns the value stored at this node
  String get printableValue;

  /// Returns the children of this node. Ideally, this should be empty if
  /// [isLeaf] is `true`
  List<PrintableNode<T>> get children;
}

enum CharSet { utf, ascii }

String _branch(CharSet charset, {required bool isLastChild}) {
  return switch (charset) {
    CharSet.utf when isLastChild => '└──',
    CharSet.ascii when isLastChild => '`--',
    CharSet.utf => '├──',
    CharSet.ascii => '|--'
  };
}

String _space(int count) => count == 0 ? '' : ' ' * count;

const _empty = '\u2205';

String treeView(
  PrintableTree tree, {
  CharSet charSet = CharSet.utf,
  int spacing = 2,
  bool centerWithName = true,
  String lineBreak = '\n',
}) {
  final PrintableTree(:name, :isEmpty, :rootNodes) = tree;
  final buffer = StringBuffer(name);

  if (isEmpty) {
    buffer.write(_empty);
    return buffer.toString();
  }

  buffer.write(lineBreak);
  final distanceFromEdge = centerWithName ? name.length ~/ 2 : 0;
  final spaceFromEdge = _space(distanceFromEdge);
  final defaultIndent = _space(spacing);
  final lastIndex = rootNodes.length - 1;

  for (final (index, rNode) in rootNodes.indexed) {
    _nodeView(
      buffer,
      rNode,
      indentLevel: 0,
      spaceFromEdge: spaceFromEdge,
      defaultIndent: defaultIndent,
      charset: charSet,
      isLastChild: index == lastIndex,
      lineBreak: lineBreak,
    );
  }
  return buffer.toString();
}

void _nodeView(
  StringBuffer buffer,
  PrintableNode node, {
  required int indentLevel,
  required String spaceFromEdge,
  required String defaultIndent,
  required CharSet charset,
  required bool isLastChild,
  required String lineBreak,
}) {
  final PrintableNode(:isLeaf, :printableValue, :children) = node;

  final spacing = spaceFromEdge + _space(indentLevel * 4);
  final branch = _branch(charset, isLastChild: isLastChild);

  final nodeAsString = '$spacing$branch $printableValue$lineBreak';
  buffer.write(nodeAsString);

  if (isLeaf) return;

  /// Next indent inclusive of branch character both ascii and utf occupy
  /// 3 char spaces and the first character of the parent
  final nextIndentLevel = ++indentLevel;
  final lastIndex = children.length - 1;

  for (final (index, child) in children.indexed) {
    _nodeView(
      buffer,
      child,
      indentLevel: nextIndentLevel,
      spaceFromEdge: spaceFromEdge,
      defaultIndent: defaultIndent,
      charset: charset,
      isLastChild: index == lastIndex,
      lineBreak: lineBreak,
    );
  }
}
