import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hall_provider.dart';
import '../../providers/visit_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/hall_card.dart';
import '../../widgets/loading_widget.dart';
import '../chat/conversations_screen.dart';
import '../notifications/notifications_screen.dart';
import 'browse_halls_screen.dart';
import 'hall_details_screen.dart';
import 'my_bookings_screen.dart';
import 'customer_profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final hallProvider = Provider.of<HallProvider>(context, listen: false);
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      // Load halls
      hallProvider.loadAllHalls();
      hallProvider.loadFeaturedHalls();

      // Load visit requests for customer (old system)
      if (authProvider.currentUser != null) {
        visitProvider.loadCustomerVisits(authProvider.currentUser!.uid);
        chatProvider.loadConversations(authProvider.currentUser!.uid);
        // NEW: Start listening to bookings (new system)
        bookingProvider.startListeningToMyBookings(authProvider.currentUser!.uid);
        // NEW: Start listening to notifications
        Provider.of<NotificationProvider>(context, listen: false)
            .startListening(authProvider.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(searchController: _searchController),
          const BrowseHallsScreen(),
          const MyBookingsScreen(), // NEW: Using new booking screen
          const ConversationsScreen(),
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Visits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final TextEditingController searchController;

  const _HomeTab({required this.searchController});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          final hallProvider = Provider.of<HallProvider>(context, listen: false);
          hallProvider.loadAllHalls();
          await hallProvider.loadFeaturedHalls();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Helpers.getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.name ?? 'Guest',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Notification bell with badge
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, _) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                color: AppTheme.primaryColor,
                              ),
                              if (notifProvider.hasUnread)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      notifProvider.unreadCount > 9
                                          ? '9+'
                                          : '${notifProvider.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Search Bar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BrowseHallsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Text(
                        'Search for halls...',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Pending Visits Section
              Consumer<VisitProvider>(
                builder: (context, visitProvider, _) {
                  final pendingVisits = visitProvider.pendingCustomerVisits;
                  
                  if (pendingVisits.isEmpty) {
                    return const SizedBox.shrink(); // Hide if no pending visits
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Pending Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...pendingVisits.map((visit) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(Icons.pending, color: Colors.orange),
                          ),
                          title: Text(visit.hallName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${visit.visitDate.day}/${visit.visitDate.month}/${visit.visitDate.year} at ${visit.visitTime}\n⏳ Waiting for approval',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Cancel Request?'),
                                  content: const Text('Are you sure you want to cancel this visit request?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Yes', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await visitProvider.cancelVisitRequest(visit.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Visit request cancelled')),
                                  );
                                }
                              }
                            },
                            tooltip: 'Cancel Request',
                          ),
                        ),
                      )).toList(),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 32),
              // Featured Halls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Halls',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BrowseHallsScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<HallProvider>(
                builder: (context, hallProvider, _) {
                  if (hallProvider.featuredHalls.isEmpty) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: hallProvider.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('No featured halls'),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: hallProvider.featuredHalls.length,
                      itemBuilder: (context, index) {
                        final hall = hallProvider.featuredHalls[index];
                        return HallCardCompact(
                          hall: hall,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HallDetailsScreen(hall: hall),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // All Halls
              const Text(
                'All Halls',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer<HallProvider>(
                builder: (context, hallProvider, _) {
                  if (hallProvider.halls.isEmpty) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: hallProvider.isLoading
                            ? const CircularProgressIndicator()
                            : const EmptyStateWidget(
                                icon: Icons.business,
                                title: 'No Halls Available',
                                message: 'Check back later for new listings',
                              ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: hallProvider.halls.length > 5 ? 5 : hallProvider.halls.length,
                    itemBuilder: (context, index) {
                      final hall = hallProvider.halls[index];
                      return HallCard(
                        hall: hall,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HallDetailsScreen(hall: hall),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
