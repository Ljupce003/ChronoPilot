import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        return _DayEventTile(event: event);
      },
    );
  }
}

class _DayEventTile extends StatelessWidget {
  final EventViewModel event;

  const _DayEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final start = TimeOfDay.fromDateTime(event.startDateTime).format(context);
    final end = TimeOfDay.fromDateTime(event.endDateTime).format(context);

    return ListTile(
      title: Text(event.title),
      subtitle: Text('$start - $end • ${event.type.name}'),
      trailing: event.overrideId != null
          ? const Icon(Icons.edit_calendar, size: 18)
          : null,
    );
  }
}