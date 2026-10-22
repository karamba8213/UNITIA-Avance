import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/donation_badge.dart';
import '../shared/donation_chat_screen.dart';

class RestaurantDonationsScreen extends StatefulWidget {
  final String uid;
  final String name;
  const RestaurantDonationsScreen({super.key, required this.uid, this.name = ''});
  @override
  State<RestaurantDonationsScreen> createState() => _RestaurantDonationsScreenState();
}

class _RestaurantDonationsScreenState extends State<RestaurantDonationsScreen> {
  final _fs = FirestoreService();
  String _filter = 'pending';

  void _openChat(Map<String, dynamic> donation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DonationChatScreen(
          donationId: donation['id'],
          currentUserId: widget.uid,
          currentUserRole: 'restaurant',
          currentUserName: widget.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donaciones')),
      body: Column(
        children: [
          // Filters
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  {'v': 'pending', 'l': 'Pendientes'},
                  {'v': 'paid', 'l': 'Pagadas'},
                  {'v': 'confirmed', 'l': 'Confirmadas'},
                ].map((f) {
                  final selected = _filter == f['v'];
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f['v']!),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f['l']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fs.restaurantDonationsStream(widget.uid, _filter),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final donations = snap.data ?? [];
                if (donations.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('✅', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No hay donaciones en este estado', style: TextStyle(color: AppColors.textMuted)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: donations.length,
                  itemBuilder: (_, i) {
                    final d = donations[i];
                    final amount = (d['amount'] ?? 0.0).toDouble();
                    final status = d['status'] ?? 'pending';
                    return GestureDetector(
                      onTap: () => _openChat(d),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: cardShadow),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d['causeName'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                    Text(d['customerName'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted)),
                                    if (d['notes'] != null &&
                                        (d['notes'] as String).isNotEmpty)
                                      Text('"${d['notes']}"',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              fontStyle: FontStyle.italic)),
                                  ]),
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('\$${amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  DonationBadge(status: status),
                                  if (status == 'pending') ...[
                                    const SizedBox(height: 6),
                                    const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          size: 12, color: AppColors.textMuted),
                                      SizedBox(width: 4),
                                      Text('Abrir chat',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted)),
                                    ]),
                                  ],
                                ]),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
