import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/database/word_dao.dart';
import '../../data/models/review_group.dart';
import '../../providers/word_provider.dart';
import 'review_screen.dart';
import 'walkthrough_screen.dart';
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
  Timer? _suggestionDebounce;
  List<String> _suggestions = const [];
  int _suggestionRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(wordNotifierProvider.notifier).syncHomeWidget();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _suggestionDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(savedWordsProvider);
      ref.invalidate(savedMeaningsProvider);
      ref.invalidate(dueWordsProvider);
    }
  }

  Future<void> _refreshWords() async {
    ref.invalidate(savedWordsProvider);
    ref.invalidate(savedMeaningsProvider);
    ref.invalidate(dueWordsProvider);
    await Future.wait([
      ref.read(savedWordsProvider.future),
      ref.read(savedMeaningsProvider.future),
      ref.read(dueWordsProvider.future),
    ]);
  }

  Future<void> _lookUpWord() async {
    _suggestionDebounce?.cancel();
    _suggestionRequest++;
    if (_suggestions.isNotEmpty) {
      setState(() => _suggestions = const []);
    }
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

    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“$savedWord” saved to your bucket.')),
    );
  }

  Future<void> _pasteAndLookUp() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final copiedText = clipboard?.text?.trim();
    if (copiedText == null || copiedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copy a word first, then try again.')),
      );
      return;
    }

    final firstPart = copiedText.split(RegExp(r'\s+')).first;
    final word = firstPart.replaceAll(
      RegExp(r"^[^A-Za-z'-]+|[^A-Za-z'-]+$"),
      '',
    );
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The clipboard does not contain a word.')),
      );
      return;
    }

    _controller.text = word;
    await _lookUpWord();
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(savedWordsProvider);
    final words = wordsAsync.valueOrNull ?? const <SavedWord>[];
    final meanings = ref.watch(savedMeaningsProvider).valueOrNull;
    final dueWordsAsync = ref.watch(dueWordsProvider);
    final statistics = ref.watch(reviewStatisticsProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(words.length),
              const SizedBox(height: 20),
              _buildSearchField(),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildSuggestions(),
              ],
              if (dueWordsAsync.valueOrNull case final dueWords?
                  when dueWords.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildReviewBanner(dueWords),
              ],
              if (statistics != null &&
                  dueWordsAsync.valueOrNull?.isEmpty == true) ...[
                const SizedBox(height: 12),
                _buildProgressStrip(statistics),
              ],
              const SizedBox(height: 16),
              Expanded(child: _buildSavedWords(wordsAsync, meanings)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int wordCount) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.auto_stories_rounded, color: colors.onPrimary),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WordBucket',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Your personal reading companion',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'How to use WordBucket',
          onPressed: _openWalkthrough,
          icon: const Icon(Icons.help_outline_rounded),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$wordCount',
            style: TextStyle(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  void _openWalkthrough() {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const WalkthroughScreen()));
  }

  Widget _buildProgressStrip(ReviewStatistics statistics) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, size: 20),
          const SizedBox(width: 8),
          Text('${statistics.currentStreak} day streak'),
          const Spacer(),
          Text(
            '${statistics.totalReviews} reviews',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBanner(List<SavedMeaning> dueWords) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: ListTile(
        leading: const Icon(Icons.school_rounded),
        title: Text(
          '${dueWords.length} ${dueWords.length == 1 ? 'meaning is' : 'meanings are'} due',
        ),
        subtitle: const Text('Practice your due words now'),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: () => _openReviewQueue(dueWords),
      ),
    );
  }

  Future<void> _openReviewQueue(List<SavedMeaning> words) async {
    final groups = await buildReviewGroups(ref.read(databaseProvider), words);
    if (!mounted || groups.isEmpty) return;
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ReviewScreen(groups: groups)),
    );
    ref.invalidate(dueWordsProvider);
    ref.invalidate(savedWordsProvider);
    ref.invalidate(reviewStatisticsProvider);
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Paste copied word',
              onPressed: _pasteAndLookUp,
              icon: const Icon(Icons.content_paste_rounded),
            ),
            IconButton(
              tooltip: 'Search',
              onPressed: _lookUpWord,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        border: const OutlineInputBorder(),
      ),
      onChanged: _onSearchChanged,
      onSubmitted: (_) => _lookUpWord(),
    );
  }

  void _onSearchChanged(String value) {
    _suggestionDebounce?.cancel();
    final query = value.trim();
    final request = ++_suggestionRequest;

    if (query.length < 2) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }

    if (_suggestions.isNotEmpty) {
      setState(() => _suggestions = const []);
    }
    _suggestionDebounce = Timer(const Duration(milliseconds: 350), () async {
      final suggestions = await ref
          .read(wordSuggestionServiceProvider)
          .suggest(query);
      if (!mounted ||
          request != _suggestionRequest ||
          _controller.text.trim() != query) {
        return;
      }
      setState(() => _suggestions = suggestions);
    });
  }

  Widget _buildSuggestions() {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final suggestion in _suggestions)
            ListTile(
              dense: true,
              leading: const Icon(Icons.search, size: 20),
              title: Text(suggestion),
              onTap: () {
                _controller.text = suggestion;
                _controller.selection = TextSelection.collapsed(
                  offset: suggestion.length,
                );
                _lookUpWord();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSavedWords(
    AsyncValue<List<SavedWord>> wordsAsync,
    List<SavedMeaning>? meanings,
  ) {
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
                confirmDismiss: (_) => _confirmWordRemoval(
                  savedWord,
                  meanings
                          ?.where((meaning) => meaning.word == savedWord.word)
                          .length ??
                      1,
                ),
                onDismissed: (_) => _removeWord(savedWord),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: WordCard(
                  word: savedWord.toModel(),
                  meanings:
                      meanings
                          ?.where((meaning) => meaning.word == savedWord.word)
                          .toList(growable: false) ??
                      const [],
                  onDeleteWord: () async {
                    final count =
                        meanings
                            ?.where((meaning) => meaning.word == savedWord.word)
                            .length ??
                        1;
                    if (await _confirmWordRemoval(savedWord, count)) {
                      await _removeWord(savedWord);
                    }
                  },
                  onDeleteMeaning: (meaning) =>
                      _confirmAndRemoveMeaning(savedWord, meaning),
                  onConfirmMeaningDismiss: (meaning) =>
                      _confirmMeaningRemoval(savedWord, meaning),
                  onMeaningDismissed: (meaning) =>
                      _removeMeaning(savedWord, meaning),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmWordRemoval(SavedWord word, int meaningCount) async {
    return await _showRemovalConfirmation(
          icon: Icons.delete_forever_outlined,
          title: 'Remove “${word.word}”?',
          message: meaningCount > 1
              ? 'This removes the word and all $meaningCount saved meanings from your bucket.'
              : 'This removes the word and its saved meaning from your bucket.',
          actionLabel: 'Remove word',
        ) ??
        false;
  }

  Future<void> _confirmAndRemoveMeaning(
    SavedWord word,
    SavedMeaning meaning,
  ) async {
    final confirmed = await _confirmMeaningRemoval(word, meaning);
    if (!confirmed || !mounted) return;
    await _removeMeaning(word, meaning);
  }

  Future<bool> _confirmMeaningRemoval(
    SavedWord word,
    SavedMeaning meaning,
  ) async {
    return await _showRemovalConfirmation(
          icon: Icons.delete_outline_rounded,
          title: 'Remove this meaning?',
          message: '“${meaning.definition}” will be removed from ${word.word}.',
          actionLabel: 'Remove meaning',
        ) ??
        false;
  }

  Future<void> _removeMeaning(SavedWord word, SavedMeaning meaning) async {
    final snapshot = await ref
        .read(wordNotifierProvider.notifier)
        .deleteMeaningWithUndo(word.word, meaning.id);
    if (!mounted || snapshot == null) return;
    _showUndo(
      message: snapshot.meanings.length == 1
          ? '“${word.word}” removed from your bucket.'
          : 'Meaning removed from “${word.word}”.',
      snapshot: snapshot,
    );
  }

  Future<void> _removeWord(SavedWord word) async {
    final snapshot = await ref
        .read(wordNotifierProvider.notifier)
        .deleteWordWithUndo(word.word);
    if (!mounted || snapshot == null) return;
    _showUndo(
      message: '“${word.word}” removed from your bucket.',
      snapshot: snapshot,
    );
  }

  void _showUndo({
    required String message,
    required DeletedWordSnapshot snapshot,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref
                .read(wordNotifierProvider.notifier)
                .restoreDeletedWord(snapshot);
          },
        ),
      ),
    );
  }

  Future<bool?> _showRemovalConfirmation({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        final systemBottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, systemBottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: colors.onErrorContainer),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Keep it'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
