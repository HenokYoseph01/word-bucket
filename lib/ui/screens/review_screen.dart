import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers/word_provider.dart';
import '../widgets/part_of_speech_badge.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.words, super.key});

  final List<SavedWord> words;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _currentIndex = 0;
  int _rememberedCount = 0;
  int _againCount = 0;
  bool _isSaving = false;
  bool _isAnswerRevealed = false;

  Future<void> _recordAnswer(bool remembered) async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(wordNotifierProvider.notifier)
          .recordReview(widget.words[_currentIndex], remembered: remembered);
      if (!mounted) return;

      if (remembered) {
        _rememberedCount++;
      } else {
        _againCount++;
      }

      if (_currentIndex < widget.words.length - 1) {
        setState(() {
          _currentIndex++;
          _isSaving = false;
          _isAnswerRevealed = false;
        });
      } else {
        Navigator.pop(
          context,
          'Review complete: $_rememberedCount remembered, '
          '$_againCount to practise again.',
        );
      }
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_currentIndex];
    final currentNumber = _currentIndex + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Review words')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Review $currentNumber of ${widget.words.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: currentNumber / widget.words.length),
            const SizedBox(height: 28),
            Text(
              word.word,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isAnswerRevealed
                  ? _buildRevealedAnswer(context, word)
                  : _buildRecallPrompt(context),
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

  Widget _buildRecallPrompt(BuildContext context) {
    return Column(
      key: const ValueKey('recall-prompt'),
      children: [
        Text(
          'Think of the meaning before revealing the answer.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => setState(() => _isAnswerRevealed = true),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Reveal definition'),
        ),
      ],
    );
  }

  Widget _buildRevealedAnswer(BuildContext context, SavedWord word) {
    return Column(
      key: const ValueKey('revealed-answer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (word.phonetic != null) ...[
          Text(
            word.phonetic!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: PartOfSpeechBadge(label: word.partOfSpeech),
        ),
        const SizedBox(height: 24),
        Text(word.definition, style: Theme.of(context).textTheme.titleLarge),
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
      ],
    );
  }
}
