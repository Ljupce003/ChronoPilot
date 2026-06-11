import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class YearView extends StatelessWidget {
  final DateTime selected;

  /// when user taps a month
  final ValueChanged<DateTime>? onMonthSelected;

  const YearView({super.key, required this.selected, this.onMonthSelected});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();

    final yearEvents = provider.getEventsForYear(selected.year);

    if (provider.isLoading && yearEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // _buildYearHeader(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85, // keep but now safe
              ),
              itemBuilder: (context, index) {
                final month = index + 1;

                final isSelectedMonth = selected.month == month;

                final monthEvents = provider.getEventsForMonth(
                  selected.year,
                  month,
                );

                final eventsByDay = _groupEventsByDay(monthEvents);

                return _MonthBox(
                  year: selected.year,
                  month: month,
                  isSelected: isSelectedMonth,
                  eventsByDay: eventsByDay,
                  onTap: onMonthSelected == null
                      ? null
                      : () =>
                            onMonthSelected!(DateTime(selected.year, month, 1)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Year header removed (unused). Kept intentionally empty to avoid unused element warning.

  Map<String, List<EventViewModel>> _groupEventsByDay(
    List<EventViewModel> events,
  ) {
    final grouped = <String, List<EventViewModel>>{};

    for (final event in events) {
      var day = DateTime(
        event.startDateTime.year,
        event.startDateTime.month,
        event.startDateTime.day,
      );

      final endDay = DateTime(
        event.endDateTime.year,
        event.endDateTime.month,
        event.endDateTime.day,
      );

      while (!day.isAfter(endDay)) {
        final key = _dateKey(day);
        grouped.putIfAbsent(key, () => []).add(event);
        day = day.add(const Duration(days: 1));
      }
    }

    return grouped;
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

/* ---------------- MONTH BOX ---------------- */

class _MonthBox extends StatelessWidget {
  final int year;
  final int month;
  final bool isSelected;
  final Map<String, List<EventViewModel>> eventsByDay;
  final VoidCallback? onTap;

  const _MonthBox({
    required this.year,
    required this.month,
    required this.isSelected,
    required this.eventsByDay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);

    final gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - 1),
    );

    final days = <DateTime>[];
    for (
      var d = gridStart;
      !d.isAfter(monthEnd.add(const Duration(days: 7)));
      d = d.add(const Duration(days: 1))
    ) {
      days.add(d);
    }

    final hasHoliday = eventsByDay.values.any(
      (events) => events.any((event) => event.contentType == EventContentType.holiday),
    );
    final boxAccent = hasHoliday ? AppColors.holiday : AppColors.primary;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // HEADER (fixed height)
            SizedBox(
              height: 22,
              child: Center(
                child: Text(
                   _monthName(month),
                   style: TextStyle(
                     fontWeight: FontWeight.w600,
                     color: isSelected ? boxAccent : Theme.of(context).colorScheme.onSurface,
                     fontSize: 12,
                   ),
                 ),
              ),
            ),

            // GRID (takes remaining space safely)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];

                    final inMonth = day.month == month;
                    final hasEvents =
                        (eventsByDay[_dateKey(day)] ?? []).isNotEmpty;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // day number takes top space
                            SizedBox(
                              height: constraints.maxHeight * 0.65,
                              child: Center(
                                 child: Text(
                                   '${day.day}',
                                   style: TextStyle(
                                     fontSize: 8,
                                     height: 1,
                                     color: inMonth
                                            ? Theme.of(context).colorScheme.onSurface
                                            : Theme.of(context).colorScheme.onSurface.withAlpha((0.4 * 255).round()),
                                   ),
                                 ),
                              ),
                            ),

                            // reserved dot zone (always same height)
                            SizedBox(
                              height: constraints.maxHeight * 0.35,
                              child: Center(
                                child: hasEvents
                                     ? Container(
                                         width: 3,
                                         height: 3,
                                          decoration: BoxDecoration(
                                           color: boxAccent,
                                           shape: BoxShape.circle,
                                         ),
                                       )
                                     : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m - 1];
  }
}
