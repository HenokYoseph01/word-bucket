import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers/word_provider.dart';
import '../widgets/part_of_speech_badge.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.word, super.key});

  final SavedWord word;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _isSaving = false;

  Future<void> _recordAnswer(bool remembered) async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(wordNotifierProvider.notifier)
          .recordReview(widget.word, remembered: remembered);
      if (!mounted) return;
      Navigator.pop(
        context,
        remembered
            ? 'Nice work — the next review was scheduled.'
            : 'No problem — this word will return tomorrow.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;

    return Scaffold(
      appBar: AppBar(title: const Text('Review word')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              word.word,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (word.phonetic != null) ...[
              const SizedBox(height: 4),
              Text(
                word.phonetic!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: PartOfSpeechBadge(label: word.partOfSpeech),
            ),
            const SizedBox(height: 24),
            Text(
              word.definition,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (word.exampleSentence != null) ...[
              const SizedBox(height: 16),
              Text(
                '“${word.exampleSentence}”',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Previous successful reviews: ${word.reviewCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Text(
              'Did you remember this word?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : () => _recordAnswer(false),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : () => _recordAnswer(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Remembered'),
                  ),
                ),
              ],
            ),
            if (_isSaving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
