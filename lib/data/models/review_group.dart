import '../database/database.dart';
import '../database/word_dao.dart';

class ReviewGroup {
  const ReviewGroup({required this.word, required this.meanings});

  final String word;
  final List<SavedMeaning> meanings;
}

Future<List<ReviewGroup>> buildReviewGroups(
  AppDatabase database,
  List<SavedMeaning> dueMeanings, {
  int? preferredMeaningId,
}) async {
  final orderedWords = <String>[];
  final preferred = preferredMeaningId == null
      ? null
      : dueMeanings
            .where((meaning) => meaning.id == preferredMeaningId)
            .firstOrNull;
  if (preferred != null) orderedWords.add(preferred.word);
  for (final meaning in dueMeanings) {
    if (!orderedWords.contains(meaning.word)) orderedWords.add(meaning.word);
  }

  final groups = <ReviewGroup>[];
  for (final word in orderedWords) {
    final meanings = await database.getMeanings(word);
    if (meanings.isNotEmpty) {
      groups.add(ReviewGroup(word: word, meanings: meanings));
    }
  }
  return groups;
}
