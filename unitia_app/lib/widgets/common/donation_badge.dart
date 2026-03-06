import 'package:flutter/material.dart';

class DonationBadge extends StatelessWidget {
  final String status;
  const DonationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      'pending'   => (label: 'Pendiente', bg: const Color(0xFFFEF3C7), text: const Color(0xFF92400E), dot: const Color(0xFFF59E0B)),
      'paid'      => (label: 'Pagada',    bg: const Color(0xFFEFF6FF), text: const Color(0xFF1D4ED8), dot: const Color(0xFF3B82F6)),
      'confirmed' => (label: 'Confirmada',bg: const Color(0xFFECFDF5), text: const Color(0xFF065F46), dot: const Color(0xFF10B981)),
      'disputed'  => (label: 'Disputa',   bg: const Color(0xFFFEF2F2), text: const Color(0xFF991B1B), dot: const Color(0xFFEF4444)),
      _           => (label: status,      bg: const Color(0xFFF3F4F6), text: const Color(0xFF6B7280), dot: const Color(0xFF9CA3AF)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: config.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: config.text),
          ),
        ],
      ),
    );
  }
}
