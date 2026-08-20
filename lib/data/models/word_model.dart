/// Represents one vocabulary word in WordBucket.
///
/// This is a plain Dart object. It does not know anything about Flutter UI,
/// APIs, or databases, so all of those layers can share it.
class WordModel {
  const WordModel({
    required this.word,
    this.phonetic,
    required this.partOfSpeech,
    required this.definition,
    this.exampleSentence,
    required this.savedAt,
    this.reviewCount = 0,
    this.nextReviewAt,
    this.senses = const [],
  });

  final String word;
  final String? phonetic;
  final String partOfSpeech;
  final String definition;
  final String? exampleSentence;
  final DateTime savedAt;
  final int reviewCount;
  final DateTime? nextReviewAt;
  final List<WordSense> senses;

  WordModel withSense(WordSense sense) => WordModel(
    word: word,
    phonetic: phonetic,
    partOfSpeech: sense.partOfSpeech,
    definition: sense.definition,
    exampleSentence: sense.exampleSentence,
    savedAt: savedAt,
    reviewCount: reviewCount,
    nextReviewAt: nextReviewAt,
    senses: senses,
  );
}

/// One possible meaning of a looked-up word.
///
/// Senses are transient lookup choices. The selected sense is copied onto the
/// [WordModel] before it is saved, so the existing database remains compatible.
class WordSense {
  const WordSense({
    required this.partOfSpeech,
    required this.definition,
    this.exampleSentence,
  });

  final String partOfSpeech;
  final String definition;
  final String? exampleSentence;
}
