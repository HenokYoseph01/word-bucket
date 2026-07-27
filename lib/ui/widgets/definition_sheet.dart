import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        child: SingleChildScrollView(
          child: Column(
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
                    ? _buildLoading(context)
                    : lookup.error != null
                    ? _buildError(context, lookup.error!)
                    : lookup.result != null
                    ? _buildDefinition(context)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
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
              'Finding that word…',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Looking through the dictionary',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
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
    final word = ref.watch(wordNotifierProvider).result!;
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
        PartOfSpeechBadge(label: word.partOfSpeech),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAE2D4)),
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
        const SizedBox(height: 22),
        Row(
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
                label: Text(_isSaving ? 'Saving…' : 'Save to Bucket'),
              ),
            ),
          ],
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
}
