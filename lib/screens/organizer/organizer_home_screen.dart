import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hall_provider.dart';
import '../../providers/visit_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/hall_card.dart';
import '../../widgets/visit_card.dart';
import '../../widgets/loading_widget.dart';
import 'my_halls_screen.dart';
import 'add_edit_hall_screen.dart';
import 'organizer_bookings_screen.dart';
import 'organizer_profile_screen.dart';
import '../chat/conversations_screen.dart';
import '../notifications/notifications_screen.dart';

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const MyHallsScreen(),
    const OrganizerBookingsScreen(), // NEW: Using new booking screen
    const ConversationsScreen(),
    const OrganizerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Defer data loading to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hallProvider = Provider.of<HallProvider>(context, listen: false);
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (authProvider.user != null) {
      hallProvider.loadOrganizerHalls(authProvider.user!.id);
      visitProvider.loadOrganizerVisits(authProvider.user!.id);
      // NEW: Start listening to bookings (new system)
      bookingProvider.startListeningToOrganizerBookings(authProvider.user!.id);
      // NEW: Start listening to notifications
      Provider.of<NotificationProvider>(context, listen: false)
          .startListening(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'My Halls',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditHallScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Hall'),
            )
          : null,
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          // Notification bell with badge
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (notifProvider.hasUnread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            notifProvider.unreadCount > 9
                                ? '9+'
                                : '${notifProvider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final hallProvider = Provider.of<HallProvider>(context, listen: false);
          final visitProvider = Provider.of<VisitProvider>(context, listen: false);

          if (authProvider.user != null) {
            await Future.wait([
              hallProvider.loadOrganizerHalls(authProvider.user!.id),
              visitProvider.loadOrganizerVisits(authProvider.user!.id),
            ]);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.user;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user?.name ?? 'Organizer',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Statistics Cards
              Consumer2<HallProvider, VisitProvider>(
                builder: (context, hallProvider, visitProvider, _) {
                  final totalHalls = hallProvider.organizerHalls.length;
                  final pendingVisits = visitProvider.organizerVisits.where((v) => v.status.name == 'pending').length;
                  final approvedVisits = visitProvider.organizerVisits.where((v) => v.status.name == 'approved').length;
                  final completedVisits =
                      visitProvider.organizerVisits.where((v) => v.status.name == 'completed').length;

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        title: 'Total Halls',
                        value: totalHalls.toString(),
                        icon: Icons.business,
                        color: AppTheme.primaryColor,
                      ),
                      _StatCard(
                        title: 'Pending',
                        value: pendingVisits.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        title: 'Approved',
                        value: approvedVisits.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: 'Completed',
                        value: completedVisits.toString(),
                        icon: Icons.done_all,
                        color: Colors.blue,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Pending Visits Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to visits tab
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              Consumer<VisitProvider>(
                builder: (context, visitProvider, _) {
                  final pendingVisits =
                      visitProvider.organizerVisits.where((v) => v.status.name == 'pending').take(3).toList();

                  if (visitProvider.isLoading) {
                    return const ShimmerLoading(height: 100, width: double.infinity);
                  }

                  if (pendingVisits.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No pending requests',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: pendingVisits.map((visit) {
                      return VisitCard(
                        visit: visit,
                        isOrganizer: true,
                        onApprove: () => _handleApprove(context, visit.id),
                        onReject: () => _handleReject(context, visit.id),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              // My Halls Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Halls',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to halls tab
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              Consumer<HallProvider>(
                builder: (context, hallProvider, _) {
                  final halls = hallProvider.organizerHalls.take(2).toList();

                  if (hallProvider.isLoading) {
                    return const ShimmerLoading(height: 200, width: double.infinity);
                  }

                  if (halls.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No halls yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your first hall to get started',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditHallScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Hall'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: halls.map((hall) {
                      return HallCardCompact(
                        hall: hall,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditHallScreen(hall: hall),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleApprove(BuildContext context, String visitId) async {
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    try {
      await visitProvider.approveVisitRequest(visitId);
      Helpers.showSuccessSnackbar(context, 'Visit approved!');
    } catch (e) {
      Helpers.showErrorSnackbar(context, 'Failed to approve visit');
    }
  }

  void _handleReject(BuildContext context, String visitId) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Visit'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Enter rejection reason...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null) {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      try {
        await visitProvider.rejectVisitRequest(
          visitId,
          reason: result.isNotEmpty ? result : null,
        );
        Helpers.showSuccessSnackbar(context, 'Visit rejected');
      } catch (e) {
        Helpers.showErrorSnackbar(context, 'Failed to reject visit');
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
