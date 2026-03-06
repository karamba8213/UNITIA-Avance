import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/cause.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import 'order_impact_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _fs          = FirestoreService();
  final _msgCtrl     = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _placing      = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final profile = await _fs.getCustomerProfile(auth.user!.uid);
    if (profile != null && profile['deliveryAddress'] != null && mounted) {
      _addressCtrl.text = profile['deliveryAddress'] as String;
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();

    // Cause is required
    if (cart.selectedCause == null) {
      await _showCausePicker();
      if (cart.selectedCause == null) return;
    }

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a delivery address'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      final msg     = _msgCtrl.text.trim();
      final address = _addressCtrl.text.trim();

      // Save address to profile for next time
      if (auth.user != null && address.isNotEmpty) {
        _fs.updateCustomerProfile(auth.user!.uid, {'deliveryAddress': address});
      }

      final cause          = cart.selectedCause!;
      final donationAmount = cart.donationAmount;

      final orderId = await _fs.createOrder(
        restaurantId:    cart.restaurant!.id,
        restaurantName:  cart.restaurant!.name,
        causeId:         cause.id,
        causeName:       cause.name,
        customerName:    auth.user?.name ?? 'Customer',
        customerId:      auth.user?.uid,
        customerEmail:   auth.user?.email,
        notes:           msg.isEmpty ? null : msg,
        deliveryAddress: address.isEmpty ? null : address,
        items: cart.items.map((i) => i.toOrderItem().toMap()).toList(),
        subtotal:        cart.subtotal,
        donationAmount:  donationAmount,
        causeMessage:    msg.isEmpty ? null : msg,
      );

      if (!mounted) return;
      cart.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderImpactScreen(
            orderId:        orderId,
            causeName:      cause.name,
            causeId:        cause.id,
            donationAmount: donationAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _showCausePicker() async {
    final cart = context.read<CartProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CausePickerSheet(
        onSelected: (cause) {
          cart.selectCause(cause);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Your Order',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (cart.restaurant != null)
              Text(cart.restaurant!.name,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        centerTitle: true,
      ),
      body: cart.isEmpty
          ? _EmptyCart(onBack: () => Navigator.pop(context))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Delivery address ─────────────────────────
                  const Text('Delivery Address',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Where should we deliver your order?',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _addressCtrl,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. 123 Main St, Apt 4B, City',
                              hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Items ────────────────────────────────────
                  const Text('Items',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      children: cart.items
                          .map((item) => _CartItemRow(item: item, cart: cart))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Cause / Impact ───────────────────────────
                  const Text('Your Impact',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showCausePicker,
                    child: AppCard(
                      child: cart.selectedCause == null
                          ? Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.volunteer_activism_rounded,
                                      color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Choose a cause',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          )),
                                      Text('Required to place your order',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.primary),
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.favorite_rounded,
                                      color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cart.selectedCause!.name,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                        'Will receive \$${cart.donationAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textMuted),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Message to cause ─────────────────────────
                  const Text('Message to the Cause',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Optional — your words go directly to the cause team',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cart.selectedCause?.name ??
                                    'Choose a cause first',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: cart.selectedCause != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _msgCtrl,
                          maxLines: 3,
                          maxLength: 200,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'e.g. "Keep up the amazing work! Your mission inspires us every day."',
                            hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            counterStyle: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Summary ──────────────────────────────────
                  AppCard(
                    child: Column(
                      children: [
                        _SummaryRow(
                            label: 'Subtotal',
                            value: '\$${cart.subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 10),
                        _SummaryRow(
                          label:
                              'Donation (${cart.restaurant?.donationPercentage.toStringAsFixed(0) ?? '5'}%)',
                          value: '\$${cart.donationAmount.toStringAsFixed(2)}',
                          valueColor: AppColors.primary,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.border, height: 1),
                        ),
                        _SummaryRow(
                          label: 'Total',
                          value: '\$${cart.subtotal.toStringAsFixed(2)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Cash note ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.payments_outlined,
                            color: AppColors.warning, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cash Payment Only — pay at pickup or delivery',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Place Order',
                    onPressed: _placeOrder,
                    loading: _placing,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ── Cart item row ──────────────────────────────────────────────────────────────
class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;
  const _CartItemRow({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('\$${item.price.toStringAsFixed(2)} each',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Row(
            children: [
              _QtyBtn(
                  icon: Icons.remove,
                  onTap: () => cart.remove(item.menuItemId)),
              SizedBox(
                width: 28,
                child: Text('${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              _QtyBtn(
                  icon: Icons.add,
                  onTap: () => cart.add({
                        'id': item.menuItemId,
                        'name': item.name,
                        'price': item.price,
                      })),
            ],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '\$${item.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
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
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 14),
      ),
    );
  }
}

// ── Summary row ────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: valueColor ?? AppColors.textPrimary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: bold ? 15 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: AppColors.textSecondary,
            )),
        Text(value, style: style),
      ],
    );
  }
}

// ── Empty cart ─────────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyCart({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Your cart is empty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Add items from a restaurant to get started',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton(label: 'Browse Restaurants', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}

// ── Cause picker bottom sheet ──────────────────────────────────────────────────
class _CausePickerSheet extends StatefulWidget {
  final ValueChanged<Cause> onSelected;
  const _CausePickerSheet({required this.onSelected});

  @override
  State<_CausePickerSheet> createState() => _CausePickerSheetState();
}

class _CausePickerSheetState extends State<_CausePickerSheet> {
  final _fs = FirestoreService();
  List<Cause> _causes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fs.getActiveCauses().then((list) {
      if (mounted) setState(() { _causes = list; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Choose a Cause',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Your donation will go directly to this cause',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _causes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final cause = _causes[i];
                  return GestureDetector(
                    onTap: () => widget.onSelected(cause),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.volunteer_activism_rounded,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cause.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                                Text(cause.description,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
