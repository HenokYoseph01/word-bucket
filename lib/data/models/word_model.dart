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
  });

  final String word;
  final String? phonetic;
  final String partOfSpeech;
  final String definition;
  final String? exampleSentence;
  final DateTime savedAt;
  final int reviewCount;
  final DateTime? nextReviewAt;
}
