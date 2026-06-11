import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/repository/auth_provider.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Event list screen
///
/// Provides a paginated/loaded list of stored events. Shows basic metadata
/// (title, schedule/type/subtype and date/time) and lets the user open the
/// details screen or create a new event. Backed by [EventProvider].
///
/// Public widget: [EventListScreen]
class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late Future<List<EventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = context.read<EventProvider>().getAllStoredEvents();
  }


  void _refreshEvents() {
    setState(() {
      _eventsFuture = context.read<EventProvider>().getAllStoredEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Events'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<EventModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load events: ${snapshot.error}'),
            );
          }

          final userId = context.watch<AuthProvider>().userId;
          final isAdmin = (context.watch<AuthProvider>().userEmail ?? '').toLowerCase() == 'admin@chrono.com';
          final events = (snapshot.data ?? [])
            ..retainWhere((e) => isAdmin || (userId != null && e.userId == userId))
            ..sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));

          if (events.isEmpty) {
            return const Center(child: Text('No events yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];

              return Card(
                elevation: 1.5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/event-details',
                      arguments: event.id,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDateTime(event),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              label: 'Schedule',
                              value: _scheduleLabel(event.scheduleType),
                            ),
                            _InfoChip(
                              label: 'Type',
                              value: _contentLabel(event.contentType),
                            ),
                            _InfoChip(
                              label: 'Subtype',
                              value: _subtypeLabel(event.educationSubtype),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-event').then((_) => _refreshEvents());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  DateTime _sortKey(EventModel event) {
    if (event.startDateTime != null) {
      return event.startDateTime!;
    }

    if (event.deadline != null) {
      return event.deadline!;
    }

    final rule = event.recurringRule;
    if (rule != null) {
      final time = _parseHourMinute(rule.startTime);
      return DateTime(
        rule.startDate.year,
        rule.startDate.month,
        rule.startDate.day,
        time.$1,
        time.$2,
      );
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDateTime(EventModel event) {
    final start = _sortKey(event);

    if (event.contentType == EventContentType.todo || event.deadline != null) {
      return 'Deadline: ${_dateText(start)} ${_timeText(start)}';
    }

    final end = event.endDateTime;
    if (end != null) {
      return '${_dateText(start)} ${_timeText(start)} - ${_timeText(end)}';
    }

    return '${_dateText(start)} ${_timeText(start)}';
  }

  String _dateText(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _timeText(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _scheduleLabel(EventScheduleType type) {
    return switch (type) {
      EventScheduleType.oneTime => 'One-time',
      EventScheduleType.recurring => 'Recurring',
    };
  }

  String _contentLabel(EventContentType type) {
    return switch (type) {
      EventContentType.ordinary => 'Ordinary',
      EventContentType.todo => 'Todo',
      EventContentType.education => 'Education',
      EventContentType.holiday => 'Holiday',
      // ignore: unreachable_switch_default
    };
  }

  String _subtypeLabel(EducationSubtype? subtype) {
    if (subtype == null) {
      return '—';
    }

    return switch (subtype) {
      EducationSubtype.lecture => 'Lecture',
      EducationSubtype.lab => 'Lab',
      EducationSubtype.auditory => 'Auditory',
    };
  }

  (int, int) _parseHourMinute(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return (0, 0);
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour, minute);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}