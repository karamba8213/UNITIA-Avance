import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurant.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import 'cart_screen.dart';

class CustomerRestaurantMenuScreen extends StatefulWidget {
  final Restaurant restaurant;
  const CustomerRestaurantMenuScreen({super.key, required this.restaurant});

  @override
  State<CustomerRestaurantMenuScreen> createState() =>
      _CustomerRestaurantMenuScreenState();
}

class _CustomerRestaurantMenuScreenState
    extends State<CustomerRestaurantMenuScreen> {
  final _fs = FirestoreService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCity());
    _load();
  }

  void _checkCity() {
    final cart = context.read<CartProvider>();
    final customerCity = cart.selectedCity;
    final restaurantCity = widget.restaurant.city;
    if (customerCity != null &&
        restaurantCity != null &&
        restaurantCity.toLowerCase() != customerCity.toLowerCase()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Restaurante no disponible',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(
            'Este restaurante está en $restaurantCity y tú estás en $customerCity.\n\nSolo puedes pedir de restaurantes en tu ciudad.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }
    cart.setRestaurant(widget.restaurant);
  }

  Future<void> _load() async {
    final items = await _fs.getMenuItems(widget.restaurant.id);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final item in _items) {
      final cat = (item['category'] as String?) ?? 'Other';
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final r    = widget.restaurant;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _CartBadge(count: cart.itemCount, onTap: () => _openCart(context)),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(r.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 4),
                        if (r.address != null)
                          Text(r.address!,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${r.donationPercentage.toStringAsFixed(0)}% donated per order',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Menu items ─────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_items.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No menu items available',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final categories = _grouped.keys.toList();
                    if (i >= categories.length) return null;
                    final cat   = categories[i];
                    final items = _grouped[cat]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (i > 0) const SizedBox(height: 24),
                        Text(cat,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 12),
                        ...items.map((item) => _MenuItem(item: item, cart: cart)),
                      ],
                    );
                  },
                  childCount: _grouped.length,
                ),
              ),
            ),
        ],
      ),

      // ── View Cart FAB ───────────────────────────────────────
      bottomNavigationBar: cart.isEmpty
          ? null
          : _ViewCartBar(
              cart: cart,
              onTap: () => _openCart(context),
            ),
    );
  }

  void _openCart(BuildContext ctx) {
    final cart = ctx.read<CartProvider>();
    if (cart.selectedCause == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Elige una causa antes de ir al carrito'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CartScreen()));
  }
}

// ── Menu item row ──────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final CartProvider cart;
  const _MenuItem({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final id    = item['id'] as String;
    final name  = item['name'] as String? ?? '';
    final desc  = item['description'] as String? ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final qty   = cart.quantityOf(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: item['imageUrl'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(item['imageUrl'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.fastfood_rounded,
                                  color: AppColors.primary, size: 32)),
                    )
                  : const Icon(Icons.fastfood_rounded,
                      color: AppColors.primary, size: 32),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Text('\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Qty controls
            qty == 0
                ? GestureDetector(
                    onTap: () => cart.add(item),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QtyBtn(
                        icon: Icons.remove,
                        onTap: () => cart.remove(id),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$qty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                      _QtyBtn(
                        icon: Icons.add,
                        onTap: () => cart.add(item),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 16),
      ),
    );
  }
}

// ── Cart badge in AppBar ───────────────────────────────────────────────────────
class _CartBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CartBadge({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 20),
          ),
          if (count > 0)
            Positioned(
              top: -4, right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text('$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

// ── View Cart bottom bar ───────────────────────────────────────────────────────
class _ViewCartBar extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onTap;
  const _ViewCartBar({required this.cart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: GestureDetector(
          onTap: onTap,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                const Expanded(
                  child: Text('View Cart',
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
    );
  }
}
