import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/restaurant.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';
import 'cart_screen.dart';
import 'customer_restaurant_menu_screen.dart';

// dbValue = category stored in Firestore (Spanish); empty = "all"
class _Category {
  final String dbValue;
  final String emoji;
  const _Category(this.dbValue, this.emoji);
}

const _categories = [
  _Category('',            '🍽️'),
  _Category('Mexicana',    '🌮'),
  _Category('Hamburguesas','🍔'),
  _Category('Pizza',       '🍕'),
  _Category('Sushi',       '🍣'),
  _Category('Asiática',    '🍜'),
  _Category('Saludable',   '🥗'),
  _Category('Pollo',       '🍗'),
  _Category('Sandwiches',  '🥪'),
  _Category('Mariscos',    '🦐'),
  _Category('Postres',     '🍰'),
  _Category('Café',        '☕'),
  _Category('Bebidas',     '🧃'),
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
  bool _loading    = true;
  bool _locLoading = true;
  int  _catIndex   = 0;

  // City filter
  String? _selectedCity;   // null = "Todas las ciudades"
  List<String> _cities = [];

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

  // ── Location ──────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) { if (mounted) setState(() => _locLoading = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) setState(() => _locLoading = false);
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

  // ── Load restaurants ──────────────────────────────────────
  Future<void> _load() async {
    final list = await _fs.getActiveRestaurants();
    if (!mounted) return;

    // Extract unique cities (non-null, sorted)
    final citySet = <String>{};
    for (final r in list) {
      if (r.city != null && r.city!.isNotEmpty) citySet.add(r.city!);
    }
    final cities = citySet.toList()..sort();

    // Auto-select nearest city once we have GPS
    String? autoCity;
    if (_userPos != null && list.isNotEmpty) {
      autoCity = _nearestCity(list, cities);
    }

    setState(() {
      _all          = list;
      _loading      = false;
      _cities       = cities;
      _selectedCity = autoCity;
    });
    if (autoCity != null) context.read<CartProvider>().setCity(autoCity);
    _applyFilters();
  }

  // ── Find nearest city by proximity ───────────────────────
  String? _nearestCity(List<Restaurant> list, List<String> cities) {
    if (_userPos == null || cities.isEmpty) return null;
    final Map<String, double> cityDist = {};
    for (final r in list) {
      if (r.city == null || r.city!.isEmpty) continue;
      final d = _distKm(r);
      if (!cityDist.containsKey(r.city) || d < cityDist[r.city]!) {
        cityDist[r.city!] = d;
      }
    }
    if (cityDist.isEmpty) return null;
    return cityDist.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
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

  // ── Apply all filters ─────────────────────────────────────
  void _applyFilters() {
    if (!mounted) return;
    final q   = _searchCtrl.text.toLowerCase();
    final cat = _categories[_catIndex];

    List<Restaurant> list = _all.where((r) {
      // City filter
      final matchCity = _selectedCity == null ||
          (r.city ?? '').toLowerCase() == _selectedCity!.toLowerCase();
      // Category filter
      final matchCat = cat.dbValue.isEmpty ||
          (r.category ?? '').toLowerCase() == cat.dbValue.toLowerCase();
      // Search filter
      final matchText = q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          (r.description ?? '').toLowerCase().contains(q) ||
          (r.city ?? '').toLowerCase().contains(q);
      return matchCity && matchCat && matchText;
    }).toList();

    // Sort by distance
    list.sort((a, b) => _distKm(a).compareTo(_distKm(b)));
    setState(() => _filtered = list);
  }

  // ── City picker bottom sheet ──────────────────────────────
  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).eatsSelectCity,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            // "Todas" option
            _CityOption(
              city: AppLocalizations.of(context).eatsAllCities,
              icon: Icons.public_rounded,
              selected: _selectedCity == null,
              onTap: () {
                setState(() => _selectedCity = null);
                context.read<CartProvider>().setCity(null);
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ..._cities.map((city) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CityOption(
                city: city,
                icon: Icons.location_city_rounded,
                selected: _selectedCity == city,
                onTap: () {
                  setState(() => _selectedCity = city);
                  context.read<CartProvider>().setCity(city);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final l10n = AppLocalizations.of(context);

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
                        // Location / city selector
                        GestureDetector(
                          onTap: _cities.isNotEmpty ? _showCityPicker : null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: _selectedCity != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _locLoading
                                    ? l10n.eatsGettingLocation
                                    : _selectedCity ?? l10n.eatsAllCities,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedCity != null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (_cities.isNotEmpty) ...[
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 16, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                        // Cart icon
                        GestureDetector(
                          onTap: () {
                            if (context.read<CartProvider>().selectedCause == null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(l10n.eatsPickCauseFirst),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ));
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                          },
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

                    const SizedBox(height: 12),
                    Text(l10n.eatsTitle,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                    const SizedBox(height: 14),

                    // Search bar
                    AppSearchBar(
                      hint: l10n.eatsSearchHint,
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
                    final catLabels = [
                      l10n.catAll, l10n.catMexican, l10n.catBurgers,
                      l10n.catPizza, l10n.catSushi, l10n.catAsian,
                      l10n.catHealthy, l10n.catChicken, l10n.catSandwiches,
                      l10n.catSeafood, l10n.catDesserts, l10n.catCoffee,
                      l10n.catDrinks,
                    ];
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
                              catLabels[i],
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

            // ── Results header ───────────────────────────────
            if (!_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        l10n.eatsRestaurantsCount(_filtered.length),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_selectedCity != null) ...[
                        Text(' ${l10n.eatsIn} ',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        Text(_selectedCity!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            )),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedCity = null);
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.border,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 12,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 4)),

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
                        _selectedCity != null
                            ? l10n.eatsNoRestaurantsCity(_selectedCity!)
                            : l10n.eatsNoRestaurantsCategory,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedCity != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedCity = null);
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(l10n.eatsViewAllCities,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                )),
                          ),
                        ),
                      ],
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
                  onTap: () {
                    if (context.read<CartProvider>().selectedCause == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context).eatsPickCauseFirst),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: primaryShadow,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
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
                        Expanded(
                          child: Text(AppLocalizations.of(context).eatsViewCart,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                        Text('\$${cart.subtotal.toStringAsFixed(2)}',
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

// ── City option tile ──────────────────────────────────────────────────────────
class _CityOption extends StatelessWidget {
  final String city;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _CityOption({
    required this.city,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBg : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(city,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  )),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
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
              builder: (_) =>
                  CustomerRestaurantMenuScreen(restaurant: restaurant)),
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
                        Row(
                          children: [
                            if (restaurant.city != null) ...[
                              const Icon(Icons.location_city_rounded,
                                  size: 12,
                                  color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(restaurant.city!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500)),
                              const Text(' · ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                            ],
                            Flexible(
                              child: Text(
                                restaurant.description ??
                                    restaurant.address ??
                                    AppLocalizations.of(context).eatsLocalRestaurant,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
      'mexicana' || 'mexican'      => '🌮',
      'hamburguesas' || 'burgers'  => '🍔',
      'pizza'                      => '🍕',
      'sushi'                      => '🍣',
      'asiática' || 'asian'        => '🍜',
      'saludable' || 'healthy'     => '🥗',
      'pollo' || 'chicken'         => '🍗',
      'sandwiches'                 => '🥪',
      'mariscos' || 'seafood'      => '🦐',
      'postres' || 'desserts'      => '🍰',
      'café' || 'coffee'           => '☕',
      'bebidas' || 'drinks'        => '🧃',
      _                            => '🍽️',
    };
  }
}
