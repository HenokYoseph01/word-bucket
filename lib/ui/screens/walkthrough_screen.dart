import 'package:flutter/material.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({this.initialPage = 0, super.key});

  final int initialPage;

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  late final PageController _controller;
  late int _page;

  static const _pages = [
    _WalkthroughPage(
      icon: Icons.text_fields_rounded,
      eyebrow: 'READ WITHOUT LEAVING',
      title: 'Highlight, then Bucketify',
      description:
          'Press and hold an unfamiliar word in an article, book, or browser. Choose Bucketify from Android’s text menu.',
      note:
          'Can’t see it? Tap More or ⋮ first. If the app only offers Copy, the next step has you covered.',
    ),
    _WalkthroughPage(
      icon: Icons.bubble_chart_rounded,
      eyebrow: 'READING COMPANION',
      title: 'Keep Bucketify close by',
      description:
          'In Settings, start Reading Companion and allow its floating book. Copy a word while reading, then tap the book to define it.',
      note:
          'Drag it to either edge, or onto the bottom remove target to stop. WordBucket reads the clipboard only when you tap.',
    ),
    _WalkthroughPage(
      icon: Icons.dashboard_customize_rounded,
      eyebrow: 'QUICK BUCKETIFY',
      title: 'When an app only offers Copy',
      description:
          'Copy the selected word, pull down Quick Settings, and tap Bucketify. Its definition opens over what you were reading.',
      note:
          'To add it manually, pull Quick Settings all the way down, tap Edit or the pencil, find Bucketify, and drag it into your active tiles.',
    ),
    _WalkthroughPage(
      icon: Icons.search_rounded,
      eyebrow: 'BUILD YOUR BUCKET',
      title: 'Look up and save words',
      description:
          'You can also search inside WordBucket. Read the definition and example, then save the word for later.',
      note: 'Your words stay on your device—no account is required.',
    ),
    _WalkthroughPage(
      icon: Icons.psychology_alt_rounded,
      eyebrow: 'REMEMBER NATURALLY',
      title: 'Review at the right time',
      description:
          'When words become due, try to remember each meaning before revealing it. Your answer shapes its next review.',
      note: 'Forgotten words return sooner; remembered words wait longer.',
    ),
    _WalkthroughPage(
      icon: Icons.widgets_rounded,
      eyebrow: 'HOME-SCREEN WIDGET',
      title: 'Keep a word within sight',
      description:
          'Press and hold an empty part of your home screen, open Widgets, find WordBucket, then drag the widget into place.',
      note:
          'The widget rotates through saved words. Tap it to open WordBucket, or refresh it when you have more than one word.',
    ),
    _WalkthroughPage(
      icon: Icons.notifications_none_rounded,
      eyebrow: 'GENTLE REMINDERS',
      title: 'Let words find you again',
      description:
          'Optional reminders bring due words back at useful moments without demanding your attention.',
      note: 'You can change reminders, themes, and palettes in Settings.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, _pages.length - 1);
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pop();

  Future<void> _next() async {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lastPage = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: colors.onPrimary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'WordBucket',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) =>
                    _WalkthroughPageView(page: _pages[index], index: index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: index == _page ? 24 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _page
                              ? colors.primary
                              : colors.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _next,
                      icon: Icon(
                        lastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(lastPage ? 'Start collecting words' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughPageView extends StatelessWidget {
  const _WalkthroughPageView({required this.page, required this.index});

  final _WalkthroughPage page;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 18),
      child: Column(
        children: [
          Container(
            width: 176,
            height: 176,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(52),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(page.icon, size: 76, color: colors.primary),
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: colors.onTertiaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 38),
          Text(
            page.eyebrow,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 19,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    page.note,
                    style: TextStyle(
                      color: colors.onTertiaryContainer,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkthroughPage {
  const _WalkthroughPage({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.note,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final String note;
}
