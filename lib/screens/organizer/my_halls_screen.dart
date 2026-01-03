import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/hall_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hall_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/hall_card.dart';
import '../../widgets/loading_widget.dart';
import 'add_edit_hall_screen.dart';

class MyHallsScreen extends StatelessWidget {
  const MyHallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Halls'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<HallProvider>(
        builder: (context, hallProvider, _) {
          if (hallProvider.isLoading) {
            return const LoadingWidget(message: 'Loading halls...');
          }

          final halls = hallProvider.organizerHalls;

          if (halls.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Halls Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by adding your first hall to showcase to customers',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
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
                      label: const Text('Add Your First Hall'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.user != null) {
                await hallProvider.loadOrganizerHalls(authProvider.user!.id);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: halls.length,
              itemBuilder: (context, index) {
                final hall = halls[index];
                return _HallManagementCard(hall: hall);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HallManagementCard extends StatelessWidget {
  final HallModel hall;

  const _HallManagementCard({required this.hall});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          HallCardCompact(
            hall: hall,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditHallScreen(hall: hall),
                ),
              );
            },
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                // Active/Inactive Toggle
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleActive(context),
                    icon: Icon(
                      hall.isActive ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                    ),
                    label: Text(hall.isActive ? 'Active' : 'Inactive'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          hall.isActive ? Colors.green : Colors.grey,
                      side: BorderSide(
                        color: hall.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit Button
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditHallScreen(hall: hall),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTheme.primaryColor,
                ),
                // Delete Button
                IconButton(
                  onPressed: () => _showDeleteDialog(context),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleActive(BuildContext context) async {
    final hallProvider = Provider.of<HallProvider>(context, listen: false);
    try {
      await hallProvider.toggleHallActive(hall.id, !hall.isActive);
      Helpers.showSuccessSnackbar(
        context,
        hall.isActive ? 'Hall deactivated' : 'Hall activated',
      );
    } catch (e) {
      Helpers.showErrorSnackbar(context, 'Failed to update hall');
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hall'),
        content: Text(
          'Are you sure you want to delete "${hall.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final hallProvider =
                  Provider.of<HallProvider>(context, listen: false);
              try {
                await hallProvider.deleteHall(hall.id);
                Helpers.showSuccessSnackbar(context, 'Hall deleted');
              } catch (e) {
                Helpers.showErrorSnackbar(context, 'Failed to delete hall');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
