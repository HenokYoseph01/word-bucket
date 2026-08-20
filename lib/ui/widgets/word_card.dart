import 'package:flutter/material.dart';

import '../../data/database/database.dart';
import '../../data/models/word_model.dart';
import 'part_of_speech_badge.dart';

class WordCard extends StatefulWidget {
  const WordCard({
    required this.word,
    this.meanings = const [],
    this.onSave,
    this.onDeleteWord,
    this.onDeleteMeaning,
    this.onConfirmMeaningDismiss,
    this.onMeaningDismissed,
    super.key,
  });

  final WordModel word;
  final List<SavedMeaning> meanings;
  final VoidCallback? onSave;
  final VoidCallback? onDeleteWord;
  final ValueChanged<SavedMeaning>? onDeleteMeaning;
  final Future<bool> Function(SavedMeaning)? onConfirmMeaningDismiss;
  final ValueChanged<SavedMeaning>? onMeaningDismissed;

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final count = widget.meanings.isEmpty ? 1 : widget.meanings.length;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.word.word,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.word.phonetic != null)
                    Text(
                      widget.word.phonetic!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 6),
                  if (widget.onDeleteWord != null)
                    IconButton(
                      tooltip: 'Remove ${widget.word.word}',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onDeleteWord,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colors.error,
                      ),
                    ),
                  AnimatedRotation(
                    turns: _expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.bookmarks_rounded,
                    size: 17,
                    color: colors.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count saved ${count == 1 ? 'meaning' : 'meanings'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _expanded ? 'Hide definitions' : 'Show definitions',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: widget.meanings.isEmpty
                              ? [_legacyMeaning(context)]
                              : [
                                  for (
                                    var index = 0;
                                    index < widget.meanings.length;
                                    index++
                                  ) ...[
                                    _meaning(context, widget.meanings[index]),
                                    if (index != widget.meanings.length - 1)
                                      const SizedBox(height: 10),
                                  ],
                                ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              if (widget.onSave != null && _expanded) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onSave,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save to Bucket'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _meaning(BuildContext context, SavedMeaning meaning) {
    final surface = _meaningSurface(
      context,
      partOfSpeech: meaning.partOfSpeech,
      definition: meaning.definition,
      example: meaning.exampleSentence,
      savedAt: meaning.savedAt,
      onDelete: widget.onDeleteMeaning == null
          ? null
          : () => widget.onDeleteMeaning!(meaning),
    );
    if (widget.meanings.length <= 1 ||
        widget.onConfirmMeaningDismiss == null ||
        widget.onMeaningDismissed == null) {
      return surface;
    }
    return Dismissible(
      key: ValueKey('meaning-${meaning.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => widget.onConfirmMeaningDismiss!(meaning),
      onDismissed: (_) => widget.onMeaningDismissed!(meaning),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: surface,
    );
  }

  Widget _legacyMeaning(BuildContext context) {
    return _meaningSurface(
      context,
      partOfSpeech: widget.word.partOfSpeech,
      definition: widget.word.definition,
      example: widget.word.exampleSentence,
      savedAt: widget.word.savedAt,
      onDelete: widget.onDeleteWord,
    );
  }

  Widget _meaningSurface(
    BuildContext context, {
    required String partOfSpeech,
    required String definition,
    required String? example,
    required DateTime savedAt,
    required VoidCallback? onDelete,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PartOfSpeechBadge(label: partOfSpeech),
              const Spacer(),
              Text(
                'Saved ${_date(savedAt)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Remove this meaning',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: colors.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            definition,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          if (example != null) ...[
            const SizedBox(height: 9),
            Text(
              '“$example”',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _date(DateTime value) {
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}
