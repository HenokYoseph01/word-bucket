import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/database/word_dao.dart';
import '../../providers/word_provider.dart';
import '../widgets/definition_sheet.dart';
import '../widgets/word_card.dart';

class BucketScreen extends ConsumerStatefulWidget {
  const BucketScreen({super.key});

  @override
  ConsumerState<BucketScreen> createState() => _BucketScreenState();
}

class _BucketScreenState extends ConsumerState<BucketScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookUpWord() async {
    FocusScope.of(context).unfocus();
    ref.read(wordNotifierProvider.notifier).lookUp(_controller.text);

    final savedWord = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const DefinitionSheet(),
    );

    ref.read(wordNotifierProvider.notifier).clear();
    if (!mounted || savedWord == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“$savedWord” saved to your bucket.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(savedWordsProvider);
    final words = wordsAsync.valueOrNull ?? const <SavedWord>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WordBucket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                '${words.length} ${words.length == 1 ? 'word' : 'words'}',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 16),
              Expanded(child: _buildSavedWords(wordsAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Look up a word',
        hintText: 'Try “ephemeral”',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Search',
          onPressed: _lookUpWord,
          icon: const Icon(Icons.arrow_forward),
        ),
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => _lookUpWord(),
    );
  }

  Widget _buildSavedWords(AsyncValue<List<SavedWord>> wordsAsync) {
    return wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Database error: $error', textAlign: TextAlign.center),
      ),
      data: (words) {
        if (words.isEmpty) {
          return const Center(
            child: Text(
              'Your bucket is empty.\nLook up a word and save it to get started.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          itemCount: words.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final savedWord = words[index];
            return Dismissible(
              key: ValueKey(savedWord.word),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                ref.read(databaseProvider).deleteWord(savedWord.word);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: WordCard(word: savedWord.toModel()),
            );
          },
        );
      },
    );
  }
}
