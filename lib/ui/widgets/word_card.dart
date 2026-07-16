import 'package:flutter/material.dart';

import '../../data/models/word_model.dart';
import 'part_of_speech_badge.dart';

class WordCard extends StatelessWidget {
  const WordCard({required this.word, this.onSave, super.key});

  final WordModel word;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    word.word,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (word.phonetic != null)
                  Text(
                    word.phonetic!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            PartOfSpeechBadge(label: word.partOfSpeech),
            const SizedBox(height: 12),
            Text(word.definition),
            if (word.exampleSentence != null) ...[
              const SizedBox(height: 10),
              Text(
                '“${word.exampleSentence!}”',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (onSave != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save to Bucket'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
