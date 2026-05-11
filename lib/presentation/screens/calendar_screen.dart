import 'package:chrono_pilot/presentation/models/calendar_view_mode.dart';
import 'package:chrono_pilot/presentation/widgets/day_view.dart';
import 'package:chrono_pilot/presentation/widgets/week_view.dart';
import 'package:chrono_pilot/presentation/widgets/month_view.dart';
import 'package:chrono_pilot/presentation/widgets/year_view.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
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
      color: Colors.grey.shade100,
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
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  _getDateRangeLabel(),
                  style: const TextStyle(fontSize: 16),
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
        return MonthView(selected: selectedDay);
      case CalendarViewMode.year:
        return YearView(selected: selectedDay);
    }
  }

  void _onAddEvent(BuildContext context) {
    Navigator.pushNamed(context, "/create-event");
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
    var newSelectedDay = DateTime(selected.year, selected.month);
    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = newSelectedDay;
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
    var newSelectedDay = DateTime(selected.year);

    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = newSelectedDay;
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
    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = DateTime(
        selectedDay.year,
        selectedDay.month + 1,
        selectedDay.day,
      );
    });
    _reloadVisibleRange();
  }

  void previousMonth() {
    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = DateTime(
        selectedDay.year,
        selectedDay.month - 1,
        selectedDay.day,
      );
    });
    _reloadVisibleRange();
  }

  void nextYear() {
    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = DateTime(selectedDay.year + 1);
    });
    _reloadVisibleRange();
  }

  void previousYear() {
    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = DateTime(selectedDay.year - 1);
    });
    _reloadVisibleRange();
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

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ).then((pickedDate) {
      if (pickedDate != null) {
        selectDay(pickedDate);
      }
    });
  }
}

