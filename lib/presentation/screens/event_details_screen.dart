import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/presentation/screens/edit_event_screen.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/presentation/widgets/event_location_map_card.dart';
import 'package:chrono_pilot/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  void _openEditFlow(BuildContext context, EventViewModel event) {
    final isRecurringOccurrence =
        event.scheduleType == EventScheduleType.recurring &&
        event.recurringEventId != null;

    if (!isRecurringOccurrence) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditEventScreen(event: event),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Recurring Event'),
          content: const Text(
            'Do you want to edit the whole recurring event or make an override for this instance?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventScreen(event: event),
                  ),
                );
              },
              child: const Text('Modify Recurring Event'),
            ),
            TextButton(
               style: TextButton.styleFrom(foregroundColor: AppColors.error),
               onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditEventScreen(event: event, forceSingleOverride: true),
                  ),
                );
              },
              child: const Text('Make Override'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, EventViewModel event) {
    final isRecurring = event.scheduleType == EventScheduleType.recurring ||
        event.recurringEventId != null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Event"),
          content: Text(isRecurring
              ? "This is a recurring event. Do you want to delete only this instance or the entire series?"
              : "Are you sure you want to delete this event?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            if (isRecurring) ...[
              // Option 1: Only this occurrence
              TextButton(
                onPressed: () async {
                  final provider = context.read<EventProvider>();

                  if (event.overrideId != null) {
                    // Revert a modified/cancelled occurrence back to series default.
                    await provider.removeRecurringOverride(event.overrideId!);
                  } else {
                    await provider.cancelRecurringOccurrence(
                      userId: event.userId,
                      recurringEventId: event.recurringEventId!,
                      originalDateTime: event.startDateTime,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to calendar
                  }
                },
                child: const Text("Only this instance"),
              ),
              // Option 2: All occurrences (The series)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  await context
                      .read<EventProvider>()
                      .deleteEvent(event.recurringEventId!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Whole series"),
              ),
            ] else
            // Standard delete for one-time events
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  await context.read<EventProvider>().deleteEvent(event.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Delete"),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cachedEvent = context.watch<EventProvider>().getEventViewModelById(eventId);

    if (cachedEvent != null) {
      return _buildDetailsScaffold(context, cachedEvent);
    }

    return FutureBuilder<EventViewModel?>(
      future: context.read<EventProvider>().getEventViewModelByIdFromStorage(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data;
        if (event == null) {
          return const Scaffold(
            body: Center(child: Text('Event not found')),
          );
        }

        return _buildDetailsScaffold(context, event);
      },
    );
  }

  Scaffold _buildDetailsScaffold(BuildContext context, EventViewModel event) {
    final isTodo = event.contentType == EventContentType.todo;
    final isEducation = event.contentType == EventContentType.education;
    final isHoliday = event.contentType == EventContentType.holiday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (!isHoliday)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _openEditFlow(context, event);
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, event),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Fields (Always visible)
            Text(
              event.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${event.startDateTime.day}/${event.startDateTime.month}/${event.startDateTime.year} • ${_formatTime(event.startDateTime)} - ${_formatTime(event.endDateTime)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (event.location != null) ...[
              _buildSectionHeader('Location'),
              EventLocationMapCard(location: event.location!),
              const SizedBox(height: 24),
            ],

            if (event.imagePath != null) ...[
              _buildSectionHeader('Image'),
              _buildImageCard(context, event.imagePath!),
              const SizedBox(height: 24),
            ],

            if (event.description != null && event.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(event.description!, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 24),
            ],

            // Expanding Todo Fields
            if (isTodo && event.deadline != null) ...[
              _buildSectionHeader('Task Deadline'),
              Card(
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.flag, color: Colors.redAccent),
                  title: Text(
                    '${event.deadline!.day}/${event.deadline!.month}/${event.deadline!.year} ${_formatTime(event.deadline!)}',
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Expanding Education Fields
            if (isEducation && event.educationDetails != null) ...[
              _buildSectionHeader('Class Information'),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                          Icons.class_, 'Course', event.educationDetails!.courseName),
                      const Divider(),
                      _buildDetailRow(Icons.person, 'Professor',
                          event.educationDetails!.professor),
                      const Divider(),
                      _buildDetailRow(
                          Icons.room, 'Room', event.educationDetails!.room),
                      const Divider(),
                      _buildDetailRow(Icons.category, 'Subtype',
                          event.educationSubtype?.name.toUpperCase() ?? 'N/A'),
                      if (event.educationDetails!.studyProgramCode.isNotEmpty) ...[
                        const Divider(),
                        _buildDetailRow(Icons.code, 'Program',
                            event.educationDetails!.studyProgramCode),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildImageCard(BuildContext context, String imagePath) {
    final file = File(imagePath);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: file.existsSync()
            ? Image.file(
                file,
                height: 220,
                fit: BoxFit.cover,
              )
            : Container(
                height: 220,
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, size: 48),
                    SizedBox(height: 8),
                    Text('Image not available'),
                  ],
                ),
              ),
      ),
    );
  }
}