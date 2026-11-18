import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/utils/money.dart';
import '../../../l10n/l10n.dart';
import '../domain/goal.dart';

/// Circular progress ring drawn with theme colors.
class GoalRing extends StatelessWidget {
  const GoalRing({super.key, required this.progress, this.size = 64});
  final GoalProgress progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = progress.achieved ? scheme.tertiary : scheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: progress.displayPercent / 100,
          track: scheme.surfaceContainerHighest,
          color: color,
        ),
        child: Center(
          child: Text(
            '${progress.displayPercent}%',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.color,
  });
  final double fraction;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    if (fraction > 0) {
      final fg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * fraction, false, fg);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.color != color;
}

String goalDeadlineText(AppLocalizations l, GoalWithProgress g) {
  final p = g.progress;
  final date = g.goal.targetDate;
  if (date == null) return l.goalsNoDeadline;
  if (p.achieved) return l.goalsTargetDate(date);
  final d = p.daysLeft!;
  if (d < 0) return l.goalsOverdueBy(-d, date);
  if (d == 0) return l.goalsDueToday(date);
  return l.goalsDaysLeft(d, date);
}

class AchievedBadge extends StatelessWidget {
  const AchievedBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(Icons.check_circle, size: 18, color: scheme.tertiary),
      label: Text(context.l10n.goalsAchieved),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

/// Body shared by the list card and summary card rows.
class GoalProgressBody extends StatelessWidget {
  const GoalProgressBody({super.key, required this.item, this.compact = false});
  final GoalWithProgress item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = item.progress;
    return Row(
      children: [
        GoalRing(progress: p, size: compact ? 52 : 68),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.goal.name,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                context.l10n.goalsProgressOf(
                  formatMinor(p.currentMinor),
                  formatMinor(p.targetMinor),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              if (p.achieved)
                Text(
                  context.l10n.goalsGoalReached,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                )
              else
                Text(
                  context.l10n.goalsRemaining(formatMinor(p.remainingMinor)),
                  style: theme.textTheme.bodySmall,
                ),
              if (!compact) ...[
                Text(
                  goalDeadlineText(context.l10n, item),
                  style: theme.textTheme.bodySmall,
                ),
                if (p.requiredPerMonthMinor != null)
                  Text(
                    context.l10n.goalsSavePerMonth(
                      formatMinor(p.requiredPerMonthMinor!),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
