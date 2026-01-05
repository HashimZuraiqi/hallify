import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/visit_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visit_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/visit_card.dart';
import '../../widgets/loading_widget.dart';

class VisitRequestsScreen extends StatefulWidget {
  const VisitRequestsScreen({super.key});

  @override
  State<VisitRequestsScreen> createState() => _VisitRequestsScreenState();
}

class _VisitRequestsScreenState extends State<VisitRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVisits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadVisits() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);

    if (authProvider.user != null) {
      visitProvider.loadCustomerVisits(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Visits'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, _) {
          if (visitProvider.isLoading) {
            return const LoadingWidget(message: 'Loading visits...');
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _VisitsList(
                visits: visitProvider.customerVisits,
                emptyMessage: 'No visits yet',
                emptySubMessage: 'Browse halls and schedule your first visit',
              ),
              _VisitsList(
                visits: visitProvider.customerVisits.where((v) => v.status == VisitStatus.pending).toList(),
                emptyMessage: 'No pending visits',
                emptySubMessage: 'Your pending visit requests will appear here',
              ),
              _VisitsList(
                visits: visitProvider.customerVisits.where((v) => v.status == VisitStatus.approved).toList(),
                emptyMessage: 'No approved visits',
                emptySubMessage: 'Approved visits will appear here',
              ),
              _VisitsList(
                visits: visitProvider.customerVisits.where((v) => v.status == VisitStatus.completed).toList(),
                emptyMessage: 'No completed visits',
                emptySubMessage: 'Your visit history will appear here',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VisitsList extends StatelessWidget {
  final List<VisitRequestModel> visits;
  final String emptyMessage;
  final String emptySubMessage;

  const _VisitsList({
    required this.visits,
    required this.emptyMessage,
    required this.emptySubMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_note,
        title: emptyMessage,
        message: emptySubMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final visitProvider = Provider.of<VisitProvider>(context, listen: false);

        if (authProvider.user != null) {
          await visitProvider.loadCustomerVisits(authProvider.user!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return VisitCard(
            visit: visit,
            isOrganizer: false,
            onTap: () => _showVisitDetails(context, visit),
          );
        },
      ),
    );
  }

  void _showVisitDetails(BuildContext context, VisitRequestModel visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VisitDetailsSheet(visit: visit),
    );
  }
}

class _VisitDetailsSheet extends StatelessWidget {
  final VisitRequestModel visit;

  const _VisitDetailsSheet({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 24),
          // Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(visit.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  visit.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(visit.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Requested ${Helpers.formatDate(visit.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Hall Name
          Text(
            visit.hallName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          // Visit Details
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: Helpers.formatDate(visit.requestDate),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: visit.timeSlot,
          ),
          if (visit.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.notes,
              label: 'Notes',
              value: visit.notes,
            ),
          ],
          if (visit.status == VisitStatus.rejected && visit.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visit.rejectionReason!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Actions
          if (visit.status == VisitStatus.pending)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelVisit(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Cancel Request'),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Color _getStatusColor(VisitStatus status) {
    switch (status) {
      case VisitStatus.pending:
        return Colors.orange;
      case VisitStatus.approved:
        return Colors.green;
      case VisitStatus.rejected:
        return Colors.red;
      case VisitStatus.completed:
        return Colors.blue;
      case VisitStatus.cancelled:
        return Colors.grey;
    }
  }

  void _cancelVisit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Visit'),
        content: const Text(
          'Are you sure you want to cancel this visit request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              final visitProvider = Provider.of<VisitProvider>(context, listen: false);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet

              try {
                await visitProvider.cancelVisitRequest(visit.id);
                Helpers.showSuccessSnackbar(context, 'Visit cancelled');
              } catch (e) {
                Helpers.showErrorSnackbar(context, 'Failed to cancel visit');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
