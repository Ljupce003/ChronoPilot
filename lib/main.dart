import 'package:chrono_pilot/presentation/screens/calendar_screen.dart';
import 'package:chrono_pilot/presentation/screens/event_list_screen.dart';
import 'package:chrono_pilot/presentation/screens/menu_page.dart';
import 'package:chrono_pilot/repository/event_overrides_repository.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = EventsRepository();
    final overridesRepository = EventOverridesRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: EventProvider(
            repository: repository,
            overridesRepository: overridesRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        routes: {
          '/menu': (context) => const MenuPage(),
          '/events': (context) => const EventListScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/profile':
              (context) => const Scaffold(body: Center(child: Text('Profile'))),
          '/create-event': (context) => const Text("Create event"),
        },
        initialRoute: '/calendar',
      ),
    );
  }
}

