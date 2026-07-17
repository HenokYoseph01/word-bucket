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

class _BucketScreenState extends ConsumerState<BucketScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(savedWordsProvider);
    }
  }

  Future<void> _refreshWords() async {
    ref.invalidate(savedWordsProvider);
    await ref.read(savedWordsProvider.future);
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
          IconButton(
            tooltip: 'Test review notification',
            onPressed: words.isEmpty
                ? null
                : () => _showTestNotification(words.first),
            icon: const Icon(Icons.notifications_outlined),
          ),
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

  Future<void> _showTestNotification(SavedWord word) async {
    final notifications = ref.read(notificationServiceProvider);
    final granted = await notifications.requestPermission();
    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are disabled. Enable them in Android settings to receive reviews.',
          ),
        ),
      );
      return;
    }

    await notifications.showReview(word);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Review notification sent.')));
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
    return RefreshIndicator(
      onRefresh: _refreshWords,
      child: wordsAsync.when(
        loading: () =>
            const _ScrollableMessage(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ScrollableMessage(
          child: Text('Database error: $error', textAlign: TextAlign.center),
        ),
        data: (words) {
          if (words.isEmpty) {
            return const _ScrollableMessage(
              child: Text(
                'Your bucket is empty.\nLook up a word and save it to get started.\n\nPull down to refresh.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Center(child: child),
            ),
          ],
        );
      },
    );
  }
}
