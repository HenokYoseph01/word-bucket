import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class ResponsiveSegment<T> {
  const ResponsiveSegment({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// A compact selector whose labels receive real width constraints.
///
/// Flutter's [SegmentedButton] measures its children intrinsically, which is
/// incompatible with AutoSizeText's layout-based sizing. This control keeps
/// the same interaction while remaining safe on narrow and large-text screens.
class ResponsiveSegmentedControl<T> extends StatelessWidget {
  const ResponsiveSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<ResponsiveSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / segments.length;
        final compact = segmentWidth < 104;

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: _SegmentButton<T>(
                    segment: segment,
                    selected: segment.value == selected,
                    compact: compact,
                    onTap: () => onChanged(segment.value),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final ResponsiveSegment<T> segment;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: selected ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 9),
              decoration: BoxDecoration(
                color: selected
                    ? colors.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (segment.icon != null) ...[
                    Icon(
                      segment.icon,
                      size: compact ? 17 : 19,
                      color: foreground,
                    ),
                    SizedBox(width: compact ? 4 : 7),
                  ],
                  Flexible(
                    child: AutoSizeText(
                      segment.label,
                      maxLines: 1,
                      minFontSize: 8,
                      maxFontSize: 14,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
