import 'dart:math' as math;

import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
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

    final timeline = _DayTimeline(
      day: selected,
      events: events,
      provider: provider
    );

    return timeline;
  }
}

class _DayTimeline extends StatelessWidget {
  final DateTime day;
  final List<EventViewModel> events;
  final EventProvider provider;

  const _DayTimeline({required this.day, required this.events, required this.provider});

  static const double _hourRowHeight = 80;
  static const double _timeLabelWidth = 64;
  static const double _laneWidth = 220;
  static const double _laneGap = 10;
  static const double _minEventHeight = 28;

  @override
  Widget build(BuildContext context) {
    final layouts = _buildLayoutEvents(day: day, events: events);
    final laneCount = layouts.isEmpty
        ? 1
        : layouts.map((e) => e.laneIndex).reduce(math.max) + 1;

    final canvasWidth = _timeLabelWidth + (laneCount * (_laneWidth + _laneGap)) + 24;
    final canvasHeight = 24 * _hourRowHeight;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: canvasWidth,
          child: SingleChildScrollView(
            child: SizedBox(
              height: canvasHeight,
              child: Stack(
                children: [
                  _buildHourGrid(context, canvasWidth: canvasWidth),
                  ...layouts.map((item) => _buildPositionedEvent(context, item)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourGrid(BuildContext context, {required double canvasWidth}) {
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Column(
      children: List.generate(24, (hour) {
        final label = '${hour.toString().padLeft(2, '0')}:00';

        return SizedBox(
          height: _hourRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _timeLabelWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    style: textStyle,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPositionedEvent(BuildContext context, _LayoutEvent item) {
    final top = (item.startMinute / 60) * _hourRowHeight;
    final rawHeight = ((item.endMinute - item.startMinute) / 60) * _hourRowHeight;
    final height = math.max(rawHeight, _minEventHeight);
    final left = _timeLabelWidth + (item.laneIndex * (_laneWidth + _laneGap));

    return Positioned(
      top: top,
      left: left,
      width: _laneWidth,
      height: height,
      child: _DayEventTile(event: item.event,provider:provider),
    );
  }

  List<_LayoutEvent> _buildLayoutEvents({
    required DateTime day,
    required List<EventViewModel> events,
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final prepared = <_PreparedEvent>[];

    // Keep original order as a stable tie-breaker for same-start events.
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

      // Earlier index keeps left priority when start time is identical.
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

    // Grab the raw event to access content types and details
    final isEdu = event.contentType == EventContentType.education;
    final isTodo = event.contentType == EventContentType.todo;

    // Color coding based on event type
    final bgColor = isEdu
        ? Colors.deepPurple.shade50
        : isTodo ? Colors.orange.shade50 : Colors.blue.shade50;

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
            final hasSpaceForDetails = constraints.maxHeight >= 110; // New threshold for extra details

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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (!isVeryCompact) const SizedBox(height: 4),
                  if (!isVeryCompact)
                    Text(
                      '$start - $end',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (!isCompact) const SizedBox(height: 2),
                  if (!isCompact)
                    Text(
                      event.scheduleAndContentText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),

                  // Expand to show Education specifics if space allows
                  if (hasSpaceForDetails && isEdu && event.educationDetails != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Class: ${event.educationDetails!.courseName}\n'
                              'Room: ${event.educationDetails!.room}\n'
                              'Prof: ${event.educationDetails!.professor}\n'
                              'Type: ${event.educationSubtype?.name.toUpperCase() ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                          overflow: TextOverflow.fade, // Fades out if it still clips
                        ),
                      ),
                    ),

                  if (!isCompact && event.overrideId != null && !hasSpaceForDetails)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.edit_calendar, size: 16),
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

