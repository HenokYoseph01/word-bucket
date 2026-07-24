import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../background/review_worker.dart';
import '../../data/database/database.dart';
import '../../data/database/word_dao.dart';
import '../../providers/word_provider.dart';
import 'review_screen.dart';
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
  bool _remindersEnabled = false;
  bool _isUpdatingReminders = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReminderSetting();
    ref.read(wordNotifierProvider.notifier).syncHomeWidget();
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
      ref.invalidate(dueWordsProvider);
    }
  }

  Future<void> _refreshWords() async {
    ref.invalidate(savedWordsProvider);
    ref.invalidate(dueWordsProvider);
    await Future.wait([
      ref.read(savedWordsProvider.future),
      ref.read(dueWordsProvider.future),
    ]);
  }

  Future<void> _loadReminderSetting() async {
    final enabled = await areReviewRemindersEnabled();
    if (!mounted) return;
    setState(() {
      _remindersEnabled = enabled;
      _isUpdatingReminders = false;
    });
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
    final dueWordsAsync = ref.watch(dueWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WordBucket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _buildReminderToggle(),
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
              if (dueWordsAsync.valueOrNull case final dueWords?
                  when dueWords.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildReviewBanner(dueWords),
              ],
              const SizedBox(height: 16),
              Expanded(child: _buildSavedWords(wordsAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderToggle() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 8, bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _remindersEnabled
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: _remindersEnabled
                  ? 'Turn review reminders off'
                  : 'Turn review reminders on',
              onPressed: _isUpdatingReminders ? null : _toggleReminders,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: RotationTransition(turns: animation, child: child),
                ),
                child: Icon(
                  _remindersEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  key: ValueKey(_remindersEnabled),
                  color: _remindersEnabled
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              right: _remindersEnabled ? 1 : 5,
              top: _remindersEnabled ? 1 : 5,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _remindersEnabled ? 9 : 0,
                height: _remindersEnabled ? 9 : 0,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBanner(List<SavedWord> dueWords) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.school_outlined),
        title: Text(
          '${dueWords.length} ${dueWords.length == 1 ? 'word is' : 'words are'} due',
        ),
        subtitle: const Text('Practise your due words now'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => _openReviewQueue(dueWords),
      ),
    );
  }

  Future<void> _openReviewQueue(List<SavedWord> words) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ReviewScreen(words: words)),
    );
    ref.invalidate(dueWordsProvider);
    ref.invalidate(savedWordsProvider);
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleReminders() async {
    final enable = !_remindersEnabled;
    setState(() => _isUpdatingReminders = true);

    try {
      if (enable) {
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
      }

      await setReviewRemindersEnabled(enable);
      if (!mounted) return;
      setState(() => _remindersEnabled = enable);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enable
                ? 'Daily review reminders are on.'
                : 'Daily review reminders are off.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update reminders: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingReminders = false);
    }
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
                  ref
                      .read(wordNotifierProvider.notifier)
                      .deleteWord(savedWord.word);
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
