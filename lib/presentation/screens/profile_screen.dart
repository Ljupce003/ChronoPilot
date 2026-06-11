import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/repository/auth_provider.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Profile screen
///
/// Shows authenticated user information and simple statistics about their
/// events (tasks, classes, recurring). Also provides a sign-out action.
/// Backed by [AuthProvider] and optionally reads events via
/// [EventsRepository].
///
/// Public widget: [ProfileScreen]
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<EventModel>> _userEventsFuture;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId != null) {
      _userEventsFuture = _loadUserEvents(userId);
    }
  }

  Future<List<EventModel>> _loadUserEvents(String userId) async {
    final events = await EventsRepository().getAllEvents();
    final auth = context.read<AuthProvider>();
    final isAdmin = (auth.userEmail ?? '').toLowerCase() == 'admin@chrono.com';
    return isAdmin ? events : events.where((e) => e.userId == userId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<EventModel>>(
        future: _userEventsFuture,
        builder: (context, snapshot) {
          final events = snapshot.data ?? [];
          final isAdmin = (context.watch<AuthProvider>().userEmail ?? '').toLowerCase() == 'admin@chrono.com';

          // Count events by type
          final visibleEvents = isAdmin ? events : events.where((e) => e.userId == user.uid).toList();
          final totalEvents = visibleEvents.length;
          final todoCount = visibleEvents.where((e) => e.contentType == EventContentType.todo).length;
          final educationCount = visibleEvents.where((e) => e.contentType == EventContentType.education).length;
          final recurringCount = visibleEvents.where((e) => e.scheduleType.name == 'recurring').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Information',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _buildUserInfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: user.email ?? 'No email',
                        ),
                        const SizedBox(height: 12),
                        _buildUserInfoRow(
                          icon: Icons.account_circle,
                          label: 'User ID',
                          value: '${user.uid.substring(0, 12)}...',
                        ),
                        const SizedBox(height: 12),
                        _buildUserInfoRow(
                          icon: Icons.check_circle,
                          label: 'Email Verified',
                          value: user.emailVerified ? 'Yes' : 'No',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Section
                Text(
                  'Event Statistics',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      context: context,
                      label: 'Total Events',
                      value: totalEvents,
                      icon: Icons.event,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      context: context,
                      label: 'Tasks',
                      value: todoCount,
                      icon: Icons.check_box,
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      context: context,
                      label: 'Classes',
                      value: educationCount,
                      icon: Icons.school,
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      context: context,
                      label: 'Recurring',
                      value: recurringCount,
                      icon: Icons.repeat,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed ?? false) {
                        final navigator = Navigator.of(context, rootNavigator: true);
                        await authProvider.signOut();
                        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

