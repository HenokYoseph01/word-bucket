import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/database/word_dao.dart';
import 'providers/word_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/app_launch_screen.dart';
import 'ui/screens/review_screen.dart';
import 'ui/widgets/definition_sheet.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class WordBucketApp extends ConsumerStatefulWidget {
  const WordBucketApp({this.bucketifyMode = false, super.key});

  final bool bucketifyMode;

  @override
  ConsumerState<WordBucketApp> createState() => _WordBucketAppState();
}

class _WordBucketAppState extends ConsumerState<WordBucketApp> {
  static const _intentChannel = MethodChannel(intentChannelName);

  bool _isDefinitionSheetOpen = false;
  bool _isReviewScreenOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.bucketifyMode) {
      _intentChannel.setMethodCallHandler(_handleMethodCall);
      WidgetsBinding.instance.addPostFrameCallback((_) => _readInitialWord());
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _initializeNotificationInteraction(),
      );
    }
  }

  Future<void> _initializeNotificationInteraction() async {
    final notifications = ref.read(notificationServiceProvider);
    await notifications.initialize(onNotificationTap: _openReview);
    final launchWord = await notifications.getLaunchWord();
    if (launchWord != null && launchWord.isNotEmpty) {
      await _openReview(launchWord);
    }
  }

  Future<void> _openReview(String wordText) async {
    if (_isReviewScreenOpen || !mounted) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openReview(wordText),
      );
      return;
    }

    final database = ref.read(databaseProvider);
    final word = await database.getWord(wordText);
    if (!mounted || !context.mounted) return;
    if (word == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“$wordText” is no longer in your bucket.')),
      );
      return;
    }

    final dueWords = await database.getWordsDueForReview();
    if (!mounted || !context.mounted) return;
    final reviewWords = [
      word,
      ...dueWords.where((dueWord) => dueWord.word != word.word),
    ];

    _isReviewScreenOpen = true;
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ReviewScreen(words: reviewWords)),
    );
    _isReviewScreenOpen = false;
    ref.invalidate(dueWordsProvider);
    ref.invalidate(savedWordsProvider);
    ref.invalidate(reviewStatisticsProvider);

    if (!context.mounted || message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    if (widget.bucketifyMode) {
      _intentChannel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  Future<void> _readInitialWord() async {
    try {
      final word = await _intentChannel.invokeMethod<String>(
        getInitialWordMethod,
      );
      if (word != null && word.isNotEmpty) await _openDefinition(word);
    } on MissingPluginException {
      // Expected when running on a non-Android platform.
    } on PlatformException {
      // A platform-channel failure should not stop the main app from opening.
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != defineWordMethod || call.arguments is! String) return;
    await _openDefinition(call.arguments as String);
  }

  Future<void> _openDefinition(String word) async {
    ref.read(wordNotifierProvider.notifier).lookUp(word);
    if (_isDefinitionSheetOpen) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openDefinition(word),
      );
      return;
    }

    _isDefinitionSheetOpen = true;
    final savedWord = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const DefinitionSheet(),
    );
    _isDefinitionSheetOpen = false;

    if (!mounted) return;
    ref.read(wordNotifierProvider.notifier).clear();
    if (widget.bucketifyMode) {
      await _finishBucketify();
      return;
    }
    if (!context.mounted || savedWord == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“$savedWord” saved to your bucket.')),
    );
  }

  Future<void> _finishBucketify() async {
    try {
      await _intentChannel.invokeMethod<void>(finishBucketifyMethod);
    } on PlatformException {
      // Android will also close the activity through its normal back behavior.
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WordBucket',
      debugShowCheckedModeBanner: false,
      theme: buildWordBucketTheme(),
      darkTheme: buildWordBucketDarkTheme(),
      themeMode: themeMode,
      color: Colors.transparent,
      home: widget.bucketifyMode
          ? const ColoredBox(color: Colors.transparent)
          : const AppLaunchScreen(),
    );
  }
}
