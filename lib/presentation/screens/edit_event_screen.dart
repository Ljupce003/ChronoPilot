import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';
import 'package:chrono_pilot/presentation/models/edit_event_request.dart';
import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/presentation/widgets/image_input_section.dart';
import 'package:chrono_pilot/presentation/widgets/location_input_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditEventScreen extends StatefulWidget {
  final EventViewModel event;
  final bool forceSingleOverride;

  const EditEventScreen({
    super.key,
    required this.event,
    this.forceSingleOverride = false,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {

  EventModel? _event;

  DateTime? originalOccurrenceTime;

  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Education Controllers
  final _courseNameController = TextEditingController();
  final _professorController = TextEditingController();
  final _roomController = TextEditingController();
  final _studyProgramCodeController = TextEditingController();

  late DateTime _start;
  DateTime? _end;
  DateTime? _deadline;

  late EventScheduleType _scheduleType;
  late EventContentType _contentType;
  late EducationSubtype _educationSubtype;
  EventLocation? _location;
  String? _imagePath;

  // Recurring state
  List<int> _selectedDays = [];
  DateTime? _recurringEndDate;

  @override
  void initState() {
    super.initState();
    _start = widget.event.startDateTime;
    _end = widget.event.endDateTime;

    final eventId = widget.event.overrideId != null
        ? widget.event.id
        : (widget.event.recurringEventId ?? widget.event.id);
    _findEventAndFillFields(eventId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _courseNameController.dispose();
    _professorController.dispose();
    _roomController.dispose();
    _studyProgramCodeController.dispose();
    super.dispose();
  }

  // --- Date & Time Pickers ---
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final time = TimeOfDay.fromDateTime(_start);
      setState(() {
        _start = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        if (_end != null && _end!.isBefore(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (picked != null) {
      setState(() {
        _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        );
        if (_end != null && _end!.isBefore(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initial = _end ?? _start.add(const Duration(hours: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final time = TimeOfDay.fromDateTime(initial);
      setState(() {
        _end = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        if (_end!.isBefore(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final initial = _end ?? _start.add(const Duration(hours: 1));
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked != null) {
      setState(() {
        _end = DateTime(
          initial.year,
          initial.month,
          initial.day,
          picked.hour,
          picked.minute,
        );
        if (_end!.isBefore(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final time = TimeOfDay.fromDateTime(_deadline ?? _start);
      setState(() {
        _deadline = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _pickRecurringEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurringEndDate ?? _start.add(const Duration(days: 30)),
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _recurringEndDate = picked;
      });
    }
  }

  Future<void> _saveFromCurrentMode() async {
    if (widget.forceSingleOverride && originalOccurrenceTime != null) {
      await _save(false);
      return;
    }

    if (originalOccurrenceTime != null) {
      await _save(true);
      return;
    }

    await _save(null);
  }

  // --- Save Logic ---
  Future<bool> _save(bool? updateWholeSeries, {bool closeScreen = true}) async {
    if (!_formKey.currentState!.validate()) return false;

    final provider = context.read<EventProvider>();

    // 1. Build Recurring Rule if recurring is selected
    RecurringRule? recurringRule;
    if (_scheduleType == EventScheduleType.recurring) {
      // Fallback: If no days are selected, default to the start day
      final days = _selectedDays.isNotEmpty ? _selectedDays : [_start.weekday];
      recurringRule = RecurringRule(
        daysOfWeek: days,
        startDate: _start,
        endDate: _recurringEndDate,
        startTime:
            '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
        endTime: _end != null
            ? '${_end!.hour.toString().padLeft(2, '0')}:${_end!.minute.toString().padLeft(2, '0')}'
            : null,
      );
    }

    // 2. Build Education Details if education is selected
    EducationDetails? educationDetails;
    if (_contentType == EventContentType.education) {
      educationDetails = EducationDetails(
        courseName: _courseNameController.text.trim(),
        professor: _professorController.text.trim(),
        room: _roomController.text.trim(),
        studyProgramCode: _studyProgramCodeController.text.trim(),
      );
    }

    // 3. Assemble Request
    final request = EditEventRequest(
      userId: 'local-user',
      // Adjust depending on auth
      title: _titleController.text.trim().isEmpty
          ? 'Untitled Event'
          : _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      start: _start,
      end: _end,
      scheduleType: _scheduleType,
      contentType: _contentType,
      deadline: _contentType == EventContentType.todo ? _deadline : null,
      recurringRule: recurringRule,
      educationDetails: educationDetails,
      educationSubtype: _contentType == EventContentType.education
          ? _educationSubtype
          : null,
      location: _location,
      imagePath: _imagePath,
      originalOccurrenceDate: originalOccurrenceTime,
      updateWholeSeries: updateWholeSeries ?? false
    );

    final eventId = _event?.id ?? widget.event.id;
    try {
      await provider.updateEvent(eventId, request);
    } catch (e, st) {
      if (mounted) {
        // Show a simple error snackbar/dialog
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(SnackBar(content: Text('Failed to save event: $e')));
      }
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error updating event: $e\n$st');
      }
      return false;
    }

    if (mounted && closeScreen) Navigator.pop(context);
    return true;
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start'),
                      subtitle: Text(
                        '${_start.day}/${_start.month}/${_start.year} ${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
                      ),
                      onTap: _pickStartDate,
                    ),
                  ),
                  IconButton(
                    onPressed: _pickStartTime,
                    icon: const Icon(Icons.access_time),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('End'),
                      subtitle: Text(
                        _end != null
                            ? '${_end!.day}/${_end!.month}/${_end!.year} ${_end!.hour.toString().padLeft(2, '0')}:${_end!.minute.toString().padLeft(2, '0')}'
                            : 'Not set',
                      ),
                      onTap: _pickEndDate,
                    ),
                  ),
                  IconButton(
                    onPressed: _pickEndTime,
                    icon: const Icon(Icons.access_time),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- SCHEDULE & CONTENT TYPE ---
              DropdownButtonFormField<EventScheduleType>(
                initialValue: _scheduleType,
                items: EventScheduleType.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) => setState(() => _scheduleType = v!),
                decoration: const InputDecoration(labelText: 'Schedule'),
              ),

              // EXPANDING FIELD: Recurring
              if (_scheduleType == EventScheduleType.recurring) ...[
                const SizedBox(height: 16),
                const Text(
                  'Repeat on Days:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: List.generate(7, (index) {
                    final dayNum = index + 1;
                    final isSelected = _selectedDays.contains(dayNum);
                    return FilterChip(
                      label: Text(_dayName(dayNum)),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(dayNum);
                          } else {
                            _selectedDays.remove(dayNum);
                          }
                        });
                      },
                    );
                  }),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeat Until (Optional)'),
                  subtitle: Text(
                    _recurringEndDate != null
                        ? '${_recurringEndDate!.day}/${_recurringEndDate!.month}/${_recurringEndDate!.year}'
                        : 'Forever',
                  ),
                  trailing: _recurringEndDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _recurringEndDate = null),
                        )
                      : null,
                  onTap: _pickRecurringEndDate,
                ),
              ],

              const SizedBox(height: 12),
              DropdownButtonFormField<EventContentType>(
                initialValue: _contentType,
                items: EventContentType.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) => setState(() => _contentType = v!),
                decoration: const InputDecoration(labelText: 'Content Type'),
              ),

              // EXPANDING FIELD: Todo/Task
              if (_contentType == EventContentType.todo) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Deadline'),
                  subtitle: Text(
                    _deadline != null
                        ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year} ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}'
                        : 'Not set',
                  ),
                  onTap: _pickDeadline,
                ),
              ],

              // EXPANDING FIELD: Education
              if (_contentType == EventContentType.education) ...[
                const SizedBox(height: 24),
                const Text(
                  'Education Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(labelText: 'Course Name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _professorController,
                  decoration: const InputDecoration(
                    labelText: 'Professor Name',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room Number/Name',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studyProgramCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Study Program Code',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EducationSubtype>(
                  initialValue: _educationSubtype,
                  items: EducationSubtype.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _educationSubtype = v!),
                  decoration: const InputDecoration(labelText: 'Class Subtype'),
                ),
              ],

              const SizedBox(height: 12),
              LocationInputSection(
                location: _location,
                onChanged: (value) => setState(() => _location = value),
              ),

              const SizedBox(height: 12),
              ImageInputSection(
                imagePath: _imagePath,
                onChanged: (value) => setState(() => _imagePath = value),
              ),

              const SizedBox(height: 24),
              ElevatedButton(onPressed: _saveFromCurrentMode, child: const Text('Save Event')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _findEventAndFillFields(String eventId) async {
    final provider = context.read<EventProvider>();
    final loadedEvent = await provider.repository.getEventById(eventId);
    if (!mounted) return;
    setState(() {
      _event = loadedEvent;
      _titleController.text = loadedEvent.title;
      _descriptionController.text = loadedEvent.description ?? "";
      if(loadedEvent.educationDetails != null){
        _courseNameController.text = loadedEvent.educationDetails!.courseName;
        _professorController.text = loadedEvent.educationDetails!.professor;
        _studyProgramCodeController.text = loadedEvent.educationDetails!.studyProgramCode;
        _roomController.text = loadedEvent.educationDetails!.room;
        _educationSubtype = loadedEvent.educationSubtype ?? EducationSubtype.lecture;
      }
      if(loadedEvent.recurringRule != null){
        _selectedDays = List<int>.from(loadedEvent.recurringRule!.daysOfWeek);
        _recurringEndDate = loadedEvent.recurringRule!.endDate;
      }
      _deadline = loadedEvent.deadline;
      _location = loadedEvent.location;
      _imagePath = loadedEvent.imagePath;

      _contentType = loadedEvent.contentType;
      _scheduleType = loadedEvent.scheduleType;
      _educationSubtype = loadedEvent.educationSubtype ?? EducationSubtype.lecture;

      // Explicit override mode: keep occurrence times and default schedule to
      // one-time so the edit creates an override replacement event.
      if (widget.forceSingleOverride && widget.event.recurringEventId != null) {
        _scheduleType = EventScheduleType.oneTime;
        _selectedDays = [];
        _recurringEndDate = null;
        _start = widget.event.startDateTime;
        _end = widget.event.endDateTime;
      }

      // If the loaded event is a recurring series, show series start/end as
      // the base values when editing the recurring event. This avoids
      // accidentally taking the currently viewed instance time as the
      // series time.
      if (loadedEvent.scheduleType == EventScheduleType.recurring &&
          !widget.forceSingleOverride) {
        _start = loadedEvent.startDateTime ?? _start;
        _end = loadedEvent.endDateTime ?? _end;
      }

      _isLoading = false;
    });

    // If we opened the editor from a recurring occurrence (the incoming
    // `widget.event` carries `recurringEventId`), remember the original
    // occurrence time so the save flow can create an override for that
    // particular instance if requested.
    if (widget.event.recurringEventId != null && widget.event.overrideId == null) {
      originalOccurrenceTime = widget.event.startDateTime;
    }
  }
}
