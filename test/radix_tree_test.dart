import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:tree_data_structures/src/radix_tree/radix_tree.dart';

void main() {
  final radixTree = RadixTree();

  tearDown(() => radixTree.clear());

  void insertAll(List<String> words) {
    for (final word in words) {
      radixTree.insert(word);
    }
  }

  group('Insert', () {
    test('returns the whole word when empty', () {
      check(
        radixTree.insert('sum', returnPathOnInsert: true)?.toList(),
      ).isNotNull().deepEquals(['sum']);
    });

    test('splits existing word if similar', () {
      radixTree.insert('sum');

      check(
        radixTree.insert('summer', returnPathOnInsert: true)!.toList(),
      ).deepEquals(['sum', 'mer']);

      check(
        radixTree.insert('summed', returnPathOnInsert: true)!.toList(),
      ).isNotNull().deepEquals(['sum', 'me', 'd']);
    });

    test('adds empty node', () {
      radixTree.insert('summer');

      check(
        radixTree.insert('sum', returnPathOnInsert: true)!.toList(),
      ).deepEquals(['sum', '']);
    });
  });

  group('Search', () {
    test('returns true for normal contains', () {
      insertAll(['summer', 'summed']);

      check(radixTree.contains('summer')).isTrue();
      check(radixTree.contains('summed')).isTrue();
    });

    test('returns true when value is absent but a substring', () {
      insertAll(['summer', 'summed']);

      check(radixTree.contains('sum')).isTrue();
    });

    test('returns word where a prefix was found', () {
      insertAll(['summer']);

      final (:existence, :word, :lastSimilarity, :nextPosition) =
          radixTree.search('su');

      check(existence).equals(ResultExistence.exists);
      check(word).equals('summer');
      check(lastSimilarity).equals(2);
      check(nextPosition).equals(2);
    });

    test('returns word where a prefix can be inserted', () {
      insertAll(['summer', 'summed']);

      final (:existence, :word, lastSimilarity: _, nextPosition: _) =
          radixTree.search('sunny');

      check(existence).equals(ResultExistence.canExist);
      check(word).equals('summe'); // Where it can be inserted
    });

    test('inserts word if condition is met', () {
      insertAll(['summer', 'summed']);

      radixTree.search('sunny', insertOn: ResultExistence.canExist);

      check(radixTree.contains('sunny')).isTrue();
    });

    test('returns possible suffixes to a prefix', () {
      final withA = ['sad', 'saddle'];
      final withU = ['summer', 'summed', 'sunny'];

      final words = [...withA, ...withU];
      insertAll(words);

      check(radixTree.getPossibleSuffix('')).unorderedEquals(words);
      check(radixTree.getPossibleSuffix('s')).unorderedEquals(words);
      check(radixTree.getPossibleSuffix('sa')).unorderedEquals(withA);
      check(radixTree.getPossibleSuffix('su')).unorderedEquals(withU);
    });
  });

  group('Delete', () {
    test('returns true if word is removed', () {
      insertAll(['summer', 'sad']);

      check(radixTree.delete('summer')).isTrue();
    });

    test('returns false if word is absent', () {
      insertAll(['summer', 'sad']);

      check(radixTree.delete('sunny')).isFalse();
    });

    test('removes entire word catalogue if deleteSubstring is true', () {
      insertAll(
        [
          // Removed words
          'saddle',
          'saddened',

          // Ignored words
          'sack',
          'summer',
        ],
      );

      check(radixTree.delete('sad', deleteIfSubstring: true)).isTrue();
      check(radixTree.getPossibleSuffix('sad')).isEmpty();
      check(radixTree.getPossibleSuffix('s'))
        ..isNotEmpty()
        ..unorderedEquals(['sack', 'summer']);
    });
  });
}
