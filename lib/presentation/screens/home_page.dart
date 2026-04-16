import 'package:chrono_pilot/presentation/widgets/home_button.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,

        // -----------------------
        // PROFILE (future)
        // -----------------------
        actions: [
          IconButton(
            onPressed: () {
              // later: navigate to profile
              Navigator.pushNamed(context, "/profile");
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),

      // -----------------------
      // MAIN NAVIGATION
      // -----------------------
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            HomeButton(
              title: "Calendar View",
              icon: Icons.calendar_month,
              onTap: () => Navigator.pushNamed(context, "/calendar"),
            ),

            const SizedBox(height: 16),

            HomeButton(
              title: "Event List",
              icon: Icons.list,
              onTap: () => Navigator.pushNamed(context, "/events"),
            ),

            const SizedBox(height: 16),

            HomeButton(
              title: "Create Event",
              icon: Icons.add,
              onTap: () => Navigator.pushNamed(context, "/create-event"),
            ),
          ],
        ),
      ),
    );
  }
}