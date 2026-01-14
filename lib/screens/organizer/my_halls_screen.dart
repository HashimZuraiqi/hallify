import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/hall_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hall_provider.dart';
import '../../utils/helpers.dart';
import 'add_edit_hall_screen.dart';

class MyHallsScreen extends StatefulWidget {
  const MyHallsScreen({super.key});

  @override
  State<MyHallsScreen> createState() => _MyHallsScreenState();
}

class _MyHallsScreenState extends State<MyHallsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh halls when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHalls();
    });
  }

  void _refreshHalls() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hallProvider = Provider.of<HallProvider>(context, listen: false);
    if (authProvider.user != null) {
      hallProvider.loadOrganizerHalls(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Halls'),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHalls,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditHallScreen(),
            ),
          );
          _refreshHalls();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Hall'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<HallProvider>(
        builder: (context, hallProvider, _) {
          if (hallProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your halls...'),
                ],
              ),
            );
          }

          final halls = hallProvider.organizerHalls;

          if (halls.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshHalls(),
            child: CustomScrollView(
              slivers: [
                // Stats Header
                SliverToBoxAdapter(
                  child: _buildStatsHeader(halls),
                ),
                // Halls List
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final hall = halls[index];
                        return _buildHallCard(hall);
                      },
                      childCount: halls.length,
                    ),
                  ),
                ),
                // Bottom padding for FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Halls Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by adding your first hall to\nshowcase to customers',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditHallScreen(),
                  ),
                );
                _refreshHalls();
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Your First Hall'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(List<HallModel> halls) {
    final activeHalls = halls.where((h) => h.isActive).length;
    final inactiveHalls = halls.length - activeHalls;
    final avgRating = halls.isEmpty 
        ? 0.0 
        : halls.fold<double>(0, (sum, h) => sum + h.rating) / halls.length;
    final totalCapacity = halls.fold<int>(0, (sum, h) => sum + h.capacity);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            Color(0xFF1A237E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.business,
                value: halls.length.toString(),
                label: 'Total',
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: activeHalls.toString(),
                label: 'Active',
                color: Colors.greenAccent,
              ),
              _buildStatItem(
                icon: Icons.pause_circle,
                value: inactiveHalls.toString(),
                label: 'Inactive',
                color: Colors.orangeAccent,
              ),
              _buildStatItem(
                icon: Icons.star,
                value: avgRating.toStringAsFixed(1),
                label: 'Rating',
                color: Colors.amberAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total Capacity: $totalCapacity guests',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallCard(HallModel hall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: hall.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: hall.primaryImageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[200]!],
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No images', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
              ),
              // Status Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hall.isActive ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (hall.isActive ? Colors.green : Colors.orange).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hall.isActive ? Icons.visibility : Icons.visibility_off,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hall.isActive ? 'Active' : 'Hidden',
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
              // Type Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hall.type.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Image count badge
              if (hall.imageUrls.length > 1)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${hall.imageUrls.length}',
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
            ],
          ),
          // Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hall.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            hall.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${hall.city} • ${hall.address}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(Icons.people, '${hall.capacity} guests'),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      _buildInfoChip(Icons.attach_money, '${hall.pricePerHour.toStringAsFixed(0)} JOD/hr'),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      _buildInfoChip(Icons.reviews, '${hall.totalReviews} reviews'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleActive(hall),
                        icon: Icon(
                          hall.isActive ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        label: Text(hall.isActive ? 'Hide' : 'Show'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: hall.isActive ? Colors.orange : Colors.green,
                          side: BorderSide(color: hall.isActive ? Colors.orange : Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditHallScreen(hall: hall),
                            ),
                          );
                          _refreshHalls();
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Hall'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _showDeleteDialog(hall),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _toggleActive(HallModel hall) async {
    final hallProvider = Provider.of<HallProvider>(context, listen: false);
    try {
      await hallProvider.toggleHallActive(hall.id, !hall.isActive);
      if (!mounted) return;
      Helpers.showSuccessSnackbar(
        context,
        hall.isActive ? 'Hall hidden from customers' : 'Hall is now visible to customers',
      );
    } catch (e) {
      if (!mounted) return;
      Helpers.showErrorSnackbar(context, 'Failed to update hall');
    }
  }

  void _showDeleteDialog(HallModel hall) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Delete Hall'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${hall.name}"?\n\nThis action cannot be undone and all data including images will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final hallProvider = Provider.of<HallProvider>(context, listen: false);
              try {
                await hallProvider.deleteHall(hall.id);
                if (!mounted) return;
                Helpers.showSuccessSnackbar(context, 'Hall deleted successfully');
                _refreshHalls();
              } catch (e) {
                if (!mounted) return;
                Helpers.showErrorSnackbar(context, 'Failed to delete hall');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
