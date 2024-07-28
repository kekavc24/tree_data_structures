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

/// Represent the desire character set to use. Implicit ascii or rendered utf
enum CharSet { utf, ascii }

/// Returns a branch for use within a [PrintableTree] or [PrintableNode]
String _branch(CharSet charset, {required bool isLastChild}) {
  return switch (charset) {
    CharSet.utf when isLastChild => '└──',
    CharSet.ascii when isLastChild => '`--',
    CharSet.utf => '├──',
    CharSet.ascii => '|--'
  };
}

/// Returns a pipe that acts as a separator between [PrintableNode]s of
/// another [PrintableNode] or of a [PrintableTree]
String _separator(CharSet charset) => charset == CharSet.utf ? '│' : '|';

/// Generates space based on the [count] provided
String _space(int count) => count == 0 ? '' : ' ' * count;

/// Ø - NULL/Empty set character.
const _empty = '\u00D8';

/// Generates a tree for any [PrintableTree] provided.
///
/// If [centerWithName] is `true`, then the tree's root axis starts at the
/// centre of the [tree.name] provided. Otherwise, axis starts at the beginning.
String treeView(
  PrintableTree tree, {
  CharSet charSet = CharSet.utf,
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
  final lastIndex = rootNodes.length - 1;

  for (final (index, rNode) in rootNodes.indexed) {
    _nodeView(
      buffer,
      rNode,
      isRoot: true,
      prefix: spaceFromEdge,
      separator: _separator(charSet),
      charset: charSet,
      isLastChild: index == lastIndex,
      lineBreak: lineBreak,
    );
  }
  return buffer.toString();
}

/// Recursively appends a single [node]'s view to the [buffer] provided.
void _nodeView(
  StringBuffer buffer,
  PrintableNode node, {
  required bool isRoot,
  required String prefix,
  required String separator,
  required CharSet charset,
  required bool isLastChild,
  required String lineBreak,
}) {
  final PrintableNode(:isLeaf, :printableValue, :children) = node;

  /// If not root,
  ///   1. 3 characters for the branch.
  ///   2. 1 for the space we apply after the branch
  var indentSize = isRoot ? 0 : 4;

  /// 1 space is used up if displaying view of a node nested within another
  /// node that is not the last child.
  if (!isRoot && prefix.endsWith(separator)) {
    indentSize -= 1;
  }

  final indent = _space(indentSize);
  final branch = _branch(charset, isLastChild: isLastChild);

  prefix += indent;

  final nodeAsString = '$prefix$branch $printableValue$lineBreak';
  buffer.write(nodeAsString);

  if (isLeaf) return;
  
  final lastIndex = children.length - 1;

  for (final (index, child) in children.indexed) {
    _nodeView(
      buffer,
      child,
      isRoot: false,
      prefix: isLastChild ? prefix : '$prefix$separator',
      separator: separator,
      charset: charset,
      isLastChild: index == lastIndex,
      lineBreak: lineBreak,
    );
  }
}
