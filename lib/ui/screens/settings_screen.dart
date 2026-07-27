import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../background/review_worker.dart';
import '../../providers/word_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _daily = false;
  bool _streak = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      areReviewRemindersEnabled(),
      areStreakRemindersEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _daily = values[0];
      _streak = values[1];
      _loading = false;
    });
  }

  Future<bool> _permission() {
    return ref.read(notificationServiceProvider).requestPermission();
  }

  Future<void> _setDaily(bool value) async {
    if (value && !await _permission()) return;
    await setReviewRemindersEnabled(value);
    if (mounted) setState(() => _daily = value);
  }

  Future<void> _setStreak(bool value) async {
    if (value && !await _permission()) return;
    await setStreakRemindersEnabled(value);
    if (mounted) setState(() => _streak = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Daily word reminder'),
                  subtitle: const Text('A due word from your bucket'),
                  value: _daily,
                  onChanged: _loading ? null : _setDaily,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.local_fire_department_outlined),
                  title: const Text('Streak reminder'),
                  subtitle: const Text(
                    'Around 1 PM when your active streak needs attention',
                  ),
                  value: _streak,
                  onChanged: _loading ? null : _setStreak,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.auto_stories_outlined),
              title: Text('WordBucket'),
              subtitle: Text('A calmer way to collect and remember words.'),
            ),
          ),
        ],
      ),
    );
  }
}
