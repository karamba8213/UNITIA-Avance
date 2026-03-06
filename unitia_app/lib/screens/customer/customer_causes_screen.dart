import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/cause.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';
import 'cart_screen.dart';
import 'cause_detail_screen.dart';
import 'cause_ranking_screen.dart';

class CustomerCausesScreen extends StatefulWidget {
  const CustomerCausesScreen({super.key});
  @override
  State<CustomerCausesScreen> createState() => _CustomerCausesScreenState();
}

class _CustomerCausesScreenState extends State<CustomerCausesScreen> {
  final _fs = FirestoreService();
  final _searchCtrl = TextEditingController();

  List<Cause> _causes = [];
  List<Cause> _filtered = [];
  bool _loading = true;

  // Filtros
  final _filters = ['All', 'Nearby', 'Education', 'Food', 'Environment'];
  int _activeFilter = 0;

  @override
  void initState() {
    super.initState();
    _loadCauses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCauses() async {
    final causes = await _fs.getActiveCauses();
    if (mounted) setState(() { _causes = causes; _filtered = causes; _loading = false; });
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _causes
          : _causes.where((c) =>
              c.name.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row with cart icon ──────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(), // spacer
                        Consumer<CartProvider>(
                          builder: (_, cart, __) => GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const CartScreen())),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: cardShadow,
                                  ),
                                  child: const Icon(Icons.shopping_cart_outlined,
                                      color: AppColors.textPrimary, size: 20),
                                ),
                                if (cart.itemCount > 0)
                                  Positioned(
                                    top: -4, right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text('${cart.itemCount}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          )),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Who are you\nsupporting today?',
                        style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 16),

                    // Cause code input
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                hintText: 'e.g. CAUSE123',
                                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Apply',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search
                    AppSearchBar(
                      hint: 'Search causes...',
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                    ),
                    const SizedBox(height: 16),

                    // Filter chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => setState(() => _activeFilter = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _activeFilter == i
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _activeFilter == i
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              _filters[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _activeFilter == i
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Featured header ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Featured',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const CauseRankingScreen())),
                      child: const Text('RANKING',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          )),
                    ),
                  ],
                ),
              ),
            ),

            // ── Featured horizontal scroll ─────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        itemCount: _filtered.take(5).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, i) => _FeaturedCard(cause: _filtered[i]),
                      ),
              ),
            ),

            // ── All causes grid ───────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i >= _filtered.length) return null;
                    return _CauseGridCard(cause: _filtered[i]);
                  },
                  childCount: _filtered.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 12,
                  childAspectRatio: 4.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured card (horizontal) ────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Cause cause;
  const _FeaturedCard({required this.cause});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: null,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CauseDetailScreen(cause: cause))),
      child: SizedBox(
        width: 200,
        child: Stack(
          children: [
            // Imagen / placeholder
            Container(
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.7),
                    AppColors.primaryLight.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: cause.logo != null
                  ? Image.network(cause.logo!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox())
                  : const Center(
                      child: Icon(Icons.volunteer_activism,
                          color: Colors.white54, size: 48)),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ImpactBadge(label: '5% DONATED'),
                    const SizedBox(height: 6),
                    Text(
                      cause.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Trending badge
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('TRENDING',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cause grid card (list style) ──────────────────────────────────────────────
class _CauseGridCard extends StatelessWidget {
  final Cause cause;
  const _CauseGridCard({required this.cause});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CauseDetailScreen(cause: cause))),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Imagen
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: cause.logo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(cause.logo!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.store_rounded, color: AppColors.primary, size: 26)),
                  )
                : const Icon(Icons.store_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cause.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  cause.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Badge + select
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ImpactBadge(label: '5% Impact'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('SELECT',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
