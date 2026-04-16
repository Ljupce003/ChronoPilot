import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().events;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade300,
        title: const Text("Events"),
        centerTitle: true,
      ),

      // -----------------------
      // BODY
      // -----------------------
      body: events.isEmpty
          ? const Center(
        child: Text("No events yet"),
      )
          : ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];

          return ListTile(
            title: Text(e.title),
            subtitle: Text(e.type.name),

            onTap: () {
              Navigator.pushNamed(
                context,
                "/event-details",
                arguments: e.id,
              );
            },
          );
        },
      ),

      // -----------------------
      // FAB (REAL ACTION)
      // -----------------------
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/create-event");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}