import 'dart:math' as math;

import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/utils/app_theme.dart';
import 'package:chrono_pilot/utils/event_classification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/presentation/screens/event_details_screen.dart';

class DayView extends StatelessWidget {
  final DateTime selected;

  const DayView({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final events = provider.getEventsForDay(selected);

    if (provider.isLoading && events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (events.isEmpty) {
      return const Center(child: Text('No events for this day'));
    }

    return _DayTimeline(
      day: selected,
      events: events,
      provider: provider,
    );
  }
}

class _DayTimeline extends StatefulWidget {
  final DateTime day;
  final List<EventViewModel> events;
  final EventProvider provider;

  const _DayTimeline({
    required this.day,
    required this.events,
    required this.provider,
  });

  @override
  State<_DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends State<_DayTimeline> {
  // Explicit controllers for both scroll planes to banish assertion errors
  late final ScrollController _verticalScrollController;
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  static const double _hourRowHeight = 80;
  static const double _timeLabelWidth = 40;
  static const double _laneWidth = 220;
  static const double _laneGap = 10;
  static const double _minEventHeight = 28;
  static const double _bottomPadding = 48;

  @override
  Widget build(BuildContext context) {
    final layouts = _buildLayoutEvents(day: widget.day, events: widget.events);
    final laneCount = layouts.isEmpty
        ? 1
        : layouts.map((e) => e.laneIndex).reduce(math.max) + 1;

    final contentWidth = (laneCount * (_laneWidth + _laneGap)) + 24;
    // Expanded canvas to support 25 timeline dividers smoothly
    final canvasHeight = (25 * _hourRowHeight) + _bottomPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        return SizedBox(
          height: viewportHeight,
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: SizedBox(
                  height: canvasHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: _timeLabelWidth,
                          child: _DayTimeLabelsColumn(
                            hourRowHeight: _hourRowHeight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: SizedBox(
                                width: contentWidth,
                                height: canvasHeight,
                                child: Stack(
                                  children: [
                                    _buildHourGridContent(context),
                                    ...layouts.map(
                                          (item) => _buildPositionedEventContent(context, item),
                                    ),
                                  ],
                                ),
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
          ),
        );
      },
    );
  }

  Widget _buildHourGridContent(BuildContext context) {
    // Generate 25 entries to give us that clean bottom closure line
    return Column(
      children: List.generate(25, (hour) {
        return SizedBox(
          height: _hourRowHeight,
          child: Align(
            alignment: Alignment.topCenter,
            child: Divider(
              height: 0,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPositionedEvent(BuildContext context, _LayoutEvent item) {
    final top = (item.startMinute / 60) * _hourRowHeight;
    final rawHeight = ((item.endMinute - item.startMinute) / 60) * _hourRowHeight;
    final height = math.max(rawHeight, _minEventHeight);
    final left = (item.laneIndex * (_laneWidth + _laneGap)) + 10;

    return Positioned(
      top: top,
      left: left,
      width: _laneWidth,
      height: height,
      child: _DayEventTile(event: item.event, provider: widget.provider),
    );
  }

  Widget _buildPositionedEventContent(BuildContext context, _LayoutEvent item) {
    return _buildPositionedEvent(context, item);
  }

  List<_LayoutEvent> _buildLayoutEvents({
    required DateTime day,
    required List<EventViewModel> events,
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final prepared = <_PreparedEvent>[];

    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      final clippedStart = event.startDateTime.isBefore(dayStart)
          ? dayStart
          : event.startDateTime;
      final clippedEnd = event.endDateTime.isAfter(dayEnd)
          ? dayEnd
          : event.endDateTime;

      if (!clippedEnd.isAfter(clippedStart)) {
        continue;
      }

      final startMinute = clippedStart.difference(dayStart).inMinutes;
      final endMinute = clippedEnd.difference(dayStart).inMinutes;

      prepared.add(
        _PreparedEvent(
          event: event,
          startMinute: startMinute,
          endMinute: endMinute,
          originalOrder: index,
        ),
      );
    }

    prepared.sort((a, b) {
      final byStart = a.startMinute.compareTo(b.startMinute);
      if (byStart != 0) return byStart;
      return a.originalOrder.compareTo(b.originalOrder);
    });

    final result = <_LayoutEvent>[];
    final active = <_LayoutEvent>[];

    for (final current in prepared) {
      active.removeWhere((item) => item.endMinute <= current.startMinute);

      final usedLanes = active.map((item) => item.laneIndex).toSet();
      var laneIndex = 0;
      while (usedLanes.contains(laneIndex)) {
        laneIndex++;
      }

      final layout = _LayoutEvent(
        event: current.event,
        startMinute: current.startMinute,
        endMinute: current.endMinute,
        laneIndex: laneIndex,
      );

      active.add(layout);
      result.add(layout);
    }

    return result;
  }
}

class _DayEventTile extends StatelessWidget {
  final EventViewModel event;

  const _DayEventTile({required this.event, required EventProvider provider});

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(eventId: event.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        color: bgColor,
        elevation: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isVeryCompact = constraints.maxHeight < 56;
            final isCompact = constraints.maxHeight < 84;
            final hasSpaceForDetails = constraints.maxHeight >= 110;

            final padding = isVeryCompact
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                : const EdgeInsets.all(8);

            return Padding(
              padding: padding,
              child: ClipRect(
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
                        fontSize: isVeryCompact ? 12 : 13,
                      ),
                    ),
                    if (!isVeryCompact && constraints.maxHeight > 24) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$start - $end',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 10 : 11,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                        ),
                      ),
                    ],
                    if (!isCompact && constraints.maxHeight > 40) ...[
                      const SizedBox(height: 1),
                      Text(
                        event.scheduleAndContentText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                        ),
                      ),
                    ],

                    if (hasSpaceForDetails && isEdu && event.educationDetails != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: SingleChildScrollView(
                            child: Text(
                              'Class: ${event.educationDetails!.courseName}\n'
                                  'Room: ${event.educationDetails!.room}\n'
                                  'Prof: ${event.educationDetails!.professor}\n'
                                  'Type: ${event.educationSubtype?.name.toUpperCase() ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.8 * 255).round()),
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                    if (!isCompact && event.overrideId != null && !hasSpaceForDetails && constraints.maxHeight > 32)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.edit_calendar, size: 14),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PreparedEvent {
  final EventViewModel event;
  final int startMinute;
  final int endMinute;
  final int originalOrder;

  const _PreparedEvent({
    required this.event,
    required this.startMinute,
    required this.endMinute,
    required this.originalOrder,
  });
}

class _LayoutEvent {
  final EventViewModel event;
  final int startMinute;
  final int endMinute;
  final int laneIndex;

  const _LayoutEvent({
    required this.event,
    required this.startMinute,
    required this.endMinute,
    required this.laneIndex,
  });
}

class _DayTimeLabelsColumn extends StatelessWidget {
  final double hourRowHeight;

  const _DayTimeLabelsColumn({required this.hourRowHeight});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Column(
      children: List.generate(25, (hour) {
        // Skips rendering text elements for the structural index zero placeholder
        if (hour == 0) {
          return SizedBox(height: hourRowHeight);
        }

        // Transforms structural 24-index pointer into trailing 00:00 closure label
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
                child: Text(label, style: textStyle),
              ),
            ),
          ),
        );
      }),
    );
  }
}