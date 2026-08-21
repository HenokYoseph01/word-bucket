import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/theme_provider.dart';

class PaletteGalleryScreen extends ConsumerStatefulWidget {
  const PaletteGalleryScreen({super.key});

  @override
  ConsumerState<PaletteGalleryScreen> createState() =>
      _PaletteGalleryScreenState();
}

class _PaletteGalleryScreenState extends ConsumerState<PaletteGalleryScreen> {
  late final PageController _controller;
  late AppPalette _preview;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _preview = ref.read(themePaletteProvider);
    _controller = PageController(
      initialPage: AppPalette.values.indexOf(_preview),
      viewportFraction: 0.86,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _select() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    await ref.read(themePaletteProvider.notifier).setPalette(_preview);
    if (!mounted) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    await Future<void>.delayed(
      reduceMotion
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 720),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(themePaletteProvider);
    final colors = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !_confirming,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Choose your paper'),
          centerTitle: true,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                child: Text(
                  'Swipe through reading atmospheres. Nothing changes until you choose one.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: _confirming
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemCount: AppPalette.values.length,
                  onPageChanged: (index) =>
                      setState(() => _preview = AppPalette.values[index]),
                  itemBuilder: (context, index) {
                    final palette = AppPalette.values[index];
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        var distance = 0.0;
                        if (_controller.hasClients &&
                            _controller.position.haveDimensions) {
                          distance = ((_controller.page ?? index) - index)
                              .abs()
                              .clamp(0.0, 1.0)
                              .toDouble();
                        }
                        return Transform.scale(
                          scale: 1 - (distance * 0.055),
                          child: Opacity(
                            opacity: 1 - (distance * 0.24),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: _PalettePreviewCard(
                          palette: palette,
                          selected: selected == palette,
                          confirming: _confirming && _preview == palette,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              _PageDots(current: _preview),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, 18 + bottomPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _confirming ? null : _select,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        _confirming
                            ? Icons.check_rounded
                            : Icons.auto_awesome_rounded,
                        key: ValueKey(_confirming),
                      ),
                    ),
                    label: Text(
                      _confirming
                          ? '${_preview.label} is ready'
                          : selected == _preview
                          ? 'Keep ${_preview.label}'
                          : 'Use ${_preview.label}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PalettePreviewCard extends StatelessWidget {
  const _PalettePreviewCard({
    required this.palette,
    required this.selected,
    required this.confirming,
  });

  final AppPalette palette;
  final bool selected;
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    final paper = palette.lightPaper;
    final ink = palette.seed;
    final accent = palette.accent;
    final inkOnAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF171717);

    return AnimatedScale(
      scale: confirming ? 0.975 : 1,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: confirming || selected ? ink : ink.withValues(alpha: 0.2),
            width: confirming || selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ink.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: palette.lightPaper,
                        ),
                      ),
                      const Spacer(),
                      AnimatedScale(
                        scale: confirming ? 1 : 0,
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutBack,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: ink,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: paper,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    palette.label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      palette.collectionLabel.toUpperCase(),
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.78),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'A quiet place for the words you keep.',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ink.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'serendipity',
                          style: TextStyle(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Finding something lovely without looking for it.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.7),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Review',
                              style: TextStyle(
                                color: inkOnAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (final color in palette.previewColors)
                        Expanded(
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              border: Border.all(
                                color: ink.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                    ],
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

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current});

  final AppPalette current;

  @override
  Widget build(BuildContext context) {
    final activeIndex = AppPalette.values.indexOf(current);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Palette ${activeIndex + 1} of ${AppPalette.values.length}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < AppPalette.values.length; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: activeIndex == index ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: activeIndex == index
                    ? colors.primary
                    : colors.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
        ],
      ),
    );
  }
}
