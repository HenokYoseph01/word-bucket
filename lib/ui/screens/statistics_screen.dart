import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/word_provider.dart';
import 'word_progress_screen.dart';

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
                  icon: Icons.bar_chart_rounded,
                  title: 'Last 7 days',
                  subtitle: 'Your recent review rhythm',
                ),
                const SizedBox(height: 10),
                _WeeklyActivityCard(data: data),
                const SizedBox(height: 28),
                const _SectionHeading(
                  icon: Icons.event_note_rounded,
                  title: 'Review forecast',
                  subtitle: 'What your next few days look like',
                ),
                const SizedBox(height: 10),
                _ReviewForecast(data: data),
                const SizedBox(height: 28),
                const _SectionHeading(
                  icon: Icons.donut_large_rounded,
                  title: 'Meaning mastery',
                  subtitle: 'How securely each saved meaning is settling in',
                ),
                const SizedBox(height: 10),
                _MasteryOverview(data: data),
                const SizedBox(height: 28),
                const _SectionHeading(
                  icon: Icons.emoji_events_outlined,
                  title: 'Strongest meanings',
                  subtitle: 'Meanings you remember most reliably',
                ),
                const SizedBox(height: 10),
                _RankedWordList(
                  words: data.strongestWords,
                  emptyMessage: 'Complete a few reviews to discover strengths.',
                  strongest: true,
                ),
                const SizedBox(height: 28),
                const _SectionHeading(
                  icon: Icons.fitness_center_rounded,
                  title: 'Needs attention',
                  subtitle: 'Words that would benefit from more practice',
                ),
                const SizedBox(height: 10),
                _RankedWordList(
                  words: data.weakestWords,
                  emptyMessage: 'No reviewed meanings need attention yet.',
                  strongest: false,
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

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.data});

  final ReviewStatistics data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maximum = data.weeklyActivity.fold<int>(
      1,
      (value, day) => day.reviews > value ? day.reviews : value,
    );
    final totalReviews = data.weeklyActivity.fold<int>(
      0,
      (total, day) => total + day.reviews,
    );
    final wordsAdded = data.weeklyActivity.fold<int>(
      0,
      (total, day) => total + day.wordsAdded,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActivitySummary(
                    value: '$totalReviews',
                    label: 'Reviews',
                  ),
                ),
                Expanded(
                  child: _ActivitySummary(
                    value: '$wordsAdded',
                    label: 'Words added',
                  ),
                ),
                Expanded(
                  child: _ActivitySummary(
                    value: '${data.longestStreak}',
                    label: 'Best streak',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 128,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in data.weeklyActivity)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${day.reviews}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final heightFactor = day.reviews == 0
                                    ? 0.08
                                    : 0.2 + (0.8 * day.reviews / maximum);
                                return Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Tooltip(
                                    message:
                                        '${day.remembered}/${day.reviews} remembered',
                                    child: Container(
                                      width: 18,
                                      height:
                                          constraints.maxHeight * heightFactor,
                                      decoration: BoxDecoration(
                                        color: colors.primary.withValues(
                                          alpha: day.reviews == 0
                                              ? 0.18
                                              : 0.38 +
                                                    (day.rememberedRate * 0.62),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _weekday(day.date.weekday),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (data.mostActiveDay case final mostActive?) ...[
              const Divider(height: 26),
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: colors.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${_weekday(mostActive.date.weekday, full: true)} was your '
                      'most active day with ${mostActive.reviews} reviews.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _weekday(int weekday, {bool full = false}) {
    const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const long = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return (full ? long : short)[weekday - 1];
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ReviewForecast extends StatelessWidget {
  const _ReviewForecast({required this.data});

  final ReviewStatistics data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ForecastItem(
                label: 'Overdue',
                value: data.overdueWords,
                icon: Icons.warning_amber_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ForecastItem(
                label: 'Today',
                value: data.dueToday,
                icon: Icons.today_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ForecastItem(
                label: 'Tomorrow',
                value: data.dueTomorrow,
                icon: Icons.next_plan_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ForecastItem(
                label: 'Next 7 days',
                value: data.dueThisWeek,
                icon: Icons.date_range_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ForecastItem extends StatelessWidget {
  const _ForecastItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: value > 0 ? colors.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryOverview extends StatelessWidget {
  const _MasteryOverview({required this.data});

  final ReviewStatistics data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MasteryChip(
              label: 'Strong',
              count: data.masteryCount(MasteryLevel.strong),
              color: Colors.green,
            ),
            _MasteryChip(
              label: 'Learning',
              count: data.masteryCount(MasteryLevel.learning),
              color: Colors.blue,
            ),
            _MasteryChip(
              label: 'Needs practice',
              count: data.masteryCount(MasteryLevel.needsPractice),
              color: Colors.orange,
            ),
            _MasteryChip(
              label: 'New',
              count: data.masteryCount(MasteryLevel.newWord),
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryChip extends StatelessWidget {
  const _MasteryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RankedWordList extends StatelessWidget {
  const _RankedWordList({
    required this.words,
    required this.emptyMessage,
    required this.strongest,
  });

  final List<WordMastery> words;
  final String emptyMessage;
  final bool strongest;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return _EmptySection(
        icon: strongest
            ? Icons.hourglass_empty_rounded
            : Icons.verified_outlined,
        message: emptyMessage,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < words.length; index++) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: (strongest ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.14),
                child: Icon(
                  strongest
                      ? Icons.trending_up_rounded
                      : Icons.priority_high_rounded,
                  color: strongest ? Colors.green : Colors.orange,
                ),
              ),
              title: Text(
                '${words[index].word.word} · ${words[index].word.partOfSpeech}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${words[index].remembered}/${words[index].attempts} remembered',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(words[index].recallRate * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => WordProgressScreen(mastery: words[index]),
                ),
              ),
            ),
            if (index < words.length - 1) const Divider(height: 1, indent: 72),
          ],
        ],
      ),
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
