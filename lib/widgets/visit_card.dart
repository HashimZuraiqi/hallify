import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/visit_request_model.dart';
import '../utils/helpers.dart';

class VisitCard extends StatelessWidget {
  final VisitRequestModel visit;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final bool showActions;
  final bool isOrganizer;

  const VisitCard({
    super.key,
    required this.visit,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.showActions = false,
    this.isOrganizer = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Hall Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: visit.hallImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: visit.hallImageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.business),
                          ),
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.business),
                        ),
                ),
                const SizedBox(width: 12),
                // Hall Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.hallName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOrganizer ? 'Customer: ${visit.customerName}' : 'Organizer: ${visit.organizerName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                _StatusBadge(status: visit.status),
              ],
            ),
            const Divider(height: 24),
            // Date and Time
            Row(
              children: [
                _InfoItem(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: Helpers.formatDate(visit.visitDate),
                ),
                const SizedBox(width: 24),
                _InfoItem(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: visit.visitTime,
                ),
              ],
            ),
            // Message (if any)
            if (visit.message != null && visit.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.message,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        visit.message!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Rejection Reason (if rejected)
            if (visit.isRejected && visit.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${visit.rejectionReason}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Actions
            if (showActions && visit.isPending) ...[
              const SizedBox(height: 16),
              if (isOrganizer)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
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
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Cancel Request'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final VisitStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor() {
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

  String _getStatusText() {
    switch (status) {
      case VisitStatus.pending:
        return 'Pending';
      case VisitStatus.approved:
        return 'Approved';
      case VisitStatus.rejected:
        return 'Rejected';
      case VisitStatus.completed:
        return 'Completed';
      case VisitStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
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
    );
  }
}
