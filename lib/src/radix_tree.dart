import 'dart:collection';
import 'dart:math';

import 'package:tree_data_structures/src/cheeky_avl_tree.dart';
import 'package:tree_data_structures/src/printable_tree.dart';
import 'package:tree_data_structures/src/utils.dart';

/// Indicates the nature of search query's existence
enum ResultExistence {
  /// Indicates that the entire value was found until it's terminal end. The
  /// terminal end can either be a substring of a [_RadixTreeNode] or the
  /// value of the [_RadixTreeNode] itself.
  exists,

  /// Indicates that a portion of a string was found within the [RadixTree].
  /// This is a good indicator that the string can be inserted.
  canExist,

  /// Indicates that the entire string is absent.
  notFound;
}

/// Indicates result by walking the [RadixTree] based on its prefixes.
///
/// - `[ResultExistence] existence`
///
/// - `[bool] isSubstring` indicates whether terminal end of a searched string
/// is a substring of the last [_RadixTreeNode] visited.
///
/// - `[int] lastSimilarity` indicates the number of characters that are
/// similar to the last searched node
///
/// - `[int] nextPosition` indicates the next possible index after the
/// `lastSimilarity`.
///
/// - `[List<_RadixTreeNode>] path` indicates all [_RadixTreeNode]s visited
/// before we found a `prefix`
typedef _SearchResult = (
  ResultExistence existence,
  bool isSubstring,
  int lastSimilarity,
  int nextPosition,
  List<_RadixTreeNode> path,
);

/// Represents a result object from searching a [RadixTree].
typedef RadixTreeResult = ({
  /// See [ResultExistence].
  ResultExistence existence,

  /// Indicates the word formed if:
  ///   1. The entire word was found - [ResultExistence.exists]
  ///   2. A portion of the word was found - [ResultExistence.canExist]
  ///   3. The entire word was found but as substring of the last word
  ///       - [ResultExistence.exists]
  String word,

  /// Indicates the number of characters that are similar to the last searched
  /// node
  int lastSimilarity,

  /// Indicates the next possible index after the [lastSimilarity]. This
  /// can possiblly be in the [word] returned or an index after it.
  int nextPosition,
});

RadixTreeResult _fromSearchResult(_SearchResult result) => (
      existence: result.$1,
      lastSimilarity: result.$3,
      nextPosition: result.$4,
      word: _buildFromLastPrefix(result.$5.lastOrNull)
    );

/// A basic implementation of a `RadixTree (Compact Trie)` whose nodes
/// store children in a [CheekyAvlTree].
///
/// See: https://en.wikipedia.org/wiki/Radix_tree
class RadixTree implements PrintableTree {
  /// Stores the root [_RadixTreeNode] for each alphabetical letter in the
  /// `Latin Alphabet` for guaranteed access in `O(1)`.
  ///
  /// We don't care about the order of storage.
  final HashMap<String, _RadixTreeNode> _nodes = HashMap();

  /// Removes all stored.
  void clear() => _nodes.clear();

  @override
  bool get isEmpty => _nodes.isEmpty;

  @override
  List<PrintableNode> get rootNodes => _nodes.values.toList();

  @override
  String get name => 'RadixTree';

  /// Inserts a [string] into the tree.
  ///
  /// By default, the string is trimmed. The tree remains unchanged
  /// if the [string] already exists or [string] is empty.
  ///
  /// Returns a
  Iterable<String>? insert(String string, {bool returnPathOnInsert = false}) {
    final value = string.trim();
    if (value.isEmpty) return [];

    final key = value[0];

    Iterable<String>? path;

    if (_nodes.containsKey(key)) {
      final head = _nodes[key]!;

      final nodePath = _add(0, head, string);

      // Incase it's not the head anymore
      _nodes[key] = _getParentAtRoot(nodePath.first);

      if (returnPathOnInsert) path = nodePath.map((node) => node.value);
    } else {
      final root = _RadixTreeNode(value, null);
      _nodes[key] = root;
      if (returnPathOnInsert) path = [root.value];
    }

    return path;
  }

  /// Returns `true` if the [prefix] can be found within the tree as a
  /// `substring` of a word or the word itself. Otherwise, `false`.
  bool contains(String prefix) {
    return search(prefix).existence == ResultExistence.exists;
  }

  /// Searches for a [prefix] within the tree.
  ///
  /// If [insertOn] is provided, then the [prefix] as a word will be inserted
  /// only when not [ResultExistence.exists].
  ///
  /// Returns a record with information about the `similarity` before the
  /// search terminated, the next expected index of the cursor on the word
  /// and the word (or a portion of it) where this [prefix] was found.
  RadixTreeResult search(String prefix, [ResultExistence? insertOn]) {
    final needle = prefix.trim();

    if (needle.isEmpty) {
      return (
        existence: ResultExistence.notFound,
        lastSimilarity: 0,
        nextPosition: 0,
        word: '',
      );
    }

    final key = needle[0];
    final result = _search(needle, _nodes[key]);
    final (existence, _, similarity, nextPosition, path) = result;

    if (existence != ResultExistence.exists && insertOn == existence) {
      if (existence == ResultExistence.notFound) {
        // Insert at root
        _nodes[key] = _RadixTreeNode(prefix, null);
      } else {
        _add(nextPosition - similarity, path.last, prefix);
      }
    }

    return _fromSearchResult(result);
  }

  /// Returns a list of possible words based on the provided [prefix].
  ///
  /// If [prefix] is not empty, this [RadixTree] guarantees that any
  /// suggestions returned will be alphabetically sorted.
  ///
  /// If [prefix] is empty, this [RadixTree] guarantees that the subset of
  /// words with the same initial alphabetical letter will be
  /// alphabetically sorted such that:
  ///   * If there are words that start with both `A` and `S` and the words
  ///     with `S` appear first, then all words which start with the letter `S`
  ///     will be sorted. Same applies to `A`.
  ///
  List<String> getPossibleSuffix(String prefix) {
    /// We search for the [_RadixNode] we want
    if (prefix.isNotEmpty) {
      final trimmed = prefix.trim();
      final (existence, _, _, _, path) = _search(
        trimmed,
        _nodes[trimmed[0]],
      );

      switch (existence) {
        case ResultExistence.notFound:
        case ResultExistence.canExist:
          return [];

        case ResultExistence.exists:
          {
            final terminal = path.removeLast();
            final prefix = path.isEmpty
                ? ''
                : path.fold('', (current, next) => '$current$next');

            final suggestions = <String>[];
            _completeSuffix(suggestions, prefix, terminal);
            return suggestions;
          }
      }
    }

    return _nodes.values.fold([], (previous, current) {
      _completeSuffix(previous, '', current);
      return previous;
    });
  }

  /// Deletes a word from the tree.
  ///
  /// If [deleteIfSubstring] is `true`, the entire word and any of its
  /// children with this [prefix] will be deleted.
  ///
  /// If [deleteIfSubstring] is `false`, then the entire word with this
  /// [prefix] will be deleted including any of its children if any are present.
  bool delete(String prefix, {bool deleteIfSubstring = false}) {
    final needle = prefix.trim();

    if (needle.isEmpty) return false;

    final key = needle[0];
    final (existence, isSubstring, _, _, path) = _search(
      needle,
      _nodes[key],
    );

    /// We want absolutes!
    ///
    /// [Feature Idea]: Allow deletion of nodes that exihibit a certain level
    /// of similarity with another string
    if (existence case ResultExistence.notFound || ResultExistence.canExist) {
      return false;
    }

    if (isSubstring && !deleteIfSubstring) return false;

    final node = path.last;

    final _RadixTreeNode(:parent, :isRoot, :isLeaf, :tree) = node;

    /// [Feature Idea]: Maybe allow tweaking whether to delete `leaf` nodes
    /// only or not.
    if (isSubstring || isLeaf) {
      if (isRoot) {
        _nodes.remove(key);
        return true;
      }

      parent!.tree.remove(node);
      _compactParent(parent);
    } else {
      /// If this node is not a `leaf` node, it means this string terminates
      /// exactly at this node. We have to remove the empty substring we have
      /// that acts as a facade to allow this node to be constructed.
      ///
      /// If not removed, accept the perfomance hit since we were given a
      /// prefix that contains a sub-prefix that's doesn't terminate at this
      /// node.
      final (didRemove, _) = tree.removeFirstWhere(
        (child) => child.value.isEmpty ? 0 : ''.compareTo(child.value),
      );

      if (didRemove) {
        _compactParent(node);
      } else {
        parent!.tree.remove(node);
        _compactParent(parent);
      }
    }

    _nodes[key] = _getParentAtRoot(parent!);
    return true;
  }

  /// Inserts a [String] into the tree.
  ///
  /// Do not depend on this method to return the last node inserted. Instead,
  /// use the [_RadixTreeNode] returns to check the parent at the root.
  List<_RadixTreeNode> _add(
    int position,
    _RadixTreeNode node,
    String toInsert,
  ) {
    final (existence, isSubstring, lastSimilarity, nextPosition, path) =
        _search(toInsert, node, position);

    final target = path.last;
    final _RadixTreeNode(:isLeaf, :isRoot, :value, :tree, :parent) = target;

    /// If [ResultExistence.exists], we ensure:
    ///   1. We only add if it is not a leaf node
    ///   2. An empty node exists indicating a null node
    ///
    /// Normally, it may exists if:
    ///  1. The entire string was iterated
    ///  2. The last portion or the entire string is a substring
    ///
    /// This condition seeks to:
    ///   1. Prevent wasting insertion cycles on duplicating entries that our
    ///      Avl tree will ignore.
    ///   2. Wasteful/wrongful splitting of a node.
    ///   3. We always check for empty terminal nodes.
    ///
    /// When `isSubstring` is true, it means our string ends as a portion of
    /// the value stored at the last node. Thus, logically it exists as a
    /// substring of a word we have but the word itself isn't in this tree!
    ///
    /// Example: "quadric" in "quadricuspidal" & "quadricuspidate":
    ///
    ///       quadric-uspid (dash shows substring)
    ///           /  \
    ///         ate  al
    ///
    /// Intentionally verbose!
    if (existence case ResultExistence.exists when !isSubstring) {
      if (isLeaf && _buildStringFromPath(path) == toInsert) return path;

      // Check for an empty node
      final empty = tree.firstWhere((child) => ''.compareTo(child.value));
      if (empty != null) return path..add(empty);
    }

    path.removeLast(); // We have it as the target

    final nodesToAddToPath = <_RadixTreeNode>[];

    /// This means that our [toInsert] string is a substring of the current
    /// node and thus we need to split it such that:
    ///
    /// Adding "sum" in a tree with "summer", we get:
    ///
    ///           sum - mer
    ///            \
    ///            ''
    ///
    /// Additionally, the last similarity during the [_search] may be less
    /// than actual value stored at this node. This means the current node
    /// has to be split such that:
    ///
    /// Adding "sunny" in a tree with "summer", we get:
    ///
    ///         su - mmer
    ///          \
    ///          nny
    if (isSubstring || lastSimilarity < value.length) {
      final hasValues = path.isNotEmpty;

      _RadixTreeNode? pathParent;
      var removedFromPath = false;

      if (!isRoot) {
        if (hasValues) {
          pathParent = path.removeLast();

          assert(
            pathParent == parent,
            'Conflicting parents found when adding $toInsert',
          );
          removedFromPath = true;
        } else {
          pathParent = parent;
        }
      } else {
        assert(
          !hasValues,
          'Found ${path.length} node(s) when the current node '
          'is a root node',
        );
      }

      final hasParent = pathParent != null;

      /// Our objects are mutable. Our [CheekyAvlTree] guarantees some lookup
      /// optimizations and therefore we need to respect its rules.
      ///
      /// If the [existing] node is split/modified, we may lose it within the
      /// [CheekyAvlTree] before we can remove it.
      if (hasParent) pathParent.tree.remove(target);

      final rootChunk = value.safeSubstring(0, lastSimilarity);
      final root = _RadixTreeNode(rootChunk, pathParent);

      // Update current node
      target
        ..value = value.safeSubstring(rootChunk.length)
        ..parent = root;

      /// Normally the last similarity will suffice for normal insertions
      /// but in case we found a massively split node, fallback to the
      /// next possible index.
      final inserted = _RadixTreeNode(
        toInsert.safeSubstring(max(lastSimilarity, nextPosition)),
        root,
      );

      root.tree
        ..insert(target)
        ..insert(inserted);

      // Insert the current root to parent if it was removed
      if (hasParent) pathParent.tree.insert(root);

      nodesToAddToPath.addAll([
        if (hasParent && removedFromPath) pathParent,
        root,
        inserted,
      ]);
    } else {
      nodesToAddToPath.add(target); // Bring back node we removed from path

      /// Normally, all additions will involve splitting the string into
      /// further chunks such that:
      ///
      /// Adding "summer" in a tree with "summed" and "sum" results in:
      ///
      ///           sum - me -r
      ///            \     \
      ///            ''     d
      final inserted = _RadixTreeNode(
        toInsert.safeSubstring(nextPosition),
        target,
      );

      tree.insert(inserted);
      nodesToAddToPath.add(inserted);

      /// If this tree was a leaf node, add an empty node to ensure we don't
      /// lose an existing word such that:
      ///
      /// Adding "summer" in a tree with "sum" results in:
      ///
      ///           sum - mer
      ///            \
      ///            ''
      if (isLeaf) tree.insert(_RadixTreeNode('', target));
    }

    return path..addAll(nodesToAddToPath);
  }
}

/// Represents a node within [RadixTree]
class _RadixTreeNode implements PrintableNode {
  _RadixTreeNode(this.value, this.parent);

  /// Represents the direct parent of this node
  _RadixTreeNode? parent;

  /// May represent an entire word or a substring of it.
  String value;

  /// Represents an [CheekyAvlTree] that stores the children of a
  /// [_RadixTreeNode] for `O(log n)` insertion, search & deletion.
  final CheekyAvlTree<_RadixTreeNode> tree = CheekyAvlTree(
    comparator: (thiz, that) => thiz.value.compareTo(that.value),
  );

  bool get isRoot => parent == null;

  @override
  bool get isLeaf => tree.length == 0;

  @override
  String toString() => value;

  @override
  List<PrintableNode> get children => tree.ordered();

  @override
  String get printableValue => value;
}

/// Recursively looks for [_RadixTreeNode] at the root with no parent
/// starting from the provided [node].
_RadixTreeNode _getParentAtRoot(_RadixTreeNode node) {
  var parent = node.parent;

  if (parent == null) return node;

  while (true) {
    final nextParent = parent!.parent;

    if (nextParent == null) return parent;
    parent = nextParent;
  }
}

/// Compares a [baseString] to a string [toBeAdded] and returns number of
/// characters that are similar.
int _checkSimilarity(String baseString, String toBeAdded) {
  var similarity = 0;
  final toBeAddedSize = toBeAdded.length;

  for (var index = 0; index < baseString.length; index++) {
    /// If string we want to add isn't long enough. Additionally, if no
    /// similarity is present.
    if (index == toBeAddedSize || baseString[index] != toBeAdded[index]) {
      break;
    }
    similarity++;
  }
  return similarity;
}

/// Searches for a string within a [RadixTree] starting from a provided
/// [node].
_SearchResult _search(String needle, _RadixTreeNode? node, [int position = 0]) {
  var needleIndex = position;
  final needleLimit = needle.length;

  final path = <_RadixTreeNode>[];

  var isSubString = false;
  var similarity = 0;
  var existence = ResultExistence.notFound;

  if (node != null) {
    var current = node;

    while (true) {
      path.add(current);
      final _RadixTreeNode(:value, :isLeaf, :tree) = current;

      similarity = _checkSimilarity(value, needle.substring(needleIndex));

      needleIndex += similarity;

      /// Exit if:
      ///   1. [current] has no more children
      ///   2. [current] only contains a portion of the [needle]
      ///   3. [needle]'s limit has been reached.
      if (similarity < value.length) {
        /// Ensure not a portion of the [needle]
        isSubString = needleIndex >= needleLimit;
        break;
      }

      if (isLeaf || needleIndex >= needleLimit) break;

      final next = tree.firstWhere((child) {
        final char = needle[needleIndex];

        final _RadixTreeNode(value: childValue) = child;

        if (childValue.startsWith(char)) return 0;
        return char.compareTo(childValue);
      });

      if (next == null) break;
      current = next;
    }

    existence = needleIndex >= needleLimit || isSubString
        ? ResultExistence.exists
        : ResultExistence.canExist;
  }

  return (existence, isSubString, similarity, needleIndex, path);
}

/// Joins all child nodes to the parent [node] to form all possible words
void _completeSuffix(List<String> buffer, String prefix, _RadixTreeNode node) {
  final _RadixTreeNode(:value, :isLeaf, :tree) = node;

  if (isLeaf) {
    buffer.add(prefix + value);
    return;
  }

  for (final child in tree.ordered()) {
    _completeSuffix(buffer, '$prefix$value', child);
  }
}

/// Compacts a [parent] with only one child node and guarantees children of the
/// child node will be child of the [parent] after.
void _compactParent(_RadixTreeNode parent) {
  final _RadixTreeNode(:value, :isLeaf, :tree) = parent;

  // We want to concatenate this parent with its child if only one is present
  if (isLeaf || tree.length != 1) return;

  final child = tree.root!;
  parent.value = value + child.value;
  tree.swapWith(child.tree);
}

/// Creates a word starting from the substring at the end to the prefix at the
/// top.
///
/// Unlike [_completeSuffix] which goes forward and generates multiple strings,
/// this function build backwards and generates only a single string.
String _buildFromLastPrefix(_RadixTreeNode? terminal) {
  final buffer = <String>[];
  var node = terminal;
  while (node != null) {
    final _RadixTreeNode(:value, :parent) = node;
    buffer.add(value);
    node = parent;
  }

  return buffer.reversed.join();
}

String _buildStringFromPath(List<_RadixTreeNode> nodes) =>
    nodes.map((node) => node.value).join();
