import 'package:flutter/material.dart';
import 'package:campusapp/features/events/domain/models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentVerificationTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const PaymentVerificationTile({
    super.key,
    required this.payment,
    required this.onVerify,
    required this.onReject,
    required this.onViewDetails,
  });

  // Helper untuk format tanggal
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Helper untuk format jam
  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Helper untuk format Rupiah
  String _formatRupiah(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  // Helper untuk status icon
  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.verified:
        return Icons.verified;
      case PaymentStatus.paid:
        return Icons.payment;
      case PaymentStatus.rejected:
        return Icons.block;
      case PaymentStatus.expired:
        return Icons.timer_off;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.pending:
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isGratis = payment.amount == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: payment.statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Payment Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge and ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: payment.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(payment.status),
                            size: 14,
                            color: payment.statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            payment.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: payment.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      payment.paymentCode != null && payment.paymentCode!.isNotEmpty
                          ? payment.paymentCode!
                          : '#${payment.id.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Event Title
                Text(
                  payment.eventTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Payment Details
                Row(
                  children: [
                    // Amount
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isGratis ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isGratis ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isGratis ? 'Gratis' : _formatRupiah(payment.amount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isGratis ? Colors.green[800] : Colors.blue[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Payment Method
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            payment.methodIcon,
                            size: 14,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            payment.methodName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // User Info & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User ID',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            payment.userId.length > 20 
                                ? '${payment.userId.substring(0, 20)}...'
                                : payment.userId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tanggal',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatDate(payment.createdAt),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(payment.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Note if exists
                if (payment.note != null && payment.note!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.note,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                payment.note!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Divider
          if (payment.status == PaymentStatus.pending ||
              payment.status == PaymentStatus.paid)
            Container(
              height: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
          
          // Actions for pending/paid payments
          if (payment.status == PaymentStatus.pending ||
              payment.status == PaymentStatus.paid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // View Details Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Reject Button (only for pending)
                  if (payment.status == PaymentStatus.pending)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  
                  if (payment.status == PaymentStatus.pending) const SizedBox(width: 8),
                  
                  // Verify Button (only for pending/paid)
                  if (payment.status == PaymentStatus.pending ||
                      payment.status == PaymentStatus.paid)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onVerify,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Verifikasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}