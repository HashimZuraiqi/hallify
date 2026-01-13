import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';
import '../../models/hall_model.dart';
import '../../models/visit_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visit_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../chat/chat_screen.dart';

class HallDetailsScreen extends StatefulWidget {
  final HallModel hall;

  const HallDetailsScreen({super.key, required this.hall});

  @override
  State<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends State<HallDetailsScreen> {
  int _currentImageIndex = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  final PageController _pageController = PageController();
  GoogleMapController? _mapController;
  StreamSubscription<QuerySnapshot>? _visitListener;
  VisitRequestModel? _currentUserVisit;

  @override
  void initState() {
    super.initState();
    _setupVisitListener();
  }

  void _setupVisitListener() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    // Real-time listener for user's visit to THIS hall
    _visitListener = FirebaseFirestore.instance
        .collection('visitRequests')
        .where('hallId', isEqualTo: widget.hall.id)
        .where('customerId', isEqualTo: authProvider.user!.id)
        .where('status', whereIn: ['pending', 'approved'])
        .orderBy('createdAt', descending: true) // Get latest request
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          if (snapshot.docs.isNotEmpty) {
            _currentUserVisit = VisitRequestModel.fromFirestore(snapshot.docs.first);
          } else {
            _currentUserVisit = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _visitListener?.cancel();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _showBookingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BookingBottomSheet(
        hall: widget.hall,
        selectedDate: _selectedDate,
        selectedTimeSlot: _selectedTimeSlot,
        onDateChanged: (date) => setState(() => _selectedDate = date),
        onTimeSlotChanged: (slot) => setState(() => _selectedTimeSlot = slot),
      ),
    );
  }

  Future<void> _startChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user == null) return;

    try {
      Helpers.showLoadingDialog(context, message: 'Starting conversation...');

      final conversation = await chatProvider.getOrCreateConversation(
        participantIds: [authProvider.user!.id, widget.hall.organizerId],
        participantNames: {
          authProvider.user!.id: authProvider.user!.name,
          widget.hall.organizerId: 'Organizer',
        },
        hallId: widget.hall.id,
        hallName: widget.hall.name,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (conversation == null) {
        Helpers.showErrorSnackbar(context, 'Failed to create conversation');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            otherUserName: 'Organizer',
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      Helpers.showErrorSnackbar(context, 'Failed to start chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image Gallery with App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Carousel
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.hall.imageUrls.isEmpty ? 1 : widget.hall.imageUrls.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      if (widget.hall.imageUrls.isEmpty) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        );
                      }
                      return CachedNetworkImage(
                        imageUrl: widget.hall.imageUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ShimmerLoading(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Page Indicator
                  if (widget.hall.imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.hall.imageUrls.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // Share hall
                },
                icon: const Icon(Icons.share, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  // Add to favorites
                },
                icon: const Icon(Icons.favorite_border, color: Colors.white),
              ),
            ],
          ),
          // Hall Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hall Name and Type Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.hall.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getTypeLabel(widget.hall.type),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.hall.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.hall.rating,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.hall.rating} (${widget.hall.reviewCount} reviews)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Price and Capacity
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.attach_money,
                          title: 'Price',
                          value: '${widget.hall.pricePerHour} JOD/hr',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.people,
                          title: 'Capacity',
                          value: '${widget.hall.capacity} guests',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.hall.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Features
                  Text(
                    'Features',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.hall.features.map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getFeatureIcon(feature),
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(feature),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Location Map
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            widget.hall.latitude,
                            widget.hall.longitude,
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(widget.hall.id),
                            position: LatLng(
                              widget.hall.latitude,
                              widget.hall.longitude,
                            ),
                            infoWindow: InfoWindow(title: widget.hall.name),
                          ),
                        },
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.user == null) {
            return const SizedBox.shrink();
          }

          // Use real-time listener data instead of provider
          final existingVisit = _currentUserVisit;

          if (existingVisit != null) {
            // Show existing visit status
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(top: BorderSide(color: Colors.orange.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pending_actions, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        existingVisit.status == VisitStatus.pending
                            ? 'Pending Visit Request'
                            : 'Approved Visit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${existingVisit.visitDate.day}/${existingVisit.visitDate.month}/${existingVisit.visitDate.year} at ${existingVisit.visitTime}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  // PENDING VISITS
                  if (existingVisit.status == VisitStatus.pending)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showBookingDialog();
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Visit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelVisit(existingVisit.id),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancel Request'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  // APPROVED VISITS
                  if (existingVisit.status == VisitStatus.approved)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startChat,
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('Chat with Organizer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelVisit(existingVisit.id),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancel Visit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                            icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                            label: const Text('Edit Visit', style: TextStyle(color: AppTheme.primaryColor)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
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
                                final visitProvider = Provider.of<VisitProvider>(context, listen: false);
                                await visitProvider.cancelVisitRequest(existingVisit.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Visit request cancelled')),
                                );
                              }
                            },
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }

          // No existing visit - show normal schedule button
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Chat Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat_outlined, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                // Book Visit Button
                Expanded(
                  child: GradientButton(
                    text: 'Schedule Visit',
                    onPressed: _showBookingDialog,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getTypeLabel(HallType type) {
    switch (type) {
      case HallType.wedding:
        return 'Wedding';
      case HallType.conference:
        return 'Conference';
      case HallType.both:
        return 'Multi-purpose';
    }
  }

  IconData _getFeatureIcon(String feature) {
    final featureIcons = {
      'Parking': Icons.local_parking,
      'Catering': Icons.restaurant,
      'AC': Icons.ac_unit,
      'Sound System': Icons.speaker,
      'Projector': Icons.videocam,
      'WiFi': Icons.wifi,
      'Stage': Icons.theater_comedy,
      'Decoration': Icons.celebration,
      'Photography': Icons.camera_alt,
      'Valet': Icons.car_rental,
    };
    return featureIcons[feature] ?? Icons.check_circle;
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingBottomSheet extends StatefulWidget {
  final HallModel hall;
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String?> onTimeSlotChanged;

  const _BookingBottomSheet({
    required this.hall,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.onDateChanged,
    required this.onTimeSlotChanged,
  });

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  String? _selectedTimeSlot;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _selectedDay = widget.selectedDate;
    _selectedTimeSlot = widget.selectedTimeSlot;
    
    // Check if editing existing visit and pre-fill data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        final existingVisit = visitProvider.customerVisits.where((v) =>
            v.hallId == widget.hall.id &&
            (v.status == VisitStatus.pending || v.status == VisitStatus.approved)
        ).firstOrNull;
        
        if (existingVisit != null) {
          setState(() {
            _selectedDay = existingVisit.visitDate;
            _focusedDay = existingVisit.visitDate;
            _selectedTimeSlot = existingVisit.visitTime;
            _notesController.text = existingVisit.message ?? '';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_selectedTimeSlot == null) {
      Helpers.showErrorSnackbar(context, 'Please select a time slot');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);

    if (authProvider.user == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Check if user is editing an existing visit
      final existingVisit = visitProvider.customerVisits.where((v) =>
          v.hallId == widget.hall.id &&
          (v.status == VisitStatus.pending || v.status == VisitStatus.approved)
      ).firstOrNull;

      // If editing, cancel the old visit first
      if (existingVisit != null) {
        await visitProvider.cancelVisitRequest(existingVisit.id);
        if (!mounted) return;
      }

      // Check for time slot conflicts
      final hasConflict = await visitProvider.checkTimeSlotConflict(
        hallId: widget.hall.id,
        date: _selectedDay,
        timeSlot: _selectedTimeSlot!,
      );

      if (hasConflict) {
        if (!mounted) return;
        Helpers.showErrorSnackbar(
          context,
          'This time slot is already booked. Please choose another.',
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final visitRequest = VisitRequestModel(
        id: '',
        hallId: widget.hall.id,
        hallName: widget.hall.name,
        hallImageUrl: widget.hall.primaryImageUrl,
        customerId: authProvider.user!.id,
        customerName: authProvider.user!.name,
        customerEmail: authProvider.user!.email,
        customerPhone: authProvider.user!.phone ?? '',
        organizerId: widget.hall.organizerId,
        organizerName: widget.hall.organizerName,
        visitDate: _selectedDay,
        visitTime: _selectedTimeSlot!,
        message: _notesController.text.trim(),
        status: VisitStatus.pending,
        createdAt: DateTime.now(),
      );

      await visitProvider.createVisitRequest(visitRequest);

      // Reload visits to refresh UI immediately
      if (authProvider.user != null) {
        await visitProvider.loadCustomerVisits(authProvider.user!.id);
      }
      
      // Small delay to ensure Firestore has propagated
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      Navigator.pop(context);
      Helpers.showSuccessSnackbar(context, 'Visit request submitted!');
    } catch (e) {
      // Show actual error message from transaction or other errors
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      Helpers.showErrorSnackbar(context, errorMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Schedule a Visit',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a date and time slot for your visit to ${widget.hall.name}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // Calendar
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDateChanged(selectedDay);
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 24),
            // Time Slots
            Text(
              'Available Time Slots',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Consumer<VisitProvider>(
              builder: (context, visitProvider, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.timeSlots.map((slot) {
                    final isSelected = _selectedTimeSlot == slot;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedTimeSlot = slot);
                        widget.onTimeSlotChanged(slot);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                hintText: 'Any special requirements or questions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: 'Submit Request',
                onPressed: _submitRequest,
                isLoading: _isSubmitting,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
