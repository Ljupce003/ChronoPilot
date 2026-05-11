import 'dart:math' as math;

import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeekView extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime>? onDaySelected;

  const WeekView({super.key, required this.selected, this.onDaySelected});

  static const double _hourRowHeight = 80;
  static const double _timeLabelWidth = 64;
  static const double _dayColumnGap = 8;
  static const double _minDayColumnWidth = 160;
  static const double _laneWidth = 140;
  static const double _laneGap = 8;
  static const double _minEventHeight = 28;
  static const double _dayHeaderHeight = 60;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final weekStart = _getWeekStart(selected);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final allEvents = provider.getEventsForWeek(weekStart, weekEnd);

    if (provider.isLoading && allEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allEvents.isEmpty) {
      return const Center(child: Text('No events for this week'));
    }

    final dayColumns = _buildDayColumns(weekStart: weekStart, events: allEvents);
    final totalWidth = _timeLabelWidth + _dayColumnGap +
        dayColumns.fold<double>(0, (sum, column) => sum + column.width) +
        (_dayColumnGap * (dayColumns.length - 1));
    final totalHeight = _dayHeaderHeight + (24 * _hourRowHeight);

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: SingleChildScrollView(
            child: SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: _timeLabelWidth,
                    height: totalHeight,
                    child: _TimeLabelsColumn(
                      headerHeight: _dayHeaderHeight,
                      hourRowHeight: _hourRowHeight,
                    ),
                  ),
                  ..._buildDayColumnWidgets(dayColumns, totalHeight: totalHeight, weekStart: weekStart),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<Widget> _buildDayColumnWidgets(
    List<_DayColumn> dayColumns, {
    required double totalHeight,
    required DateTime weekStart,
  }) {
    final widgets = <Widget>[];
    var left = _timeLabelWidth + _dayColumnGap;

    for (final column in dayColumns) {
      widgets.add(
        Positioned(
          left: left,
          top: 0,
          width: column.width,
          height: totalHeight,
          child: _WeekDayColumn(
            column: column,
            headerHeight: _dayHeaderHeight,
            hourRowHeight: _hourRowHeight,
            laneWidth: _laneWidth,
            minEventHeight: _minEventHeight,
            onTap: onDaySelected == null ? null : () => onDaySelected!(column.dayDate),
          ),
        ),
      );
      left += column.width + _dayColumnGap;
    }

    return widgets;
  }

  List<_DayColumn> _buildDayColumns({
    required DateTime weekStart,
    required List<EventViewModel> events,
  }) {
    final columns = <_DayColumn>[];

    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final dayDate = weekStart.add(Duration(days: dayIndex));
      final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayEvents = events
          .where((event) => event.endDateTime.isAfter(dayStart) && event.startDateTime.isBefore(dayEnd))
          .toList();

      final prepared = <_PreparedEventWeek>[];
      for (var index = 0; index < dayEvents.length; index++) {
        final event = dayEvents[index];
        final clippedStart = event.startDateTime.isBefore(dayStart) ? dayStart : event.startDateTime;
        final clippedEnd = event.endDateTime.isAfter(dayEnd) ? dayEnd : event.endDateTime;

        if (!clippedEnd.isAfter(clippedStart)) continue;

        prepared.add(
          _PreparedEventWeek(
            event: event,
            startMinute: clippedStart.difference(dayStart).inMinutes,
            endMinute: clippedEnd.difference(dayStart).inMinutes,
            originalOrder: index,
          ),
        );
      }

      prepared.sort((a, b) {
        final byStart = a.startMinute.compareTo(b.startMinute);
        if (byStart != 0) return byStart;
        return a.originalOrder.compareTo(b.originalOrder);
      });

      final layouts = <_WeekLayoutEvent>[];
      final active = <_WeekLayoutEvent>[];

      for (final current in prepared) {
        active.removeWhere((item) => item.endMinute <= current.startMinute);

        var laneIndex = 0;
        final usedLanes = active.map((item) => item.laneIndex).toSet();
        while (usedLanes.contains(laneIndex)) {
          laneIndex++;
        }

        final layout = _WeekLayoutEvent(
          event: current.event,
          startMinute: current.startMinute,
          endMinute: current.endMinute,
          laneIndex: laneIndex,
        );

        active.add(layout);
        layouts.add(layout);
      }

      final maxLaneCount = layouts.isEmpty ? 1 : layouts.map((e) => e.laneIndex).reduce(math.max) + 1;
      final columnWidth = math.max(
        _minDayColumnWidth,
        (maxLaneCount * _laneWidth) + ((maxLaneCount - 1) * _laneGap),
      );

      columns.add(
        _DayColumn(
          dayIndex: dayIndex,
          dayDate: dayDate,
          width: columnWidth,
          events: layouts,
          maxLaneCount: maxLaneCount,
        ),
      );
    }

    return columns;
  }
}

class _TimeLabelsColumn extends StatelessWidget {
  final double headerHeight;
  final double hourRowHeight;

  const _TimeLabelsColumn({
    required this.headerHeight,
    required this.hourRowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Column(
      children: [
        SizedBox(height: headerHeight),
        ...List.generate(24, (hour) {
          final label = '${hour.toString().padLeft(2, '0')}:00';
          return SizedBox(
            height: hourRowHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 6, top: 2),
                child: Text(label, style: textStyle),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  final _DayColumn column;
  final double headerHeight;
  final double hourRowHeight;
  final double laneWidth;
  final double minEventHeight;
  final VoidCallback? onTap;

  const _WeekDayColumn({
    required this.column,
    required this.headerHeight,
    required this.hourRowHeight,
    required this.laneWidth,
    required this.minEventHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            children: [
              Container(
                height: headerHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayName(column.dayDate.weekday),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text('${column.dayDate.day}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: List.generate(24, (hour) {
                        return SizedBox(
                          height: hourRowHeight,
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    ...column.events.map((event) {
                      final top = (event.startMinute / 60) * hourRowHeight;
                      final rawHeight = ((event.endMinute - event.startMinute) / 60) * hourRowHeight;
                      final height = math.max(rawHeight, minEventHeight);
                      final left = event.laneIndex * (_WeekViewConstants.laneWidth + _WeekViewConstants.laneGap);

                      return Positioned(
                        top: top,
                        left: left,
                        width: laneWidth,
                        height: height,
                        child: _WeekEventTile(event: event.event),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

class _WeekEventTile extends StatelessWidget {
  final EventViewModel event;

  const _WeekEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final start = TimeOfDay.fromDateTime(event.startDateTime).format(context);
    final end = TimeOfDay.fromDateTime(event.endDateTime).format(context);

    return Card(
      margin: const EdgeInsets.all(1),
      color: Colors.blue.shade50,
      elevation: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isVeryCompact = constraints.maxHeight < 40;
          final isCompact = constraints.maxHeight < 60;

          return Padding(
            padding: EdgeInsets.all(isVeryCompact ? 2 : 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: isVeryCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isVeryCompact ? 10 : 12,
                  ),
                ),
                if (!isVeryCompact)
                  Text(
                    '$start - $end',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: isCompact ? 9 : 10),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PreparedEventWeek {
  final EventViewModel event;
  final int startMinute;
  final int endMinute;
  final int originalOrder;

  const _PreparedEventWeek({
    required this.event,
    required this.startMinute,
    required this.endMinute,
    required this.originalOrder,
  });
}

class _WeekLayoutEvent {
  final EventViewModel event;
  final int startMinute;
  final int endMinute;
  final int laneIndex;

  const _WeekLayoutEvent({
    required this.event,
    required this.startMinute,
    required this.endMinute,
    required this.laneIndex,
  });
}

class _DayColumn {
  final int dayIndex;
  final DateTime dayDate;
  final double width;
  final List<_WeekLayoutEvent> events;
  final int maxLaneCount;

  const _DayColumn({
    required this.dayIndex,
    required this.dayDate,
    required this.width,
    required this.events,
    required this.maxLaneCount,
  });
}

class _WeekViewConstants {
  static const double laneWidth = 140;
  static const double laneGap = 8;
}

