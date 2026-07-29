import 'package:flutter/material.dart';

import '../../providers/word_provider.dart';
import '../widgets/part_of_speech_badge.dart';

class WordProgressScreen extends StatelessWidget {
  const WordProgressScreen({required this.mastery, super.key});

  final WordMastery mastery;

  @override
  Widget build(BuildContext context) {
    final word = mastery.word;
    final colors = Theme.of(context).colorScheme;
    final percentage = (mastery.recallRate * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Word progress'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (word.phonetic != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      word.phonetic!,
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  PartOfSpeechBadge(label: word.partOfSpeech),
                  const SizedBox(height: 18),
                  Text(
                    word.definition,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onPrimary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _WordMetric(
                    value: '$percentage%',
                    label: 'Recall',
                    icon: Icons.psychology_alt_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WordMetric(
                    value: '${mastery.attempts}',
                    label: 'Reviews',
                    icon: Icons.fact_check_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WordMetric(
                    value: '${mastery.word.reviewCount}',
                    label: 'Current run',
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: Icon(_levelIcon(mastery.level)),
                title: Text(
                  _levelLabel(mastery.level),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(_levelExplanation(mastery.level)),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Review history',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Every answer recorded for this word',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            if (mastery.history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('This word has not been reviewed yet.'),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < mastery.history.length;
                      index++
                    ) ...[
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (mastery.history[index].remembered
                                      ? Colors.green
                                      : Colors.orange)
                                  .withValues(alpha: 0.14),
                          child: Icon(
                            mastery.history[index].remembered
                                ? Icons.check_rounded
                                : Icons.refresh_rounded,
                            color: mastery.history[index].remembered
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        title: Text(
                          mastery.history[index].remembered
                              ? 'Remembered'
                              : 'Again',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          _formatDate(mastery.history[index].reviewedAt),
                        ),
                        trailing: Text(
                          '#${mastery.history.length - index}',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                      if (index < mastery.history.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _levelLabel(MasteryLevel level) => switch (level) {
    MasteryLevel.newWord => 'New word',
    MasteryLevel.learning => 'Learning',
    MasteryLevel.strong => 'Strong',
    MasteryLevel.needsPractice => 'Needs practice',
  };

  String _levelExplanation(MasteryLevel level) => switch (level) {
    MasteryLevel.newWord => 'Complete more reviews to establish a pattern.',
    MasteryLevel.learning => 'Your recall is developing with each review.',
    MasteryLevel.strong => 'You remember this word reliably.',
    MasteryLevel.needsPractice =>
      'A few closer reviews should help this stick.',
  };

  IconData _levelIcon(MasteryLevel level) => switch (level) {
    MasteryLevel.newWord => Icons.fiber_new_rounded,
    MasteryLevel.learning => Icons.school_outlined,
    MasteryLevel.strong => Icons.verified_rounded,
    MasteryLevel.needsPractice => Icons.fitness_center_rounded,
  };

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} · '
        '$hour:$minute $period';
  }
}

class _WordMetric extends StatelessWidget {
  const _WordMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
