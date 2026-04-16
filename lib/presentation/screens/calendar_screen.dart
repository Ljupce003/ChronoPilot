
import 'package:chrono_pilot/presentation/models/calendar_view_mode.dart';
import 'package:chrono_pilot/presentation/widgets/day_view.dart';
import 'package:chrono_pilot/presentation/widgets/week_view.dart';
import 'package:chrono_pilot/presentation/widgets/month_view.dart';
import 'package:chrono_pilot/presentation/widgets/year_view.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget{
  const CalendarScreen({super.key});

  @override
  State<StatefulWidget> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarScreen>{

  late CalendarViewMode calendarViewMode;
  late DateTime selectedDay;


  @override
  void initState() {
    super.initState();
    //
    calendarViewMode = CalendarViewMode.day;
    selectedDay = DateTime.now();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildViewModeSelector(),
        actions: [
          IconButton(
            onPressed: setCurrentDay,
            tooltip: 'Today',
            icon: const Icon(Icons.today),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddEvent(context),
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return SegmentedButton<CalendarViewMode>(
      segments: const [
        ButtonSegment(value: CalendarViewMode.day,   label: Text('Day'),   icon: Icon(Icons.view_day)),
        ButtonSegment(value: CalendarViewMode.week,  label: Text('Week'),  icon: Icon(Icons.view_week)),
        ButtonSegment(value: CalendarViewMode.month, label: Text('Month'), icon: Icon(Icons.calendar_view_month)),
        ButtonSegment(value: CalendarViewMode.year,  label: Text('Year'),  icon: Icon(Icons.calendar_today)),
      ],
      selected: {calendarViewMode},
      onSelectionChanged: (Set<CalendarViewMode> selected) {
        final mode = selected.first;
        switch (mode) {
          case CalendarViewMode.day:   selectDay(selectedDay);
          case CalendarViewMode.week:  selectWeek(selectedDay);
          case CalendarViewMode.month: selectMonth(selectedDay);
          case CalendarViewMode.year:  selectYear(selectedDay);
        }
      },
    );
  }

  Widget _buildBody() {
    switch (calendarViewMode) {
      case CalendarViewMode.day:
        return DayView(selected: selectedDay);
      case CalendarViewMode.week:
        return WeekView(selected: selectedDay);
      case CalendarViewMode.month:
        return MonthView(selected: selectedDay);
      case CalendarViewMode.year:
        return YearView(selected: selectedDay);
    }
  }

  void _onAddEvent(BuildContext context) {
    Navigator.pushNamed(context, "/create-event");
  }

  void setCurrentDay(){
    var newSelectedDay = DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day);
    setState(() {
      calendarViewMode = CalendarViewMode.day;
      selectedDay = newSelectedDay;
    });
  }


  void selectDay(DateTime selected){
    var newSelectedDay = DateTime(selected.year,selected.month,selected.day);
    setState(() {
      calendarViewMode = CalendarViewMode.day;
      selectedDay = newSelectedDay;
    });
  }

  void selectMonth(DateTime selected){
    var newSelectedDay = DateTime(selected.year,selected.month);
    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = newSelectedDay;
    });
  }

  void selectWeek(DateTime selected) {
    var newSelectedDay = DateTime(selected.year, selected.month, selected.day);
    int daysSubtract = selected.weekday - 1;
    newSelectedDay = newSelectedDay.subtract(Duration(days: daysSubtract));

    setState(() {
      calendarViewMode = CalendarViewMode.week;
      selectedDay = newSelectedDay;
    });
  }

  void selectYear(DateTime selected) {
    var newSelectedDay = DateTime(selected.year);

    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = newSelectedDay;
    });
  }

  void nextDay(){
    setState(() {
      calendarViewMode = CalendarViewMode.day;
      selectedDay = selectedDay.add(Duration(days: 1));
    });
  }

  void previousDay(){
    setState(() {
      calendarViewMode = CalendarViewMode.day;
      selectedDay = selectedDay.subtract(Duration(days: 1));
    });
  }

  void nextWeek(){
    setState(() {
      calendarViewMode = CalendarViewMode.week;
      selectedDay = selectedDay.add(Duration(days: 7));
    });
  }

  void previousWeek(){
    setState(() {
      calendarViewMode = CalendarViewMode.week;
      selectedDay = selectedDay.subtract(Duration(days: 7));
    });
  }

  void nextMonth(){
    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = DateTime(selectedDay.year,selectedDay.month+1,selectedDay.day);
    });
  }

  void previousMonth(){
    setState(() {
      calendarViewMode = CalendarViewMode.month;
      selectedDay = DateTime(selectedDay.year,selectedDay.month-1,selectedDay.day);
    });
  }

  void nextYear(){
    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = DateTime(selectedDay.year+1);
    });
  }

  void previousYear(){
    setState(() {
      calendarViewMode = CalendarViewMode.year;
      selectedDay = DateTime(selectedDay.year-1);
    });
  }







}




