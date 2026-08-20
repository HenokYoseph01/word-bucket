import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers/word_provider.dart';
import '../widgets/part_of_speech_badge.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.words, super.key});

  final List<SavedMeaning> words;

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
          '$_againCount to practice again.',
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
      appBar: AppBar(title: const Text('Review session'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                Text(
                  'MEANING $currentNumber OF ${widget.words.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${((currentNumber / widget.words.length) * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: currentNumber / widget.words.length,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.72),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    word.word,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _isAnswerRevealed
                    ? _buildRevealedAnswer(context, word)
                    : _buildRecallPrompt(context, word),
              ),
            ),
            if (_isSaving) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecallPrompt(BuildContext context, SavedMeaning meaning) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('recall-prompt'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_alt_outlined,
            size: 36,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(height: 12),
          Text(
            'Can you recall this meaning?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          PartOfSpeechBadge(label: meaning.partOfSpeech),
          const SizedBox(height: 8),
          Text(
            'Take a moment to recall it before checking.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _isAnswerRevealed = true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Reveal definition'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedAnswer(BuildContext context, SavedMeaning word) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('revealed-answer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PartOfSpeechBadge(label: word.partOfSpeech),
                  const Spacer(),
                  if (word.phonetic != null)
                    Text(
                      word.phonetic!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                word.definition,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(height: 1.5),
              ),
              if (word.exampleSentence != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '“${word.exampleSentence}”',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 17, color: colors.outline),
            const SizedBox(width: 6),
            Text(
              '${word.reviewCount} successful '
              '${word.reviewCount == 1 ? 'review' : 'reviews'} before this',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          'Did you remember this meaning?',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => _recordAnswer(false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Icon(Icons.refresh_rounded),
                      SizedBox(height: 3),
                      Text('Again'),
                      Text('Review sooner', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isSaving ? null : () => _recordAnswer(true),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Icon(Icons.check_rounded),
                      SizedBox(height: 3),
                      Text('Remembered'),
                      Text('Space it out', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
