import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../background/review_worker.dart';
import '../../providers/word_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  bool _streakRemindersEnabled = false;
  bool _isUpdatingReminder = true;

  @override
  void initState() {
    super.initState();
    _loadReminderSetting();
  }

  Future<void> _loadReminderSetting() async {
    final enabled = await areStreakRemindersEnabled();
    if (!mounted) return;
    setState(() {
      _streakRemindersEnabled = enabled;
      _isUpdatingReminder = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statistics = ref.watch(reviewStatisticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: SafeArea(
        child: statistics.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StatisticsError(
            error: error,
            onRetry: () => ref.invalidate(reviewStatisticsProvider),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reviewStatisticsProvider);
              await ref.read(reviewStatisticsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.notifications_active_outlined,
                        ),
                        title: const Text('Streak reminder'),
                        subtitle: const Text(
                          'Around 1 PM, only when your streak is active, '
                          'you have not reviewed today, and words are due.',
                        ),
                        value: _streakRemindersEnabled,
                        onChanged: _isUpdatingReminder
                            ? null
                            : _setStreakReminder,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.35,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _StatCard(
                      icon: Icons.library_books_outlined,
                      value: '${data.totalWords}',
                      label: 'Words saved',
                    ),
                    _StatCard(
                      icon: Icons.schedule,
                      value: '${data.dueWords}',
                      label: 'Due now',
                    ),
                    _StatCard(
                      icon: Icons.fact_check_outlined,
                      value: '${data.totalReviews}',
                      label: 'Reviews',
                    ),
                    _StatCard(
                      icon: Icons.percent,
                      value: '${(data.rememberedRate * 100).round()}%',
                      label: 'Remembered',
                    ),
                    _StatCard(
                      icon: Icons.local_fire_department_outlined,
                      value: '${data.currentStreak}',
                      label: 'Day${data.currentStreak == 1 ? '' : 's'} streak',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Upcoming reviews',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.upcomingWords.isEmpty)
                  const _EmptySection(message: 'No reviews are scheduled yet.')
                else
                  Card(
                    child: Column(
                      children: [
                        for (final word in data.upcomingWords)
                          ListTile(
                            title: Text(word.word),
                            trailing: Text(
                              _formatReviewDate(word.nextReviewAt!),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Words to practise',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.frequentlyMissedWords.isEmpty)
                  const _EmptySection(
                    message: 'Missed words will appear here after reviews.',
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (final entry in data.frequentlyMissedWords)
                          ListTile(
                            title: Text(entry.key),
                            trailing: Text(
                              '${entry.value} ${entry.value == 1 ? 'miss' : 'misses'}',
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setStreakReminder(bool enabled) async {
    setState(() => _isUpdatingReminder = true);
    try {
      if (enabled) {
        final granted = await ref
            .read(notificationServiceProvider)
            .requestPermission();
        if (!mounted) return;
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Enable notifications in Android settings to use reminders.',
              ),
            ),
          );
          return;
        }
      }

      await setStreakRemindersEnabled(enabled);
      if (!mounted) return;
      setState(() => _streakRemindersEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'Streak reminders are on.' : 'Streak reminders are off.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update the reminder: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingReminder = false);
    }
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(date.year, date.month, date.day);
    final difference = reviewDay.difference(today).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: Text(message)),
    );
  }
}

class _StatisticsError extends StatelessWidget {
  const _StatisticsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load statistics: $error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
