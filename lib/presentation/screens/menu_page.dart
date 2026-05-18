import 'package:chrono_pilot/presentation/widgets/home_button.dart';
import 'package:chrono_pilot/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChronoPilot"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
            tooltip: 'Toggle Theme',
            icon: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                );
              },
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO later: navigate to profile
              Navigator.pushNamed(context, "/profile");
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),

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