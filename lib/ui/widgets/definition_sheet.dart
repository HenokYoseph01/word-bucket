import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/word_provider.dart';
import 'part_of_speech_badge.dart';

class DefinitionSheet extends ConsumerWidget {
  const DefinitionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(wordNotifierProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        top: 12,
        right: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (lookup.isLoading) _buildLoading(),
            if (lookup.error != null) _buildError(context, lookup.error!),
            if (lookup.result != null) _buildDefinition(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Looking up definition…'),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline,
          size: 36,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(error, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
        ),
      ],
    );
  }

  Widget _buildDefinition(BuildContext context, WidgetRef ref) {
    final word = ref.watch(wordNotifierProvider).result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                word.word,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (word.phonetic != null)
              Text(
                word.phonetic!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        PartOfSpeechBadge(label: word.partOfSpeech),
        const SizedBox(height: 16),
        Text(word.definition, style: Theme.of(context).textTheme.bodyLarge),
        if (word.exampleSentence != null) ...[
          const SizedBox(height: 12),
          Text(
            '“${word.exampleSentence!}”',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  final saved = await ref
                      .read(wordNotifierProvider.notifier)
                      .saveCurrentWord();
                  if (context.mounted && saved != null) {
                    Navigator.pop(context, saved.word);
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
