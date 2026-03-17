import 'package:flutter_test/flutter_test.dart';
import 'package:paperfinder/src/repositories/openalex_repository.dart';

void main() {
  test('decodeAbstractInvertedIndex rebuilds abstract order', () {
    final abstract = OpenAlexRepository.decodeAbstractInvertedIndex({
      'graph': [0],
      'neural': [1],
      'networks': [2],
    });

    expect(abstract, 'graph neural networks');
  });

  test('decodeAbstractInvertedIndex handles empty input', () {
    expect(OpenAlexRepository.decodeAbstractInvertedIndex({}), isEmpty);
  });
}
