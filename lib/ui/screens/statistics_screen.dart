import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/word_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(reviewStatisticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your progress'), centerTitle: true),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _ProgressHero(data: data),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.bookmarks_outlined,
                        value: '${data.totalWords}',
                        label: 'Words',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.fact_check_outlined,
                        value: '${data.totalReviews}',
                        label: 'Reviews',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.schedule_rounded,
                        value: '${data.dueWords}',
                        label: 'Due',
                        highlighted: data.dueWords > 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _SectionHeading(
                  icon: Icons.calendar_month_outlined,
                  title: 'Coming up',
                  subtitle: 'Your next scheduled reviews',
                ),
                const SizedBox(height: 10),
                if (data.upcomingWords.isEmpty)
                  const _EmptySection(
                    icon: Icons.event_available_rounded,
                    message:
                        'You’re all caught up. New reviews will appear here.',
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < data.upcomingWords.length;
                          index++
                        ) ...[
                          _UpcomingReviewTile(
                            word: data.upcomingWords[index].word,
                            date: _formatReviewDate(
                              data.upcomingWords[index].nextReviewAt!,
                            ),
                          ),
                          if (index < data.upcomingWords.length - 1)
                            const Divider(height: 1, indent: 62),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                const _SectionHeading(
                  icon: Icons.fitness_center_rounded,
                  title: 'Words to strengthen',
                  subtitle: 'A little more practice will help these stick',
                ),
                const SizedBox(height: 10),
                if (data.frequentlyMissedWords.isEmpty)
                  const _EmptySection(
                    icon: Icons.verified_outlined,
                    message: 'No difficult words yet. Keep reviewing!',
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < data.frequentlyMissedWords.length;
                            index++
                          ) ...[
                            _PracticeWordRow(
                              entry: data.frequentlyMissedWords[index],
                              maximumMisses:
                                  data.frequentlyMissedWords.first.value,
                            ),
                            if (index < data.frequentlyMissedWords.length - 1)
                              const SizedBox(height: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(date.year, date.month, date.day);
    final difference = reviewDay.difference(today).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.data});

  final ReviewStatistics data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percentage = (data.rememberedRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: colors.tertiaryContainer,
                  size: 30,
                ),
                const SizedBox(height: 12),
                Text(
                  '${data.currentStreak} day${data.currentStreak == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  data.currentStreak == 0
                      ? 'Complete a review to begin'
                      : 'Your current review streak',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: data.totalReviews == 0 ? 0 : data.rememberedRate,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.onPrimary.withValues(alpha: 0.16),
                  color: colors.tertiaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$percentage% retained',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: highlighted ? colors.tertiaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(height: 7),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
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
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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

class _UpcomingReviewTile extends StatelessWidget {
  const _UpcomingReviewTile({required this.word, required this.date});

  final String word;
  final String date;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.menu_book_rounded, size: 19),
      ),
      title: Text(word, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(date, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _PracticeWordRow extends StatelessWidget {
  const _PracticeWordRow({required this.entry, required this.maximumMisses});

  final MapEntry<String, int> entry;
  final int maximumMisses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${entry.value} ${entry.value == 1 ? 'miss' : 'misses'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: entry.value / maximumMisses,
            minHeight: 7,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
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
            const Icon(Icons.bar_chart_rounded, size: 44),
            const SizedBox(height: 12),
            Text(
              'Could not load your progress.\n$error',
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
