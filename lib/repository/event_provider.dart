import 'package:chrono_pilot/service/event_service.dart';
import 'package:flutter/foundation.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';

class EventProvider extends ChangeNotifier {
  final EventsRepository repository;
  late final EventService service;

  EventProvider(this.repository) {
    service = EventService(repository);
  }

  List<EventModel> _events = [];

  List<EventModel> get events => List.unmodifiable(_events);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // -----------------------
  // INIT (load once from DB)
  // -----------------------
  Future<void> loadEvents() async {

    _isLoading = true;
    notifyListeners();

    _events = await repository.getAllEvents();

    print("PROVIDER SIZE → ${_events.length}");

    _isLoading = false;
    notifyListeners();
  }

  // -----------------------
  // CREATE
  // -----------------------
  Future<void> createEvent(CreateEventRequest request) async {
    // await service.createEvent(request);

    final newEvent = await service.createEvent(request);

    _events.add(newEvent);
    notifyListeners();
  }

  // -----------------------
  // UPDATE
  // -----------------------
  Future<void> updateEvent(String id, CreateEventRequest request) async {
    await service.updateEvent(id, request);

    final index = _events.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final updated = await repository.getEventById(id);

    _events[index] = updated;
    notifyListeners();
  }

  // -----------------------
  // DELETE
  // -----------------------
  Future<void> deleteEvent(String id) async {
    await service.deleteEvent(id);

    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // -----------------------
  // READ HELPERS (NO DB CALLS)
  // -----------------------

  List<EventModel> getEventsForDay(DateTime day) {
    return _events.where((e) {
      if (e.startDateTime != null) {
        final d = e.startDateTime!;
        return d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }
      return false;
    }).toList();
  }

  List<EventModel> getEventsForWeek(DateTime startOfWeek, DateTime endOfWeek) {
    return _events.where((e) {
      if (e.startDateTime != null) {
        final d = e.startDateTime!;
        return d.isAfter(startOfWeek) && d.isBefore(endOfWeek);
      }
      return false;
    }).toList();
  }

  List<EventModel> getEventsForMonth(int year, int month) {
    return _events.where((e) {
      if (e.startDateTime != null) {
        return e.startDateTime!.year == year &&
            e.startDateTime!.month == month;
      }
      return false;
    }).toList();
  }

  // // -----------------------
  // // INTERNAL SAFETY HELPERS
  // // -----------------------
  //
  // Future<EventModel> _findLatestEventFromDbOrBuild(CreateEventRequest r) async {
  //   // safest option: re-fetch last inserted event if needed
  //   final all = await repository.getAllEvents();
  //   return all.last;
  // }
}