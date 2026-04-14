import 'package:chrono_pilot/domain/enums/event_type.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late final EventProvider provider;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }


  @override
  void initState() {
    //
    super.initState();

    final repo = EventsRepository();
    provider = EventProvider(repo);

    provider.loadEvents();
  }

  Future<void> _testCreate() async {
    final request = CreateEventRequest(
      userId: "test-user",
      title: "Debug Event",
      type: EventType.single,
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(hours: 1)),
    );

    await provider.createEvent(request);

    debugPrint("CREATED → ${provider.events.length}");
  }

  Future<void> _testRead() async {
    await provider.loadEvents();
    debugPrint("TOTAL EVENTS → ${provider.events.length}");

    for (final e in provider.events) {
      debugPrint("EVENT: ${e.id} | ${e.title}");
    }
  }

  Future<void> _testUpdate() async {
    if (provider.events.isEmpty) return;

    final first = provider.events.first;

    final updatedRequest = CreateEventRequest(
      userId: first.userId,
      title: "UPDATED TITLE",
      type: first.type,
      start: first.startDateTime,
      end: first.endDateTime,
    );

    await provider.updateEvent(first.id, updatedRequest);

    debugPrint("UPDATED → ${first.id}");
  }

  Future<void> _testDelete() async {
    if (provider.events.isEmpty) return;

    final id = provider.events.first.id;

    await provider.deleteEvent(id);

    debugPrint("DELETED → $id");
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(title: const Text("ChronoPilot Debug")),

      body: Column(
        children: [
          ElevatedButton(
            onPressed: _testCreate,
            child: const Text("CREATE"),
          ),
          ElevatedButton(
            onPressed: _testRead,
            child: const Text("READ"),
          ),
          ElevatedButton(
            onPressed: _testUpdate,
            child: const Text("UPDATE"),
          ),
          ElevatedButton(
            onPressed: _testDelete,
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }
}