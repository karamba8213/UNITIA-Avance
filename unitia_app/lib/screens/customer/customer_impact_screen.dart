import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import 'cause_ranking_screen.dart';
import 'refer_cause_screen.dart';

class CustomerImpactScreen extends StatefulWidget {
  final String uid;
  const CustomerImpactScreen({super.key, required this.uid});
  @override
  State<CustomerImpactScreen> createState() => _CustomerImpactScreenState();
}

class _CustomerImpactScreenState extends State<CustomerImpactScreen> {
  final _fs = FirestoreService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = context.read<AuthProvider>().user?.email ?? '';
    final impact = await _fs.getCustomerImpact(email);
    if (mounted) setState(() { _data = impact; _loading = false; });
  }

  String _fmt(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Impact',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const CauseRankingScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.leaderboard_rounded,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Ranking',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    : Column(
                        children: [
                          // ── Impact wallet card (gradiente) ──────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: primaryShadow,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.savings_rounded,
                                      color: Colors.white, size: 26),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'TOTAL IMPACT GENERATED',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _fmt((_data?['totalDonated'] ?? 0.0).toDouble()),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14, height: 1.4),
                                    children: [
                                      const TextSpan(text: 'Your orders have directly supported '),
                                      TextSpan(
                                        text:
                                            '${(_data?['byCause'] as List?)?.length ?? 0} local causes',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                      const TextSpan(text: ' in your community.'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () => Navigator.push(context,
                                      MaterialPageRoute(
                                          builder: (_) => const ReferCauseScreen())),
                                  child: Container(
                                    width: double.infinity,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.volunteer_activism_rounded,
                                            color: AppColors.primary, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Refer a Cause',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Stats row ───────────────────────────────
                          Row(children: [
                            Expanded(
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.local_cafe_outlined,
                                          color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text('+2 this week',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.success)),
                                      ),
                                    ]),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${_data?['totalOrders'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text('Contributions made',
                                        style: TextStyle(
                                            fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.groups_outlined,
                                        color: AppColors.primary, size: 20),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${(_data?['byCause'] as List?)?.length ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text('Causes supported',
                                        style: TextStyle(
                                            fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // ── Impact History ──────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Impact History',
                                  style: TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w800)),
                              GestureDetector(
                                onTap: () {},
                                child: const Text('See All',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Transaction list
                          ...(_data?['recentOrders'] as List? ?? [])
                              .take(10)
                              .map((order) => _TransactionTile(order: order)),

                          if ((_data?['recentOrders'] as List? ?? []).isEmpty)
                            AppCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(children: [
                                    Icon(Icons.receipt_long_outlined,
                                        size: 40, color: AppColors.border),
                                    const SizedBox(height: 10),
                                    const Text('No orders yet',
                                        style: TextStyle(
                                            color: AppColors.textSecondary, fontSize: 14)),
                                  ]),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction tile ──────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final dynamic order;
  const _TransactionTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final amount    = (order['donationAmount'] ?? 0.0).toDouble();
    final status    = order['donationStatus'] ?? 'pending';
    final isConfirmed = status == 'confirmed';
    final createdAt = order['createdAt'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['restaurantName'] ?? 'Restaurante',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    createdAt != null
                        ? '${_fmtDate(createdAt.toDate())} · ${order['causeName'] ?? ''}'
                        : order['causeName'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConfirmed ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isConfirmed ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}
