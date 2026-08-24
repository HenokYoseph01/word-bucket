import 'package:flutter/material.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static const releaseId = '1.1.0';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colors.onPrimary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.auto_stories_rounded,
                                color: colors.onPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.tertiaryContainer,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'VERSION 1.1',
                                style: TextStyle(
                                  color: colors.onTertiaryContainer,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Your reading flow just got smoother',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Meet the new ways to collect meanings, review words, and make WordBucket feel like yours.',
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.78),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _NewFeatureCard(
                    icon: Icons.bubble_chart_rounded,
                    title: 'Reading Companion',
                    description:
                        'Keep a small floating book over what you are reading. Copy a word and tap it to Bucketify without returning to the app.',
                    path: 'Settings → Reading Companion → Start reading',
                  ),
                  const _NewFeatureCard(
                    icon: Icons.library_books_rounded,
                    title: 'More than one meaning',
                    description:
                        'Save the meaning you intended now, then return later to collect another meaning of the same word.',
                    path:
                        'Search a saved word again to explore another meaning',
                  ),
                  const _NewFeatureCard(
                    icon: Icons.psychology_alt_rounded,
                    title: 'Clearer, safer reviews',
                    description:
                        'Meanings from the same word are introduced together, then reviewed individually so you always know what you are recalling.',
                    path: 'Progress → Start review',
                  ),
                  const _NewFeatureCard(
                    icon: Icons.palette_rounded,
                    title: 'A new palette gallery',
                    description:
                        'Preview WordBucket Originals and the Robi Pack side by side, with richer light and dark appearances.',
                    path: 'Settings → Appearance → Paper palette',
                  ),
                  const _NewFeatureCard(
                    icon: Icons.delete_sweep_outlined,
                    title: 'A safer word bucket',
                    description:
                        'Definitions collapse for calmer browsing, and deleting a word or an individual meaning now asks for confirmation.',
                    path:
                        'Home → Open a word, or use its trash and swipe actions',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Explore WordBucket 1.1'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewFeatureCard extends StatelessWidget {
  const _NewFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.path,
  });

  final IconData icon;
  final String title;
  final String description;
  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          size: 15,
                          color: colors.onTertiaryContainer,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            path,
                            style: TextStyle(
                              color: colors.onTertiaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
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
