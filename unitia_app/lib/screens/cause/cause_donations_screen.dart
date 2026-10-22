import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/donation_badge.dart';
import '../shared/donation_chat_screen.dart';
import 'direct_donation_detail_screen.dart';

class CauseDonationsScreen extends StatefulWidget {
  final String uid;
  final String name;
  const CauseDonationsScreen({super.key, required this.uid, this.name = ''});
  @override
  State<CauseDonationsScreen> createState() => _CauseDonationsScreenState();
}

class _CauseDonationsScreenState extends State<CauseDonationsScreen>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  String _filter = 'paid';
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openChat(Map<String, dynamic> donation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DonationChatScreen(
          donationId: donation['id'],
          currentUserId: widget.uid,
          currentUserRole: 'cause',
          currentUserName: widget.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donaciones'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Por pedidos'),
            Tab(text: 'Directas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: order-based donations ───────────────────────
          Column(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f['l']!,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary)),
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
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final donations = snap.data ?? [];
                    if (donations.isEmpty) {
                      return const Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('💚',
                                  style: TextStyle(fontSize: 48)),
                              SizedBox(height: 12),
                              Text('No hay donaciones en este estado',
                                  style: TextStyle(
                                      color: AppColors.textMuted)),
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
                              boxShadow: cardShadow,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(d['restaurantName'] ?? '',
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
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontStyle:
                                                      FontStyle.italic)),
                                      ]),
                                ),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          '\$${amount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      DonationBadge(status: status),
                                      if (status == 'paid') ...[
                                        const SizedBox(height: 6),
                                        const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                  Icons
                                                      .chat_bubble_outline_rounded,
                                                  size: 12,
                                                  color: AppColors.textMuted),
                                              SizedBox(width: 4),
                                              Text('Abrir chat',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textMuted)),
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

          // ── Tab 2: direct donations ────────────────────────────
          _DirectDonationsTab(causeId: widget.uid, causeName: widget.name),
        ],
      ),
    );
  }
}

// ── Direct donations tab ───────────────────────────────────────────────────────
class _DirectDonationsTab extends StatefulWidget {
  final String causeId;
  final String causeName;
  const _DirectDonationsTab(
      {required this.causeId, required this.causeName});

  @override
  State<_DirectDonationsTab> createState() => _DirectDonationsTabState();
}

class _DirectDonationsTabState extends State<_DirectDonationsTab> {
  final _fs = FirestoreService();
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                {'v': 'pending', 'l': 'Pendientes'},
                {'v': 'confirmed', 'l': 'Confirmadas'},
              ].map((f) {
                final selected = _filter == f['v'];
                return GestureDetector(
                  onTap: () => setState(() => _filter = f['v']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f['l']!,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _fs.directDonationsByCauseStream(
                widget.causeId, _filter),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary));
              }
              final donations = snap.data ?? [];
              if (donations.isEmpty) {
                return Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💸',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'pending'
                              ? 'No hay donaciones directas pendientes'
                              : 'No hay donaciones directas confirmadas',
                          style: const TextStyle(
                              color: AppColors.textMuted),
                        ),
                      ]),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: donations.length,
                itemBuilder: (_, i) {
                  final d = donations[i];
                  final amount = (d['proposedAmount'] ?? 0.0).toDouble();
                  final status = d['status'] ?? 'pending';
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectDonationDetailScreen(
                          donation: d,
                          causeId: widget.causeId,
                          causeName: widget.causeName,
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(d['customerName'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  if (d['notes'] != null &&
                                      (d['notes'] as String).isNotEmpty)
                                    Text('"${d['notes']}"',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                  const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                            Icons
                                                .check_circle_outline_rounded,
                                            size: 12,
                                            color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text('Confirmar',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                                fontWeight:
                                                    FontWeight.w600)),
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
    );
  }
}
