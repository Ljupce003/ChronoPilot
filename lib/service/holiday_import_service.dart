import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/service/holiday_api_service.dart';

class HolidayImportService {
  final HolidayApiService _api;
  final EventProvider _eventProvider;

  HolidayImportService({
    required HolidayApiService api,
    required EventProvider eventProvider,
  })  : _api = api,
        _eventProvider = eventProvider;

  Future<int> importHolidays({
    required String userId,
    required int year,
    required String countryCode,
    String? countryName,
  }) async {
    final holidays = await _api.getPublicHolidays(year: year, countryCode: countryCode);
    final existingEvents = await _eventProvider.getAllStoredEvents();

    var importedCount = 0;
    for (final holiday in holidays) {
      final title = countryName == null || countryName.isEmpty
          ? holiday.name
          : '${holiday.name} • $countryName';

      final start = DateTime(holiday.date.year, holiday.date.month, holiday.date.day);
      final end = DateTime(holiday.date.year, holiday.date.month, holiday.date.day, 23, 59);

      final alreadyImported = existingEvents.any((event) {
        return event.userId == userId &&
            event.contentType == EventContentType.holiday &&
            event.title == title &&
            event.startDateTime == start &&
            event.endDateTime == end;
      });

      if (alreadyImported) {
        continue;
      }

      await _eventProvider.eventServiceRef.createEvent(
        CreateEventRequest(
          userId: userId,
          title: title,
          description: holiday.localName == holiday.name
              ? null
              : holiday.localName,
          scheduleType: EventScheduleType.oneTime,
          contentType: EventContentType.holiday,
          start: start,
          end: end,
        ),
      );
      importedCount++;
    }

    await _eventProvider.refreshCurrentRange();

    return importedCount;
  }
}

