import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../chat/chat_screen.dart';

/// Enterprise-grade "My Bookings" screen for customers.
/// Airbnb-quality UI with real-time updates via Firestore streams.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Start listening to bookings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        bookingProvider.startListeningToMyBookings(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myBookings.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingsList(
                bookings: provider.upcomingBookings,
                isUpcoming: true,
                emptyIcon: Icons.event_available,
                emptyTitle: 'No upcoming bookings',
                emptySubtitle: 'When you book a venue, it will appear here',
              ),
              _BookingsList(
                bookings: [...provider.pastBookings, ...provider.cancelledBookings]
                  ..sort((a, b) => b.startAt.compareTo(a.startAt)),
                isUpcoming: false,
                emptyIcon: Icons.history,
                emptyTitle: 'No past bookings',
                emptySubtitle: 'Your booking history will show here',
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Scrollable list of bookings
class _BookingsList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool isUpcoming;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _BookingsList({
    required this.bookings,
    required this.isUpcoming,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(
          booking: bookings[index],
          isUpcoming: isUpcoming,
        );
      },
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium booking card with Airbnb-quality design
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isUpcoming;

  const _BookingCard({
    required this.booking,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = booking.isPast;
    final isCancelled = booking.isCancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image header with status badge
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                // Venue image
                Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: booking.venueImageUrl.isNotEmpty
                      ? Image.network(
                          booking.venueImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Venue name
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Text(
                    booking.venueName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date and time row
                Row(
                  children: [
                    _DetailItem(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('EEE, MMM d').format(booking.startAt),
                    ),
                    const SizedBox(width: 24),
                    _DetailItem(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: booking.formattedTimeRange,
                    ),
                  ],
                ),
                
                // Action buttons (only for upcoming, confirmed bookings)
                if (isUpcoming && booking.isConfirmed && !isPast) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.grey[100],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Chat button
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Message',
                          onTap: () => _openChat(context),
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Cancel button
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.close,
                          label: 'Cancel',
                          onTap: () => _cancelBooking(context),
                          isPrimary: false,
                          isDestructive: true,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Past booking - show organizer name
                if (!isUpcoming || isPast || isCancelled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        'Hosted by ${booking.organizerName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.business, size: 40, color: Colors.grey[400]),
      ),
    );
  }

  Color _getStatusColor() {
    if (booking.isCancelled) return Colors.red;
    if (booking.isPast) return Colors.grey;
    if (booking.isActive) return Colors.blue;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (booking.isCancelled) return Icons.cancel;
    if (booking.isPast) return Icons.history;
    if (booking.isActive) return Icons.play_circle;
    return Icons.schedule;
  }

  String _getStatusText() {
    if (booking.isCancelled) return 'Cancelled';
    if (booking.isPast) return 'Completed';
    if (booking.isActive) return 'In Progress';
    return 'Confirmed';
  }

  void _openChat(BuildContext context) {
    if (booking.chatRoomId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: booking.chatRoomId!,
            otherUserName: booking.organizerName,
            otherUserId: booking.organizerId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat not available')),
      );
    }
  }

  void _cancelBooking(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel your booking at:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.venueName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('EEE, MMM d').format(booking.startAt)} at ${booking.formattedTimeRange}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      final success = await provider.cancelBooking(booking.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Booking cancelled' : 'Failed to cancel'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

/// Detail item (date, time)
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive 
        ? Colors.red 
        : (isPrimary ? AppTheme.primaryColor : Colors.grey[700]);
    
    return Material(
      color: isPrimary ? AppTheme.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isPrimary ? null : Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
