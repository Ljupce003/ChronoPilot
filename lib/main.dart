import 'package:chrono_pilot/presentation/screens/event_list_screen.dart';
import 'package:chrono_pilot/presentation/screens/home_page.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var repository = EventsRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: EventProvider(repository))
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        ),
        routes: {
          "/home": (context) => const MyHomePage(title: "ChronoPilot"),
          // "/calendar": (context) => const CalendarScreen(),
          "/events": (context) => const EventListScreen(),
          // "/create-event": (context) => const CreateEventScreen(),
          "/profile": (context) => const Scaffold(body: Center(child: Text("Profile"))),
        },
        initialRoute: "/home",
      ),
    );
  }
}

