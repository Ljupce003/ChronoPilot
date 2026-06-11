import 'package:chrono_pilot/firebase_options.dart';
import 'package:chrono_pilot/presentation/screens/calendar_screen.dart';
import 'package:chrono_pilot/presentation/screens/create_event_screen.dart';
import 'package:chrono_pilot/presentation/screens/login_screen.dart';
import 'package:chrono_pilot/presentation/screens/profile_screen.dart';
import 'package:chrono_pilot/presentation/screens/event_details_screen.dart';
import 'package:chrono_pilot/presentation/screens/event_list_screen.dart';
import 'package:chrono_pilot/presentation/screens/menu_page.dart';
import 'package:chrono_pilot/repository/auth_provider.dart';
import 'package:chrono_pilot/repository/event_overrides_repository.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:chrono_pilot/utils/app_theme.dart';
import 'package:chrono_pilot/utils/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = EventsRepository();
    final overridesRepository = EventOverridesRepository();
    final themeProvider = ThemeProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider.value(
          value: EventProvider(
            repository: repository,
            overridesRepository: overridesRepository,
          ),
        ),
        ChangeNotifierProvider.value(
          value: themeProvider,
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          return MaterialApp(
            title: 'ChronoPilot',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routes: {
              '/login': (context) => const LoginScreen(),
              '/menu': (context) => const MenuPage(),
              '/events': (context) => const EventListScreen(),
              '/calendar': (context) => const CalendarScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/event-details': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final eventId = args is String
                    ? args
                    : args is Map<String, dynamic> && args['eventId'] is String
                        ? args['eventId'] as String
                        : null;

                if (eventId == null) {
                  return const Scaffold(
                    body: Center(child: Text('Missing event id')),
                  );
                }

                return EventDetailsScreen(eventId: eventId);
              },
              '/create-event': (context) {
                // Optional arguments: { 'initialStart': DateTime }
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
                final initial = args != null && args['initialStart'] is DateTime
                    ? args['initialStart'] as DateTime
                    : null;

                return CreateEventScreen(initialStart: initial);
              },
            },
            initialRoute: authProvider.isAuthenticated ? '/calendar' : '/login',
            home: authProvider.isAuthenticated
                ? const CalendarScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}

