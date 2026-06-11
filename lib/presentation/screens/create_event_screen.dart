import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';
import 'package:chrono_pilot/repository/auth_provider.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/presentation/widgets/image_input_section.dart';
import 'package:chrono_pilot/presentation/widgets/location_input_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateEventScreen extends StatefulWidget {
  final DateTime? initialStart;

  const CreateEventScreen({super.key, this.initialStart});

  @override
  State<StatefulWidget> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
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

  EventScheduleType _scheduleType = EventScheduleType.oneTime;
  EventContentType _contentType = EventContentType.ordinary;
  EducationSubtype _educationSubtype = EducationSubtype.lecture;
  EventLocation? _location;
  String? _imagePath;

  // Recurring state
  final List<int> _selectedDays = [];
  DateTime? _recurringEndDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = widget.initialStart ?? now;
    _end = _start.add(const Duration(hours: 1));

    // Default to the current day for recurring events initially
    _selectedDays.add(_start.weekday);
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
        _start = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
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
        _start = DateTime(_start.year, _start.month, _start.day, picked.hour, picked.minute);
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
        _end = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
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
        _end = DateTime(initial.year, initial.month, initial.day, picked.hour, picked.minute);
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
        _deadline = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
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

  // --- Save Logic ---
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EventProvider>();
    final userId = context.read<AuthProvider>().userId;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to create events.')),
      );
      return;
    }

    // 1. Build Recurring Rule if recurring is selected
    RecurringRule? recurringRule;
    if (_scheduleType == EventScheduleType.recurring) {
      // Fallback: If no days are selected, default to the start day
      final days = _selectedDays.isNotEmpty ? _selectedDays : [_start.weekday];
      recurringRule = RecurringRule(
        daysOfWeek: days,
        startDate: _start,
        endDate: _recurringEndDate,
        startTime: '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
        endTime: _end != null ? '${_end!.hour.toString().padLeft(2, '0')}:${_end!.minute.toString().padLeft(2, '0')}' : null,
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
    final request = CreateEventRequest(
      userId: userId,
      title: _titleController.text.trim().isEmpty
          ? 'Untitled Event'
          : _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      start: _start,
      end: _end,
      scheduleType: _scheduleType,
      contentType: _contentType,
      deadline: _contentType == EventContentType.todo ? _deadline : null,
      recurringRule: recurringRule,
      educationDetails: educationDetails,
      educationSubtype: _contentType == EventContentType.education ? _educationSubtype : null,
      location: _location,
      imagePath: _imagePath,
    );

    try {
      await provider.createEvent(request);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    }
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
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
                      subtitle: Text('${_start.day}/${_start.month}/${_start.year} ${_start.hour.toString().padLeft(2,'0')}:${_start.minute.toString().padLeft(2,'0')}'),
                      onTap: _pickStartDate,
                    ),
                  ),
                  IconButton(onPressed: _pickStartTime, icon: const Icon(Icons.access_time)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('End'),
                      subtitle: Text(_end != null ? '${_end!.day}/${_end!.month}/${_end!.year} ${_end!.hour.toString().padLeft(2,'0')}:${_end!.minute.toString().padLeft(2,'0')}' : 'Not set'),
                      onTap: _pickEndDate,
                    ),
                  ),
                  IconButton(onPressed: _pickEndTime, icon: const Icon(Icons.access_time)),
                ],
              ),
              const SizedBox(height: 12),

              // --- SCHEDULE & CONTENT TYPE ---
              DropdownButtonFormField<EventScheduleType>(
                initialValue: _scheduleType,
                items: EventScheduleType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                onChanged: (v) => setState(() => _scheduleType = v!),
                decoration: const InputDecoration(labelText: 'Schedule'),
              ),

              // EXPANDING FIELD: Recurring
              if (_scheduleType == EventScheduleType.recurring) ...[
                const SizedBox(height: 16),
                const Text('Repeat on Days:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  subtitle: Text(_recurringEndDate != null
                      ? '${_recurringEndDate!.day}/${_recurringEndDate!.month}/${_recurringEndDate!.year}'
                      : 'Forever'),
                  trailing: _recurringEndDate != null
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _recurringEndDate = null))
                      : null,
                  onTap: _pickRecurringEndDate,
                ),
              ],

              const SizedBox(height: 12),
              DropdownButtonFormField<EventContentType>(
                initialValue: _contentType,
                items: EventContentType.values
                    .where((e) => e != EventContentType.holiday)
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
                  subtitle: Text(_deadline != null ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year} ${_deadline!.hour.toString().padLeft(2,'0')}:${_deadline!.minute.toString().padLeft(2,'0')}' : 'Not set'),
                  onTap: _pickDeadline,
                ),
              ],

              // EXPANDING FIELD: Education
              if (_contentType == EventContentType.education) ...[
                const SizedBox(height: 24),
                const Text('Education Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(labelText: 'Course Name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _professorController,
                  decoration: const InputDecoration(labelText: 'Professor Name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room Number/Name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studyProgramCodeController,
                  decoration: const InputDecoration(labelText: 'Study Program Code'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EducationSubtype>(
                  initialValue: _educationSubtype,
                  items: EducationSubtype.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
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
              ElevatedButton(onPressed: _save, child: const Text('Save Event')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}