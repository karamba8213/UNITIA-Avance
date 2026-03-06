import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/donation_badge.dart';

class CauseDonationsScreen extends StatefulWidget {
  final String uid;
  const CauseDonationsScreen({super.key, required this.uid});
  @override
  State<CauseDonationsScreen> createState() => _CauseDonationsScreenState();
}

class _CauseDonationsScreenState extends State<CauseDonationsScreen> {
  final _fs = FirestoreService();
  String _filter = 'paid';
  String? _confirming;

  Future<void> _confirm(Map<String, dynamic> d) async {
    setState(() => _confirming = d['id']);
    try {
      await _fs.confirmDonationReceived(d['id'], d['orderId'], widget.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _confirming = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donaciones')),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  {'v': 'paid', 'l': 'Por confirmar'},
                  {'v': 'pending', 'l': 'Pendientes'},
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
                      child: Text(f['l']!,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fs.causeDonationsStream(widget.uid, _filter),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final donations = snap.data ?? [];
                if (donations.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('💚', style: TextStyle(fontSize: 48)),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: cardShadow,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['restaurantName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(d['customerName'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              if (d['notes'] != null && (d['notes'] as String).isNotEmpty)
                                Text('"${d['notes']}"',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                            ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('\$${amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            DonationBadge(status: d['status'] ?? 'pending'),
                            if (d['status'] == 'paid') ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _confirming == d['id'] ? null : () => _confirm(d),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: AppColors.success, borderRadius: BorderRadius.circular(8)),
                                  child: _confirming == d['id']
                                      ? const SizedBox(width: 12, height: 12,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Confirmar recibo',
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ]),
                        ],
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
