import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurant.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';
import 'cart_screen.dart';
import 'customer_restaurant_menu_screen.dart';

// ── Categories (Rappi / Uber Eats style) ──────────────────────────────────────
class _Category {
  final String label;
  final String emoji;
  const _Category(this.label, this.emoji);
}

const _categories = [
  _Category('All',        '🍽️'),
  _Category('Mexican',    '🌮'),
  _Category('Burgers',    '🍔'),
  _Category('Pizza',      '🍕'),
  _Category('Sushi',      '🍣'),
  _Category('Asian',      '🍜'),
  _Category('Healthy',    '🥗'),
  _Category('Chicken',    '🍗'),
  _Category('Sandwiches', '🥪'),
  _Category('Seafood',    '🦐'),
  _Category('Desserts',   '🍰'),
  _Category('Coffee',     '☕'),
  _Category('Drinks',     '🧃'),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class CustomerEatsScreen extends StatefulWidget {
  const CustomerEatsScreen({super.key});

  @override
  State<CustomerEatsScreen> createState() => _CustomerEatsScreenState();
}

class _CustomerEatsScreenState extends State<CustomerEatsScreen> {
  final _fs         = FirestoreService();
  final _searchCtrl = TextEditingController();

  List<Restaurant> _all      = [];
  List<Restaurant> _filtered = [];
  Position? _userPos;
  bool _loading     = true;
  bool _locLoading  = true;
  int  _catIndex    = 0;   // 0 = All

  @override
  void initState() {
    super.initState();
    _initLocation();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) { setState(() => _locLoading = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() => _locLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) setState(() { _userPos = pos; _locLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _locLoading = false);
    }
    _applyFilters();
  }

  Future<void> _load() async {
    final list = await _fs.getActiveRestaurants();
    if (mounted) setState(() { _all = list; _loading = false; });
    _applyFilters();
  }

  // ── Haversine distance in km ──────────────────────────────
  double _distKm(Restaurant r) {
    if (_userPos == null || r.latitude == null || r.longitude == null) {
      return double.infinity;
    }
    const R = 6371.0;
    final lat1 = _userPos!.latitude * pi / 180;
    final lat2 = r.latitude! * pi / 180;
    final dLat = (r.latitude! - _userPos!.latitude) * pi / 180;
    final dLon = (r.longitude! - _userPos!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _distLabel(Restaurant r) {
    final d = _distKm(r);
    if (d == double.infinity) return '';
    if (d < 1) return '${(d * 1000).round()} m';
    return '${d.toStringAsFixed(1)} km';
  }

  void _applyFilters() {
    if (!mounted) return;
    final q   = _searchCtrl.text.toLowerCase();
    final cat = _categories[_catIndex].label;

    List<Restaurant> list = _all.where((r) {
      final matchCat  = cat == 'All' || (r.category ?? '').toLowerCase() == cat.toLowerCase();
      final matchText = q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          (r.description ?? '').toLowerCase().contains(q);
      return matchCat && matchText;
    }).toList();

    // Sort by distance (closest first), unknowns at the end
    list.sort((a, b) => _distKm(a).compareTo(_distKm(b)));

    setState(() => _filtered = list);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order & Donate',
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _userPos != null
                                      ? Icons.location_on_rounded
                                      : Icons.location_off_rounded,
                                  size: 13,
                                  color: _userPos != null
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _locLoading
                                      ? 'Getting location...'
                                      : _userPos != null
                                          ? 'Sorted by distance'
                                          : 'Location unavailable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _userPos != null
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Cart icon
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const CartScreen())),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: cardShadow,
                                ),
                                child: const Icon(Icons.shopping_cart_outlined,
                                    color: AppColors.textPrimary, size: 22),
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    AppSearchBar(
                      hint: 'Search restaurants...',
                      controller: _searchCtrl,
                      onChanged: (_) => _applyFilters(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Category chips ───────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final cat      = _categories[i];
                    final selected = _catIndex == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _catIndex = i);
                        _applyFilters();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: selected ? null : cardShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Loading ──────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
              )

            // ── Empty ────────────────────────────────────────
            else if (_filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🍽️',
                          style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        _searchCtrl.text.isEmpty
                            ? 'No restaurants in this category yet'
                            : 'No results for "${_searchCtrl.text}"',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )

            // ── Restaurant list ──────────────────────────────
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RestaurantCard(
                      restaurant: _filtered[i],
                      distLabel: _distLabel(_filtered[i]),
                    ),
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // ── Floating cart bar ────────────────────────────────────
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: primaryShadow,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${cart.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('View Cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                        Text(
                            '\$${cart.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Restaurant card ────────────────────────────────────────────────────────────
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final String distLabel;
  const _RestaurantCard(
      {required this.restaurant, required this.distLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CustomerRestaurantMenuScreen(
                  restaurant: restaurant)),
        ),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: restaurant.logo != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(
                            restaurant.logo!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.store_rounded,
                                  color: Colors.white54, size: 40),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.store_rounded,
                              color: Colors.white54, size: 40),
                        ),
                ),
                // Distance badge
                if (distLabel.isNotEmpty)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 3),
                          Text(distLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
                // Category badge
                if (restaurant.category != null)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_emojiForCategory(restaurant.category!)} ${restaurant.category!}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Info row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurant.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(
                          restaurant.description ??
                              restaurant.address ??
                              'Local restaurant',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ImpactBadge(
                    label:
                        '${restaurant.donationPercentage.toStringAsFixed(0)}% Impact',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emojiForCategory(String cat) {
    return switch (cat.toLowerCase()) {
      'mexican'    => '🌮',
      'burgers'    => '🍔',
      'pizza'      => '🍕',
      'sushi'      => '🍣',
      'asian'      => '🍜',
      'healthy'    => '🥗',
      'chicken'    => '🍗',
      'sandwiches' => '🥪',
      'seafood'    => '🦐',
      'desserts'   => '🍰',
      'coffee'     => '☕',
      'drinks'     => '🧃',
      _            => '🍽️',
    };
  }
}
