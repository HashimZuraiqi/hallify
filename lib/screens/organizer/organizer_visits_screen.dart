import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/visit_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visit_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/visit_card.dart';
import '../../widgets/loading_widget.dart';

class OrganizerVisitsScreen extends StatefulWidget {
  const OrganizerVisitsScreen({super.key});

  @override
  State<OrganizerVisitsScreen> createState() => _OrganizerVisitsScreenState();
}

class _OrganizerVisitsScreenState extends State<OrganizerVisitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Requests'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Completed'),
            Tab(text: 'Rejected'),
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
              _OrganizerVisitsList(
                visits: visitProvider.organizerVisits,
                emptyMessage: 'No visits yet',
              ),
              _OrganizerVisitsList(
                visits: visitProvider.organizerVisits.where((v) => v.status == VisitStatus.pending).toList(),
                emptyMessage: 'No pending requests',
              ),
              _OrganizerVisitsList(
                visits: visitProvider.organizerVisits.where((v) => v.status == VisitStatus.approved).toList(),
                emptyMessage: 'No approved visits',
              ),
              _OrganizerVisitsList(
                visits: visitProvider.organizerVisits.where((v) => v.status == VisitStatus.completed).toList(),
                emptyMessage: 'No completed visits',
              ),
              _OrganizerVisitsList(
                visits: visitProvider.organizerVisits.where((v) => v.status == VisitStatus.rejected).toList(),
                emptyMessage: 'No rejected visits',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrganizerVisitsList extends StatelessWidget {
  final List<VisitRequestModel> visits;
  final String emptyMessage;

  const _OrganizerVisitsList({
    required this.visits,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_note,
        title: emptyMessage,
        message: 'Visit requests will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final visitProvider = Provider.of<VisitProvider>(context, listen: false);

        if (authProvider.user != null) {
          await visitProvider.loadOrganizerVisits(authProvider.user!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return VisitCard(
            visit: visit,
            isOrganizer: true,
            onTap: () => _showVisitDetails(context, visit),
            onApprove: visit.status == VisitStatus.pending ? () => _handleApprove(context, visit) : null,
            onReject: visit.status == VisitStatus.pending ? () => _handleReject(context, visit) : null,
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
      builder: (context) => _OrganizerVisitDetailsSheet(visit: visit),
    );
  }

  void _handleApprove(BuildContext context, VisitRequestModel visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Visit'),
        content: Text(
          'Approve visit request from ${visit.customerName} for ${visit.hallName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      try {
        await visitProvider.approveVisitRequest(visit.id);
        Helpers.showSuccessSnackbar(context, 'Visit approved!');
      } catch (e) {
        Helpers.showErrorSnackbar(context, 'Failed to approve visit');
      }
    }
  }

  void _handleReject(BuildContext context, VisitRequestModel visit) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject visit request from ${visit.customerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
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
          visit.id,
          reason: result.isNotEmpty ? result : null,
        );
        Helpers.showSuccessSnackbar(context, 'Visit rejected');
      } catch (e) {
        Helpers.showErrorSnackbar(context, 'Failed to reject visit');
      }
    }
  }
}

class _OrganizerVisitDetailsSheet extends StatelessWidget {
  final VisitRequestModel visit;

  const _OrganizerVisitDetailsSheet({required this.visit});

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
                Helpers.formatDate(visit.createdAt),
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
          const SizedBox(height: 8),
          // Customer Info
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Customer: ${visit.customerName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Visit Details
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Visit Date',
            value: Helpers.formatDate(visit.requestDate),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Time Slot',
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
          const SizedBox(height: 24),
          // Actions for pending visits
          if (visit.status == VisitStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleReject(context, visit);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleApprove(context, visit);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          // Mark as completed for approved visits
          if (visit.status == VisitStatus.approved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markAsCompleted(context, visit),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Completed'),
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

  void _handleApprove(BuildContext context, VisitRequestModel visit) async {
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    try {
      await visitProvider.approveVisitRequest(visit.id);
      Helpers.showSuccessSnackbar(context, 'Visit approved!');
    } catch (e) {
      Helpers.showErrorSnackbar(context, 'Failed to approve visit');
    }
  }

  void _handleReject(BuildContext context, VisitRequestModel visit) async {
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
          visit.id,
          reason: result.isNotEmpty ? result : null,
        );
        Helpers.showSuccessSnackbar(context, 'Visit rejected');
      } catch (e) {
        Helpers.showErrorSnackbar(context, 'Failed to reject visit');
      }
    }
  }

  void _markAsCompleted(BuildContext context, VisitRequestModel visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text('Mark this visit as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pop(context);
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      try {
        await visitProvider.completeVisitRequest(visit.id);
        Helpers.showSuccessSnackbar(context, 'Visit marked as completed');
      } catch (e) {
        Helpers.showErrorSnackbar(context, 'Failed to update visit');
      }
    }
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
