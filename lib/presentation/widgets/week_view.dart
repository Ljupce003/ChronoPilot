import 'dart:math' as math;

import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/utils/app_theme.dart';
import 'package:chrono_pilot/utils/event_classification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';

class WeekView extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime>? onDaySelected;

  const WeekView({super.key, required this.selected, this.onDaySelected});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late final ScrollController _horizontalScrollController;
  late final ScrollController _verticalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  static const double _hourRowHeight = 80;
  static const double _timeLabelWidth = 64;
  static const double _dayColumnGap = 8;
  static const double _minDayColumnWidth = 160;
  static const double _laneWidth = 140;
  static const double _laneGap = 8;
  static const double _dayColumnInnerPadding = 6;
  static const double _minEventHeight = 28;
  static const double _dayHeaderHeight = 60;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final weekStart = _getWeekStart(widget.selected);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final allEvents = provider.getEventsForWeek(weekStart, weekEnd);

    if (provider.isLoading && allEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allEvents.isEmpty) {
      return const Center(child: Text('No events for this week'));
    }

    final dayColumns = _buildDayColumns(weekStart: weekStart, events: allEvents);

    final totalColumnsWidth = dayColumns.fold<double>(0, (sum, column) => sum + column.width);
    final totalWidth = _timeLabelWidth + _dayColumnGap + totalColumnsWidth;

    // FIXED: Capped structural columns directly at 24 hours to hide the 25th row box
    final gridExactHeight = 24 * _hourRowHeight;
    final hoursHeight = (25 * _hourRowHeight) + 40;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        return SizedBox(
          height: viewportHeight,
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                height: viewportHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: _dayHeaderHeight,
                      child: Row(
                        children: [
                          SizedBox(width: _timeLabelWidth),
                          const SizedBox(width: _dayColumnGap),
                          ...dayColumns.map((col) {
                            final headerCell = SizedBox(
                              width: col.width,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
                                    right: BorderSide(color: Theme.of(context).colorScheme.outline),
                                  ),
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _dayName(col.dayDate.weekday),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${col.dayDate.day}',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (widget.onDaySelected == null) return headerCell;
                            return GestureDetector(
                              onTap: () => widget.onDaySelected!(col.dayDate),
                              child: headerCell,
                            );
                          }),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _verticalScrollController,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: SizedBox(
                            height: hoursHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: _timeLabelWidth,
                                  child: _TimeLabelsColumn(
                                    headerHeight: 0,
                                    hourRowHeight: _hourRowHeight,
                                  ),
                                ),
                                const SizedBox(width: _dayColumnGap),
                                ...dayColumns.map((col) {
                                  final bodyCell = SizedBox(
                                      width: col.width,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            height: gridExactHeight,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.surface,
                                                border: Border(
                                                  right: BorderSide(color: Theme.of(context).colorScheme.outline),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(left: _dayColumnInnerPadding),
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Column(
                                                  children: List.generate(
                                                    25,
                                                        (_) => SizedBox(
                                                      height: _hourRowHeight,
                                                      child: Align(
                                                        alignment: Alignment.topCenter,
                                                        child: Divider(
                                                          height: 0,
                                                          thickness: 1,
                                                          color: Theme.of(context).colorScheme.outline,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                ...col.events.map((event) {
                                                  final top = (event.startMinute / 60) * _hourRowHeight;
                                                  final rawHeight = ((event.endMinute - event.startMinute) / 60) * _hourRowHeight;
                                                  final height = math.max(rawHeight, _minEventHeight);
                                                  final left = event.laneIndex * (_laneWidth + _laneGap);

                                                  return Positioned(
                                                    top: top,
                                                    left: left,
                                                    width: _laneWidth,
                                                    height: height,
                                                    child: _WeekEventTile(event: event.event),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ));

                                  if (widget.onDaySelected == null) return bodyCell;
                                  return GestureDetector(
                                    onTap: () => widget.onDaySelected!(col.dayDate),
                                    child: bodyCell,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
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
        (maxLaneCount * _laneWidth) + ((maxLaneCount - 1) * _laneGap) + (2 * _dayColumnInnerPadding),
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

String _dayName(int weekday) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[weekday - 1];
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

        ...List.generate(25, (hour) {
          if (hour == 0) {
            return SizedBox(height: hourRowHeight);
          }

          final safeHour = hour == 24 ? 0 : hour;
          final label = '${safeHour.toString().padLeft(2, '0')}:00';

          return SizedBox(
            height: hourRowHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: FractionalTranslation(
                translation: const Offset(0, -0.5),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    label,
                    style: textStyle,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _WeekEventTile extends StatelessWidget {
  final EventViewModel event;

  const _WeekEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final start = TimeOfDay.fromDateTime(event.startDateTime).format(context);
    final end = TimeOfDay.fromDateTime(event.endDateTime).format(context);

    final isEdu = event.contentType == EventContentType.education && event.educationSubtype !=null;
    final isTodo = event.contentType == EventContentType.todo;

    final accent = isEdu
        ? getColorForCard(event.educationSubtype!)
        : isTodo
        ? AppColors.todo
        : AppColors.ordinary;
    final bgColor = Color.alphaBlend(
      accent.withAlpha((0.22 * 255).round()),
      Theme.of(context).colorScheme.surface,
    );

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/event-details',
          arguments: event.id,
        );
      },
      child: Card(
        margin: const EdgeInsets.fromLTRB(2,1,1,1),
        color: bgColor,
        elevation: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isVeryCompact = constraints.maxHeight < 40;
            final isCompact = constraints.maxHeight < 60;
            final hasSpaceForDetails = constraints.maxHeight >= 80;

            final padding = isVeryCompact
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                : const EdgeInsets.all(8);

            return Padding(
              padding: padding,
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

                  if (hasSpaceForDetails && isEdu && event.educationDetails != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          '${event.educationDetails!.room} • ${event.educationSubtype?.name.toUpperCase() ?? ''}',
                          style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.8 * 255).round())),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
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