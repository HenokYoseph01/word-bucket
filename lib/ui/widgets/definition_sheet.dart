import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/models/word_model.dart';
import '../../providers/word_provider.dart';
import 'part_of_speech_badge.dart';

class DefinitionSheet extends ConsumerStatefulWidget {
  const DefinitionSheet({super.key});

  @override
  ConsumerState<DefinitionSheet> createState() => _DefinitionSheetState();
}

class _DefinitionSheetState extends ConsumerState<DefinitionSheet> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final lookup = ref.watch(wordNotifierProvider);
    final mediaQuery = MediaQuery.of(context);
    final safeBottom = math.max(
      mediaQuery.viewInsets.bottom,
      mediaQuery.viewPadding.bottom,
    );
    final sheetContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: lookup.isLoading
              ? _buildLoading(context, lookup.isRetrying)
              : lookup.error != null
              ? _buildError(context, lookup.error!, lookup.canRetry)
              : lookup.result != null
              ? _buildDefinition(context)
              : const SizedBox.shrink(),
        ),
      ],
    );

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          top: 12,
          right: 20,
          bottom: safeBottom + 20,
        ),
        child: lookup.result == null
            ? SingleChildScrollView(child: sheetContent)
            : SizedBox(
                height: math.min(mediaQuery.size.height * 0.84, 720),
                child: Column(
                  children: [
                    Expanded(child: SingleChildScrollView(child: sheetContent)),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    _buildDefinitionActions(context, lookup),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, bool isRetrying) {
    return Padding(
      key: const ValueKey('definition-loading'),
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isRetrying ? 'Rebucketifying…' : 'Bucketifying…',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              isRetrying
                  ? 'Giving the dictionary a quiet moment'
                  : 'Leafing through the dictionary',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error, bool canRetry) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('definition-error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.search_off_rounded, color: colors.onErrorContainer),
        ),
        const SizedBox(height: 18),
        Text(
          'We couldn’t find that one',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        if (canRetry) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ref.read(wordNotifierProvider.notifier).retry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Try another word'),
          ),
        ),
      ],
    );
  }

  Widget _buildDefinition(BuildContext context) {
    final lookup = ref.watch(wordNotifierProvider);
    final word = lookup.result!;
    final existingWord = lookup.existingWord;
    final colors = Theme.of(context).colorScheme;

    return Column(
      key: ValueKey('definition-${word.word}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.menu_book_rounded, color: colors.onPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (word.phonetic != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      word.phonetic!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (existingWord != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '${lookup.savedMeanings.length} saved '
                    '${lookup.savedMeanings.length == 1 ? 'meaning' : 'meanings'} '
                    'in your bucket',
                    style: TextStyle(
                      color: colors.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (word.senses.length > 1) ...[
          Row(
            children: [
              Text(
                'CHOOSE THE MEANING',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${word.senses.length} meanings',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < word.senses.length; index++) ...[
            _MeaningChoice(
              number: index + 1,
              sense: word.senses[index],
              selected:
                  word.partOfSpeech == word.senses[index].partOfSpeech &&
                  word.definition == word.senses[index].definition,
              savedAt: _savedAtFor(word.senses[index], lookup.savedMeanings),
              onTap: () =>
                  ref.read(wordNotifierProvider.notifier).selectSense(index),
            ),
            if (index != word.senses.length - 1) const SizedBox(height: 9),
          ],
        ] else ...[
          PartOfSpeechBadge(label: word.partOfSpeech),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEFINITION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  word.definition,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
        if (word.exampleSentence != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: colors.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    word.exampleSentence!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDefinitionActions(BuildContext context, LookupState lookup) {
    final selectedSavedMeaning = lookup.selectedSavedMeaning;
    if (selectedSavedMeaning != null) {
      return SizedBox(
        key: ValueKey('saved-${selectedSavedMeaning.id}'),
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check_rounded),
          label: Text(
            'Already saved · ${_formatSavedDate(selectedSavedMeaning.savedAt)}',
          ),
        ),
      );
    }
    return Row(
      key: ValueKey('save-${lookup.result?.definition}'),
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveWord,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bookmark_add_rounded),
            label: Text(
              _isSaving
                  ? 'Saving…'
                  : lookup.existingWord != null
                  ? 'Add this meaning'
                  : 'Save to Bucket',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveWord() async {
    setState(() => _isSaving = true);
    try {
      final saved = await ref
          .read(wordNotifierProvider.notifier)
          .saveCurrentWord();
      if (mounted && saved != null) Navigator.pop(context, saved.word);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatSavedDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  DateTime? _savedAtFor(WordSense sense, List<SavedMeaning> savedMeanings) {
    final normalized = _normalizeDefinition(sense.definition);
    for (final saved in savedMeanings) {
      if (_normalizeDefinition(saved.definition) == normalized) {
        return saved.savedAt;
      }
    }
    return null;
  }

  String _normalizeDefinition(String definition) =>
      definition.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

class _MeaningChoice extends StatelessWidget {
  const _MeaningChoice({
    required this.number,
    required this.sense,
    required this.selected,
    required this.savedAt,
    required this.onTap,
  });

  final int number;
  final WordSense sense;
  final bool selected;
  final DateTime? savedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.65)
          : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? colors.primary
                      : colors.surfaceContainerHigh,
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: colors.onPrimary,
                      )
                    : Text(
                        '$number',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PartOfSpeechBadge(label: sense.partOfSpeech),
                    const SizedBox(height: 8),
                    Text(
                      sense.definition,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.4),
                    ),
                    if (savedAt != null) ...[
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_added_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Saved ${_shortDate(savedAt!)}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
