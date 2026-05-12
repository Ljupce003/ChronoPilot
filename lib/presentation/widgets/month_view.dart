import 'dart:ffi';

import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class MonthView extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime>? onDaySelected;

  const MonthView({
    super.key,
    required this.selected,
    this.onDaySelected,
  });

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  DateTime? animatingDay;

  Future<void> _handleDayTap(DateTime day) async {
    setState(() {
      animatingDay = day;
    });

    await Future.delayed(const Duration(milliseconds: 180));

    if (mounted && widget.onDaySelected != null) {
      widget.onDaySelected!(day);
    }

    if (mounted) {
      setState(() {
        animatingDay = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final monthEvents = provider.getEventsForMonth(
      widget.selected.year,
      widget.selected.month,
    );

    if (provider.isLoading && monthEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final monthStart = DateTime(
      widget.selected.year,
      widget.selected.month,
      1,
    );

    final monthEnd = DateTime(
      widget.selected.year,
      widget.selected.month + 1,
      1,
    );

    final gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - 1),
    );

    final gridEnd = _lastVisibleDay(monthEnd);

    final visibleDays = <DateTime>[];

    for (
    var day = gridStart;
    !day.isAfter(gridEnd);
    day = day.add(const Duration(days: 1))
    ) {
      visibleDays.add(day);
    }

    final eventsByDay = _groupEventsByDay(monthEvents);

    return Column(
      children: [
        _buildWeekdayHeader(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.92,
            ),
            itemCount: visibleDays.length,
            itemBuilder: (context, index) {
              final day = visibleDays[index];

              final isCurrentMonth =
                  day.month == widget.selected.month;

              final isSelected =
              _isSameDay(day, widget.selected);

              final isAnimating =
                  animatingDay != null &&
                      _isSameDay(day, animatingDay!);

              final events =
                  eventsByDay[_dateKey(day)] ??
                      const <EventViewModel>[];

              return _MonthDayCell(
                day: day,
                isCurrentMonth: isCurrentMonth,
                isSelected: isSelected,
                isAnimating: isAnimating,
                events: events,
                onTap: isCurrentMonth &&
                    widget.onDaySelected != null
                    ? () => _handleDayTap(day)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        children: labels
            .map(
              (label) => Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Map<String, List<EventViewModel>> _groupEventsByDay(
      List<EventViewModel> events,
      ) {
    final grouped = <String, List<EventViewModel>>{};

    for (final event in events) {
      var day = DateTime(
        event.startDateTime.year,
        event.startDateTime.month,
        event.startDateTime.day,
      );

      final endDay = DateTime(
        event.endDateTime.year,
        event.endDateTime.month,
        event.endDateTime.day,
      );

      while (!day.isAfter(endDay)) {
        final key = _dateKey(day);

        grouped
            .putIfAbsent(
          key,
              () => <EventViewModel>[],
        )
            .add(event);

        day = day.add(const Duration(days: 1));
      }
    }

    return grouped;
  }

  DateTime _lastVisibleDay(DateTime monthEnd) {
    final lastDayOfMonth =
    monthEnd.subtract(const Duration(days: 1));

    final daysUntilSunday =
        7 - lastDayOfMonth.weekday;

    return lastDayOfMonth.add(
      Duration(days: daysUntilSunday),
    );
  }

  String _dateKey(DateTime day) =>
      '${day.year}-${day.month}-${day.day}';

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isAnimating;
  final List<EventViewModel> events;
  final VoidCallback? onTap;

  const _MonthDayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isAnimating,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrentMonth
        ? Colors.black87
        : Colors.grey.shade400;

    final hasEvents = events.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isAnimating
                ? Colors.blue.shade100
                : isSelected
                ? Colors.blue.shade50
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isAnimating
                  ? Colors.blueAccent
                  : isSelected
                  ? Colors.blue
                  : Colors.grey.shade300,
              width: isAnimating
                  ? 3
                  : (isSelected ? 1.5 : 1),
            ),
            boxShadow: isAnimating
                ? [
              BoxShadow(
                color: Colors.blue.withAlpha(64),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showMarkers =
                  hasEvents &&
                      constraints.maxHeight >= 28;

              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize:
                        constraints.maxHeight < 36
                            ? 11
                            : 12,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (showMarkers)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _MonthEventMarkers(
                        count: events.length,
                        color: isCurrentMonth
                            ? Colors.blue
                            : Colors.grey.shade400,
                        compact:
                        constraints.maxHeight < 40,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MonthEventMarkers extends StatelessWidget {
  final int count;
  final Color color;
  final bool compact;

  const _MonthEventMarkers({
    required this.count,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = count > 3 ? 3 : count;

    final dotSize = compact ? 4.0 : 5.0;
    final spacing = compact ? 1.0 : 2.0;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < visibleCount; i++)
              Padding(
                padding: EdgeInsets.only(right: spacing),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (count > 3)
              Padding(
                padding: EdgeInsets.only(left: spacing),
                child: Container(
                  width: compact ? 8 : 10,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}