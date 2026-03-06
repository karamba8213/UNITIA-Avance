import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/donation_badge.dart';

class RestaurantDonationsScreen extends StatefulWidget {
  final String uid;
  const RestaurantDonationsScreen({super.key, required this.uid});
  @override
  State<RestaurantDonationsScreen> createState() => _RestaurantDonationsScreenState();
}

class _RestaurantDonationsScreenState extends State<RestaurantDonationsScreen> {
  final _fs = FirestoreService();
  String _filter = 'pending';
  String? _paying;

  Future<void> _markPaid(Map<String, dynamic> donation) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirmar pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Donación de \$${(donation['amount'] as num).toStringAsFixed(0)} a ${donation['causeName']}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Nota (opcional)', hintText: 'Ej: transferencia #12345'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                child: const Text('Cancelar'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                child: const Text('Confirmar'),
              )),
            ]),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _paying = donation['id']);
    try {
      await _fs.markDonationPaid(donation['id'], donation['orderId'], notes: notesCtrl.text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _paying = null);
    }
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: cardShadow),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['causeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(d['customerName'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              if (d['notes'] != null && (d['notes'] as String).isNotEmpty)
                                Text('"${d['notes']}"', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                            ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('\$${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            DonationBadge(status: d['status'] ?? 'pending'),
                            if (d['status'] == 'pending') ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _paying == d['id'] ? null : () => _markPaid(d),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                                  child: _paying == d['id']
                                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Marcar pagada', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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
