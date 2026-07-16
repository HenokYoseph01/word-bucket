import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/word_provider.dart';
import 'ui/screens/bucket_screen.dart';
import 'ui/widgets/definition_sheet.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class WordBucketApp extends ConsumerStatefulWidget {
  const WordBucketApp({super.key});

  @override
  ConsumerState<WordBucketApp> createState() => _WordBucketAppState();
}

class _WordBucketAppState extends ConsumerState<WordBucketApp> {
  static const _intentChannel = MethodChannel(intentChannelName);

  bool _isDefinitionSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _intentChannel.setMethodCallHandler(_handleMethodCall);
    WidgetsBinding.instance.addPostFrameCallback((_) => _readInitialWord());
  }

  @override
  void dispose() {
    _intentChannel.setMethodCallHandler(null);
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
    if (!context.mounted || savedWord == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“$savedWord” saved to your bucket.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WordBucket',
      debugShowCheckedModeBanner: false,
      theme: buildWordBucketTheme(),
      home: const BucketScreen(),
    );
  }
}
