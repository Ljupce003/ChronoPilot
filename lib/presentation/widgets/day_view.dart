import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class DayView extends StatelessWidget{

  final DateTime selected;

  const DayView({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {

    var provider = context.read<EventProvider>();

    List<EventModel> events = provider.getEventsForDay(selected);

    // TODO: implement build
    throw UnimplementedError();
  }
  
}