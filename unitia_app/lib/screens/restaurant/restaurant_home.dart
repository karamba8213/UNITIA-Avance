import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/donation_badge.dart';
import '../auth/login_screen.dart';
import 'restaurant_menu_screen.dart';
import 'restaurant_orders_screen.dart';
import 'restaurant_donations_screen.dart';
import 'restaurant_settings_screen.dart';
import 'restaurant_credits_screen.dart';

class RestaurantHome extends StatefulWidget {
  const RestaurantHome({super.key});
  @override
  State<RestaurantHome> createState() => _RestaurantHomeState();
}

class _RestaurantHomeState extends State<RestaurantHome> {
  int _tab = 0;
  final _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _saveFcmToken();
  }

  Future<void> _saveFcmToken() async {
    final token = NotificationService.fcmToken;
    if (token == null) return;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    await _fs.updateRestaurant(uid, {'fcmToken': token});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screens = [
      _DashboardTab(uid: auth.user!.uid),
      RestaurantOrdersScreen(uid: auth.user!.uid),
      RestaurantDonationsScreen(uid: auth.user!.uid, name: auth.user!.name),
      RestaurantMenuScreen(uid: auth.user!.uid),
      RestaurantSettingsScreen(uid: auth.user!.uid),
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
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Pedidos',
            ),
            NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism),
              label: 'Donaciones',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu_rounded),
              label: 'Menú',
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

class _DashboardTab extends StatefulWidget {
  final String uid;
  const _DashboardTab({required this.uid});
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _fs = FirestoreService();
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _fs.getRestaurantDashboard(widget.uid);
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
            // ── Header hero ─────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder(
                stream: _fs.restaurantStream(widget.uid),
                builder: (ctx, snap) {
                  final r = snap.data;
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hola 👋',
                                  style: TextStyle(color: Colors.white60, fontSize: 14),
                                ),
                                Text(
                                  r?.name ?? 'Mi Restaurante',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
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
                        const SizedBox(height: 16),
                        // Cause chip
                        if (r?.causeId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Apoyando a ${r!.causeName ?? ''} · ${r.donationPercentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Elegir una causa que apoyar',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                            label: 'Pedidos hoy',
                            value: '${_stats['todayOrders'] ?? 0}',
                            icon: Icons.shopping_bag_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Ventas hoy',
                            value: _fmt(_stats['todayRevenue']?.toDouble() ?? 0),
                            icon: Icons.trending_up_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
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
                            label: 'Pendiente de pago',
                            value: _fmt(_stats['totalPending']?.toDouble() ?? 0),
                            sub: '${_stats['countPending'] ?? 0} pedidos',
                            icon: Icons.pending_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 28),

                    // ── Quick actions ─────────────────────────────
                    const Text(
                      'Acciones rápidas',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder(
                      stream: _fs.restaurantStream(widget.uid),
                      builder: (ctx, snap) {
                        final creditBalance =
                            snap.data?.creditBalance ?? 0.0;
                        return Row(children: [
                          _QuickAction(
                            icon: Icons.volunteer_activism,
                            label: 'Donaciones',
                            color: AppColors.accent,
                            bg: AppColors.accentBg,
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.bolt_rounded,
                            label: 'Créditos',
                            sub: '\$${creditBalance.toStringAsFixed(0)}',
                            color: creditBalance > 0
                                ? AppColors.success
                                : AppColors.error,
                            bg: creditBalance > 0
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => RestaurantCreditsScreen(
                                  uid: widget.uid,
                                ),
                              ),
                            ),
                          ),
                        ]);
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── Recent orders ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pedidos recientes',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Ver todos',
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
                      stream: _fs.restaurantOrdersRawStream(widget.uid),
                      builder: (ctx, snap) {
                        final orders = snap.data ?? [];
                        if (orders.isEmpty) {
                          return _EmptyState(
                            icon: Icons.receipt_long_rounded,
                            text: 'Aún no hay pedidos',
                          );
                        }
                        return Column(
                          children: orders.take(5)
                              .map((o) => _OrderCard(order: o))
                              .toList(),
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

// ── Quick action chip ────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    this.sub,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final dynamic order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final donation  = (order['donationAmount'] ?? 0.0).toDouble();
    final subtotal  = (order['subtotal'] ?? 0.0).toDouble();
    final createdAt = order['createdAt'];

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
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['customerName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 3),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt.toDate()),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          // Amounts + badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                '+\$${donation.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              DonationBadge(status: order['donationStatus'] ?? 'pending'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month) {
      return 'Hoy ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
