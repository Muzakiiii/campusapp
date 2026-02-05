import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/features/events/domain/models/payment_model.dart';

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

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
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
                            payment.status == PaymentStatus.verified
                                ? Icons.verified
                                : Icons.access_time,
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
                      'ID: ${payment.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
                    color: AppColors.textPrimary,
                  ),
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
                        color: payment.amount > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment.amount > 0
                            ? 'Rp ${payment.amount.toInt()}'
                            : 'Gratis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: payment.amount > 0 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Payment Method
                    Row(
                      children: [
                        Icon(
                          payment.methodIcon,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          payment.methodName,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // User Info & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ID',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          payment.userId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tanggal',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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
                      Text(
                        'Catatan: ${payment.note}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
            Container(
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
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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