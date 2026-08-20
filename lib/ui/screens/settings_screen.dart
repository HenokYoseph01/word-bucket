import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../background/review_worker.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/word_provider.dart';
import 'walkthrough_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  static const _quickTileChannel = MethodChannel(quickTileChannelName);
  static const _companionChannel = MethodChannel(readingCompanionChannelName);

  bool _daily = false;
  bool _streak = true;
  bool _loading = true;
  bool _updating = false;
  bool _addingQuickTile = false;
  bool _companionActive = false;
  bool _companionUpdating = false;
  bool _startCompanionAfterPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_startCompanionAfterPermission) {
      _finishCompanionPermissionRequest();
    } else {
      _refreshCompanionStatus();
    }
  }

  Future<void> _load() async {
    final values = await Future.wait([
      areReviewRemindersEnabled(),
      areStreakRemindersEnabled(),
      _readCompanionStatus(),
    ]);
    if (!mounted) return;
    setState(() {
      _daily = values[0];
      _streak = values[1];
      _companionActive = values[2];
      _loading = false;
    });
  }

  Future<bool> _readCompanionStatus() async {
    try {
      return await _companionChannel.invokeMethod<bool>(
            'isReadingCompanionActive',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _refreshCompanionStatus() async {
    final active = await _readCompanionStatus();
    if (mounted) setState(() => _companionActive = active);
  }

  Future<void> _setReadingCompanion(bool enabled) async {
    if (_companionUpdating) return;
    setState(() => _companionUpdating = true);
    try {
      if (!enabled) {
        await _companionChannel.invokeMethod<void>('stopReadingCompanion');
        if (mounted) setState(() => _companionActive = false);
        return;
      }

      final hasPermission =
          await _companionChannel.invokeMethod<bool>('hasOverlayPermission') ??
          false;
      if (!hasPermission) {
        final continueToSettings = await _explainOverlayPermission();
        if (continueToSettings != true || !mounted) return;
        _startCompanionAfterPermission = true;
        await _companionChannel.invokeMethod<void>('requestOverlayPermission');
        return;
      }
      await _startReadingCompanion();
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading Companion is available on Android.'),
        ),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not start companion.')),
      );
    } finally {
      if (mounted) setState(() => _companionUpdating = false);
    }
  }

  Future<void> _finishCompanionPermissionRequest() async {
    _startCompanionAfterPermission = false;
    final granted =
        await _companionChannel.invokeMethod<bool>('hasOverlayPermission') ??
        false;
    if (!mounted) return;
    if (granted) {
      await _startReadingCompanion();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Display-over-apps permission was not enabled. You can try again anytime.',
          ),
        ),
      );
    }
  }

  Future<void> _startReadingCompanion() async {
    final palette = ref.read(themePaletteProvider);
    await _companionChannel.invokeMethod<bool>('startReadingCompanion', {
      'color': palette.seed.toARGB32(),
    });
    if (!mounted) return;
    setState(() => _companionActive = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading Companion is ready. Copy a word, then tap it.'),
      ),
    );
  }

  Future<bool?> _explainOverlayPermission() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.auto_stories_rounded),
        title: const Text('Ready to start reading?'),
        content: const Text(
          'Add the little WordBucket book to your screen, then keep reading wherever you like. Copy a word and tap the book whenever curiosity strikes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add the bubble'),
          ),
        ],
      ),
    );
  }

  Future<void> _setReminder({
    required bool value,
    required bool isStreak,
  }) async {
    setState(() => _updating = true);
    try {
      if (value) {
        final granted = await ref
            .read(notificationServiceProvider)
            .requestPermission();
        if (!mounted) return;
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications are disabled. Enable them in Android settings first.',
              ),
            ),
          );
          return;
        }
      }

      if (isStreak) {
        await setStreakRemindersEnabled(value);
      } else {
        await setReviewRemindersEnabled(value);
      }
      if (!mounted) return;
      setState(() {
        if (isStreak) {
          _streak = value;
        } else {
          _daily = value;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${isStreak ? 'Streak' : 'Daily word'} reminder '
            '${value ? 'enabled' : 'disabled'}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update reminders: $error')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _addQuickTile() async {
    setState(() => _addingQuickTile = true);
    try {
      final outcome = await _quickTileChannel.invokeMethod<String>(
        requestAddQuickTileMethod,
      );
      if (!mounted) return;
      final message = switch (outcome) {
        'added' => 'Bucketify was added to Quick Settings.',
        'already_added' => 'Bucketify is already in Quick Settings.',
        'not_added' => 'The tile was not added. You can try again anytime.',
        'manual' =>
          'Open Quick Settings, tap Edit, then drag Bucketify into your tiles.',
        _ =>
          'Could not add the tile automatically. Add it from Quick Settings.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick Bucketify is available on Android.'),
        ),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not add the tile automatically. Open Quick Settings, tap Edit, and add Bucketify.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingQuickTile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _loading || _updating;
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(themePaletteProvider);
    ref.listen<AppPalette>(themePaletteProvider, (previous, next) {
      if (!_companionActive) return;
      _companionChannel.invokeMethod<void>('updateReadingCompanionColor', {
        'color': next.seed.toARGB32(),
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _buildHeader(context),
            const SizedBox(height: 26),
            ..._buildReadingCompanionSection(),
            const SizedBox(height: 28),
            const _SectionLabel(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Choose the reading atmosphere you prefer.',
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setMode(selection.first);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paper palette',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every palette includes a matching dark version.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final option in AppPalette.values)
                              SizedBox(
                                width: width,
                                child: _PaletteOption(
                                  palette: option,
                                  selected: palette == option,
                                  onTap: () => ref
                                      .read(themePaletteProvider.notifier)
                                      .setPalette(option),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel(
              icon: Icons.notifications_none_rounded,
              title: 'Reminders',
              subtitle: 'Choose how WordBucket gently brings words back.',
            ),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _ReminderTile(
                    icon: Icons.menu_book_rounded,
                    title: 'Daily word reminder',
                    description:
                        'Receive one due word to keep vocabulary fresh.',
                    value: _daily,
                    enabled: !disabled,
                    onChanged: (value) =>
                        _setReminder(value: value, isStreak: false),
                  ),
                  const Divider(height: 1, indent: 76),
                  _ReminderTile(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Streak reminder',
                    description:
                        'Around 1 PM, only when an active streak needs attention.',
                    value: _streak,
                    enabled: !disabled,
                    onChanged: (value) =>
                        _setReminder(value: value, isStreak: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel(
              icon: Icons.help_outline_rounded,
              title: 'Help',
              subtitle: 'A quick refresher whenever you need it.',
            ),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.auto_stories_rounded),
                    title: const Text('How to use WordBucket'),
                    subtitle: const Text('Replay the seven-step introduction.'),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const WalkthroughScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_rounded),
                    title: const Text('Add Quick Bucketify tile'),
                    subtitle: const Text(
                      'Copy a word, then define it from Quick Settings.',
                    ),
                    trailing: _addingQuickTile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                    onTap: _addingQuickTile ? null : _addQuickTile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'Built for calmer, uninterrupted reading.',
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WordBucket',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Collect words while reading. Remember them over time.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_updating) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: colors.tertiaryContainer, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make it yours',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Keep your reading rhythm comfortable.',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReadingCompanionSection() => [
    const _SectionLabel(
      icon: Icons.auto_stories_rounded,
      title: 'Reading Companion',
      subtitle: 'Keep Bucketify nearby without leaving your book.',
    ),
    const SizedBox(height: 10),
    Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ReminderTile(
            icon: Icons.bubble_chart_rounded,
            title: 'Start reading',
            description:
                'Show a draggable bubble. Copy a word and tap the bubble to define it.',
            value: _companionActive,
            enabled: !_companionUpdating,
            onChanged: _setReadingCompanion,
          ),
          const Divider(height: 1, indent: 76),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Yours until you tap'),
            subtitle: Text(
              'The bubble waits quietly and checks your copied word only when you ask it to.',
            ),
          ),
          const Divider(height: 1, indent: 76),
          const ListTile(
            leading: Icon(Icons.open_with_rounded),
            title: Text('Move it or dismiss it'),
            subtitle: Text(
              'Drag it to either edge, or drag it onto the remove target at the bottom to stop.',
            ),
          ),
        ],
      ),
    ),
  ];
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: '${palette.label} palette',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PaletteSwatch(color: palette.lightPaper),
                  Transform.translate(
                    offset: const Offset(-5, 0),
                    child: _PaletteSwatch(color: palette.seed),
                  ),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: _PaletteSwatch(color: palette.accent),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                palette.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: value
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      value ? 'ON' : 'OFF',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: value ? colors.primary : colors.outline,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
