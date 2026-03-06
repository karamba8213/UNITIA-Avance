import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/cause.dart';
import '../../widgets/common/donation_badge.dart';
import '../../widgets/common/stat_card.dart';
import '../auth/login_screen.dart';
import 'cause_donations_screen.dart';
import 'cause_settings_screen.dart';

class CauseHome extends StatefulWidget {
  const CauseHome({super.key});
  @override
  State<CauseHome> createState() => _CauseHomeState();
}

class _CauseHomeState extends State<CauseHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screens = [
      _CauseDashboardTab(uid: auth.user!.uid),
      CauseDonationsScreen(uid: auth.user!.uid),
      CauseSettingsScreen(uid: auth.user!.uid),
    ];

    return Scaffold(
      body: screens[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism),
              label: 'Donaciones',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Tab ────────────────────────────────────────────────────────────

class _CauseDashboardTab extends StatefulWidget {
  final String uid;
  const _CauseDashboardTab({required this.uid});
  @override
  State<_CauseDashboardTab> createState() => _CauseDashboardTabState();
}

class _CauseDashboardTabState extends State<_CauseDashboardTab> {
  final _fs = FirestoreService();
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _fs.getCauseDashboard(widget.uid);
    if (mounted) setState(() { _stats = stats; _loadingStats = false; });
  }

  String _fmt(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Hero header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<Cause?>(
                stream: _fs.causeStream(widget.uid),
                builder: (ctx, snap) {
                  final cause    = snap.data;
                  final progress = (cause?.progress ?? 0.0) / 100;

                  return Container(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B4332), AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tu causa',
                                    style: TextStyle(color: Colors.white60, fontSize: 13),
                                  ),
                                  Text(
                                    cause?.name ?? 'Mi Causa',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await auth.signOut();
                                if (ctx.mounted) {
                                  Navigator.pushReplacement(
                                    ctx,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                }
                              },
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Progress section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _fmt(cause?.totalRaised ?? 0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Meta: ${_fmt(cause?.targetAmount ?? 0)}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}% alcanzado',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearPercentIndicator(
                          lineHeight: 8,
                          percent: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.white24,
                          progressColor: AppColors.accent,
                          barRadius: const Radius.circular(4),
                          padding: EdgeInsets.zero,
                          animation: true,
                          animationDuration: 800,
                        ),

                        if (cause?.description != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            cause!.description,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats grid ────────────────────────────────
                    if (_loadingStats)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else ...[
                      Row(children: [
                        Expanded(
                          child: StatCard(
                            label: 'Donaciones hoy',
                            value: _fmt(_stats['todayDonations']?.toDouble() ?? 0),
                            icon: Icons.volunteer_activism,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Total recaudado',
                            value: _fmt(_stats['totalRaised']?.toDouble() ?? 0),
                            icon: Icons.savings_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: StatCard(
                            label: 'Pendiente de cobro',
                            value: _fmt(_stats['pendingAmount']?.toDouble() ?? 0),
                            icon: Icons.pending_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Restaurantes',
                            value: '${_stats['restaurantCount'] ?? 0}',
                            icon: Icons.restaurant_rounded,
                            color: AppColors.info,
                          ),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 28),

                    // ── Recent donations ──────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Donaciones recientes',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Ver todas',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _fs.causeDonationsStream(widget.uid, 'pending'),
                      builder: (ctx, snap) {
                        final donations = snap.data ?? [];
                        if (donations.isEmpty) {
                          return _EmptyState(
                            icon: Icons.volunteer_activism_outlined,
                            text: 'Aún no hay donaciones pendientes',
                          );
                        }
                        return Column(
                          children: donations.take(5).map((d) => _DonationCard(
                            donation: d,
                            onConfirm: () async {
                              await _fs.confirmDonationReceived(
                                d['id'], d['orderId'], widget.uid,
                              );
                            },
                          )).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
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

// ── Donation card ─────────────────────────────────────────────────────────────

class _DonationCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final VoidCallback onConfirm;
  const _DonationCard({required this.donation, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final amount = (donation['amount'] ?? 0.0).toDouble();
    final status = donation['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation['restaurantName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  donation['customerName'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // Amount + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              DonationBadge(status: status),
              if (status == 'paid') ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Confirmar recibo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.border),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
