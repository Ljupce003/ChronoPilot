import 'package:chrono_pilot/presentation/models/calendar_view_mode.dart';
import 'package:chrono_pilot/presentation/widgets/day_view.dart';
import 'package:chrono_pilot/presentation/widgets/week_view.dart';
import 'package:chrono_pilot/presentation/widgets/month_view.dart';
import 'package:chrono_pilot/presentation/widgets/year_view.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<StatefulWidget> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarScreen> {
  late CalendarViewMode calendarViewMode;
  late DateTime selectedDay;

  @override
  void initState() {
    super.initState();
    calendarViewMode = CalendarViewMode.day;
    selectedDay = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadVisibleRange();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/menu'),
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
        ),
        title: SizedBox(
          height: 36,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _buildViewModeSelector(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: setCurrentDay,
            tooltip: 'Today',
            icon: const Icon(Icons.today),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildNavigationBar(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddEvent(context),
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _cyclePrevious,
            tooltip: 'Previous',
            icon: const Icon(Icons.navigate_before),
            iconSize: 24,
          ),
           if (calendarViewMode == CalendarViewMode.day)
             TextButton(
               onPressed: _showDatePicker,
               child: Text(
                 '${selectedDay.day} / ${selectedDay.month} / ${selectedDay.year}',
                 style: TextStyle(
                   color: Theme.of(context).colorScheme.onSurface,
                   fontSize: 16,
                 ),
               ),
             )
          else
            Expanded(
              child: Center(
                 child: calendarViewMode == CalendarViewMode.month
                     ? TextButton(
                   onPressed: _showMonthPicker,
                   child: Text(
                     _getDateRangeLabel(),
                     style: TextStyle(
                       fontSize: 16,
                       color: Theme.of(context).colorScheme.onSurface,
                     ),
                   ),
                 )
                     : Text(
                   _getDateRangeLabel(),
                   style: TextStyle(
                     fontSize: 16,
                     color: Theme.of(context).colorScheme.onSurface,
                   ),
                 ),
              ),
            ),
          IconButton(
            onPressed: _cycleNext,
            tooltip: 'Next',
            icon: const Icon(Icons.navigate_next),
            iconSize: 24,
          ),
        ],
      ),
    );
  }

  String _getDateRangeLabel() {
    return switch (calendarViewMode) {
      CalendarViewMode.day => '${selectedDay.day} / ${selectedDay.month} / ${selectedDay.year}',
      CalendarViewMode.week => 'Week of ${selectedDay.day} / ${selectedDay.month}',
      CalendarViewMode.month => '${_getMonthName(selectedDay.month)} ${selectedDay.year}',
      CalendarViewMode.year => '${selectedDay.year}',
    };
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  Widget _buildViewModeSelector() {
    return SegmentedButton<CalendarViewMode>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
      ),
      segments: const [
        ButtonSegment(value: CalendarViewMode.day, label: Text('Day')),
        ButtonSegment(value: CalendarViewMode.week, label: Text('Week')),
        ButtonSegment(value: CalendarViewMode.month, label: Text('Month')),
        ButtonSegment(value: CalendarViewMode.year, label: Text('Year')),
      ],
      selected: {calendarViewMode},
      onSelectionChanged: (Set<CalendarViewMode> selected) {
        final mode = selected.first;
        final today = DateTime.now();
        switch (mode) {
          case CalendarViewMode.day:
            selectDay(today);
          case CalendarViewMode.week:
            selectWeek(today);
          case CalendarViewMode.month:
            selectMonth(today);
          case CalendarViewMode.year:
            selectYear(today);
        }
      },
    );
  }

  Widget _buildBody() {
    switch (calendarViewMode) {
      case CalendarViewMode.day:
        return DayView(selected: selectedDay);
      case CalendarViewMode.week:
        return WeekView(
          selected: selectedDay,
          onDaySelected: selectDay,
        );
      case CalendarViewMode.month:
        return MonthView(
          selected: selectedDay,
          onDaySelected: selectDay,
        );
      case CalendarViewMode.year:
        return YearView(
          selected: selectedDay,
          onMonthSelected: selectMonth,
        );
    }
  }

  Future<void> _showMonthPicker() async {
    int selectedYear = selectedDay.year;
    int selectedMonth = selectedDay.month;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              child: SizedBox(
                width: 340,
                height: 500,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                selectedYear--;
                              });
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '$selectedYear',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                selectedYear++;
                              });
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 12,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2,
                        ),
                        itemBuilder: (context, index) {
                          final month = index + 1;

                          final isSelected =
                              month == selectedMonth &&
                                  selectedYear ==
                                      selectedDay.year;

                           return InkWell(
                             borderRadius:
                             BorderRadius.circular(12),
                             onTap: () {
                               Navigator.pop(
                                 context,
                                 DateTime(
                                   selectedYear,
                                   month,
                                 ),
                               );
                             },
                             child: AnimatedContainer(
                               duration:
                               const Duration(milliseconds: 150),
                               decoration: BoxDecoration(
                                 color: isSelected
                                     ? AppColors.primary.withAlpha((0.2 * 255).round())
                                     : Theme.of(context).colorScheme.surface,
                                 borderRadius:
                                 BorderRadius.circular(12),
                                 border: Border.all(
                                   color: isSelected
                                       ? AppColors.primary
                                       : Theme.of(context).colorScheme.outline,
                                   width: isSelected ? 2 : 1,
                                 ),
                               ),
                               child: Center(
                                 child: Text(
                                   _getMonthName(month),
                                   textAlign: TextAlign.center,
                                   style: TextStyle(
                                     fontWeight: isSelected
                                         ? FontWeight.w600
                                         : FontWeight.normal,
                                     color: Theme.of(context).colorScheme.onSurface,
                                   ),
                                 ),
                               ),
                             ),
                           );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      selectMonth(picked);
    }
  }

  void _onAddEvent(BuildContext context) {
    DateTime initialStart;

    switch (calendarViewMode) {
      case CalendarViewMode.day:
        initialStart = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
        break;
      case CalendarViewMode.week:
        // selectedDay is start of week
        initialStart = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
        break;
      case CalendarViewMode.month:
        initialStart = DateTime(
          selectedDay.year,
          selectedDay.month,
          1,
          DateTime.now().hour,
          DateTime.now().minute,
        );
        break;
      case CalendarViewMode.year:
        initialStart = DateTime(
          selectedDay.year,
          1,
          1,
          DateTime.now().hour,
          DateTime.now().minute,
        );
        break;
    }

    Navigator.pushNamed(context, "/create-event", arguments: {'initialStart': initialStart});
  }

  void setCurrentDay() {
    var newSelectedDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    setState(() {
      calendarViewMode = CalendarViewMode.day;
      selectedDay = newSelectedDay;
    });
    _reloadVisibleRange();
  }

  void selectDay(DateTime selected) {
    var newSelectedDay = DateTime(selected.year, selected.month, selected.day);
    setState(() {
      calendarViewMode = CalendarViewMode.day;
      selectedDay = newSelectedDay;
    });
    _reloadVisibleRange();
  }

  void selectMonth(DateTime selected) {
    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = _resolveMonthSelection(selected);
    });

    _reloadVisibleRange();
  }

  void selectWeek(DateTime selected) {
    var newSelectedDay = DateTime(selected.year, selected.month, selected.day);
    int daysSubtract = selected.weekday - 1;
    newSelectedDay = newSelectedDay.subtract(Duration(days: daysSubtract));

    setState(() {
      calendarViewMode = CalendarViewMode.week;
      selectedDay = newSelectedDay;
    });
    _reloadVisibleRange();
  }

  void selectYear(DateTime selected) {
    final target = DateTime(selectedDay.year);

    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = _resolveYearSelection(target);
    });
    _reloadVisibleRange();
  }

  void nextDay() {
    setState(() {
      calendarViewMode = CalendarViewMode.day;
      selectedDay = selectedDay.add(const Duration(days: 1));
    });
    _reloadVisibleRange();
  }

  void previousDay() {
    setState(() {
      calendarViewMode = CalendarViewMode.day;
      selectedDay = selectedDay.subtract(const Duration(days: 1));
    });
    _reloadVisibleRange();
  }

  void nextWeek() {
    setState(() {
      calendarViewMode = CalendarViewMode.week;
      selectedDay = selectedDay.add(const Duration(days: 7));
    });
    _reloadVisibleRange();
  }

  void previousWeek() {
    setState(() {
      calendarViewMode = CalendarViewMode.week;
      selectedDay = selectedDay.subtract(const Duration(days: 7));
    });
    _reloadVisibleRange();
  }

  void nextMonth() {
    final target = DateTime(
      selectedDay.year,
      selectedDay.month + 1,
    );

    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = _resolveMonthSelection(target);
    });

    _reloadVisibleRange();
  }

  void previousMonth() {
    final target = DateTime(
      selectedDay.year,
      selectedDay.month - 1,
    );

    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = _resolveMonthSelection(target);
    });

    _reloadVisibleRange();
  }

  void nextYear() {
    final target = DateTime(
      selectedDay.year + 1,
    );
    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = _resolveYearSelection(target);
    });
    _reloadVisibleRange();
  }

  void previousYear() {
    final target = DateTime(
      selectedDay.year - 1,
    );
    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = _resolveYearSelection(target);
    });
    _reloadVisibleRange();
  }

  DateTime _resolveMonthSelection(DateTime targetMonth) {
    final today = DateTime.now();

    final isCurrentMonth =
        today.year == targetMonth.year &&
            today.month == targetMonth.month;

    return DateTime(
      targetMonth.year,
      targetMonth.month,
      isCurrentMonth ? today.day : 1,
    );
  }

  DateTime _resolveYearSelection(DateTime targetMonth) {
    final today = DateTime.now();

    final isCurrentYear =
        today.year == targetMonth.year;

    return DateTime(
      targetMonth.year,
      isCurrentYear ? today.month : 1,
    );
  }



  void _reloadVisibleRange() {
    final provider = context.read<EventProvider>();

    late final DateTime start;
    late final DateTime end;

    switch (calendarViewMode) {
      case CalendarViewMode.day:
        start = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        end = start.add(const Duration(days: 1));
        break;
      case CalendarViewMode.week:
        start = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        end = start.add(const Duration(days: 7));
        break;
      case CalendarViewMode.month:
        start = DateTime(selectedDay.year, selectedDay.month, 1);
        end = DateTime(selectedDay.year, selectedDay.month + 1, 1);
        break;
      case CalendarViewMode.year:
        start = DateTime(selectedDay.year, 1, 1);
        end = DateTime(selectedDay.year + 1, 1, 1);
        break;
    }

    provider.loadEvents(rangeStart: start, rangeEnd: end);
  }

  void _cycleNext() {
    switch (calendarViewMode) {
      case CalendarViewMode.day:
        return nextDay();
      case CalendarViewMode.week:
        return nextWeek();
      case CalendarViewMode.month:
        return nextMonth();
      case CalendarViewMode.year:
        return nextYear();
    }
  }

  void _cyclePrevious() {
    switch (calendarViewMode) {
      case CalendarViewMode.day:
        return previousDay();
      case CalendarViewMode.week:
        return previousWeek();
      case CalendarViewMode.month:
        return previousMonth();
      case CalendarViewMode.year:
        return previousYear();
    }
  }

  void _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      selectDay(pickedDate);
    }
  }
}

