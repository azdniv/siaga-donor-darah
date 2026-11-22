import 'package:flutter/material.dart';

import '../models/blood_request.dart';

/// Label status permintaan dengan warna sesuai statusnya.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip(this.status, {super.key});

  Color _color(BuildContext context) {
    switch (status) {
      case 'active':
        return Colors.blue.shade700;
      case 'fulfilled':
        return Colors.green.shade700;
      case 'pending_verification':
        return Colors.orange.shade800;
      case 'rejected':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        requestStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
