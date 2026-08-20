import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/models/review_group.dart';
import '../../providers/word_provider.dart';
import '../widgets/part_of_speech_badge.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.groups, super.key});

  final List<ReviewGroup> groups;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _groupIndex = 0;
  int _rememberedCount = 0;
  int _againCount = 0;
  bool _revealed = false;
  final Map<int, bool> _answers = {};
  final Set<int> _saving = {};

  ReviewGroup get _group => widget.groups[_groupIndex];
  bool get _groupComplete =>
      _group.meanings.every((meaning) => _answers.containsKey(meaning.id));

  Future<void> _recordAnswer(SavedMeaning meaning, bool remembered) async {
    if (_saving.contains(meaning.id) || _answers.containsKey(meaning.id)) {
      return;
    }
    setState(() => _saving.add(meaning.id));
    try {
      await ref
          .read(wordNotifierProvider.notifier)
          .recordReview(meaning, remembered: remembered);
      if (!mounted) return;
      setState(() {
        _saving.remove(meaning.id);
        _answers[meaning.id] = remembered;
        if (remembered) {
          _rememberedCount++;
        } else {
          _againCount++;
        }
      });
    } finally {
      if (mounted && _saving.contains(meaning.id)) {
        setState(() => _saving.remove(meaning.id));
      }
    }
  }

  void _continue() {
    if (!_groupComplete) return;
    if (_groupIndex < widget.groups.length - 1) {
      setState(() {
        _groupIndex++;
        _revealed = false;
      });
      return;
    }
    Navigator.pop(
      context,
      'Review complete: $_rememberedCount remembered, '
      '$_againCount to practice again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentNumber = _groupIndex + 1;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Review session'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                Text(
                  'WORD $currentNumber OF ${widget.groups.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${((currentNumber / widget.groups.length) * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: currentNumber / widget.groups.length,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: colors.onPrimary.withValues(alpha: 0.72),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _group.word,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${_group.meanings.length} saved '
                    '${_group.meanings.length == 1 ? 'meaning' : 'meanings'}',
                    style: TextStyle(
                      color: colors.onPrimary.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _revealed
                  ? _revealedMeanings(context)
                  : _recallPrompt(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recallPrompt(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('recall-${_group.word}'),
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
            _group.meanings.length == 1
                ? 'What does this word mean?'
                : 'How many meanings can you recall?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            _group.meanings.length == 1
                ? 'Take a moment before checking the definition.'
                : 'Try to remember all ${_group.meanings.length} meanings before checking.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _revealed = true),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(
                _group.meanings.length == 1
                    ? 'Reveal definition'
                    : 'Reveal meanings',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revealedMeanings(BuildContext context) {
    return Column(
      key: ValueKey('meanings-${_group.word}'),
      children: [
        for (var index = 0; index < _group.meanings.length; index++) ...[
          _meaningCard(context, _group.meanings[index], index + 1),
          if (index != _group.meanings.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _groupComplete ? _continue : null,
            icon: Icon(
              _groupIndex == widget.groups.length - 1
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
            ),
            label: Text(
              _groupComplete
                  ? (_groupIndex == widget.groups.length - 1
                        ? 'Finish review'
                        : 'Next word')
                  : 'Answer each meaning to continue',
            ),
          ),
        ),
      ],
    );
  }

  Widget _meaningCard(BuildContext context, SavedMeaning meaning, int number) {
    final colors = Theme.of(context).colorScheme;
    final answer = _answers[meaning.id];
    final saving = _saving.contains(meaning.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: answer == null
            ? colors.surfaceContainerLow
            : (answer
                  ? colors.tertiaryContainer.withValues(alpha: 0.65)
                  : colors.errorContainer.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: answer == null
              ? colors.outlineVariant
              : (answer ? colors.tertiary : colors.error),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              PartOfSpeechBadge(label: meaning.partOfSpeech),
              const Spacer(),
              if (answer != null)
                Icon(
                  answer
                      ? Icons.check_circle_rounded
                      : Icons.replay_circle_filled,
                  color: answer ? colors.tertiary : colors.error,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            meaning.definition,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(height: 1.45),
          ),
          if (meaning.exampleSentence != null) ...[
            const SizedBox(height: 12),
            Text(
              '“${meaning.exampleSentence}”',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (answer == null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () => _recordAnswer(meaning, false),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Again'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () => _recordAnswer(meaning, true),
                    icon: saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Remembered'),
                  ),
                ),
              ],
            )
          else
            Text(
              answer ? 'Remembered' : 'Practice again sooner',
              style: TextStyle(
                color: answer
                    ? colors.onTertiaryContainer
                    : colors.onErrorContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}
