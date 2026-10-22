import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/order.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../shared/order_chat_screen.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<Order?>(
          stream: FirestoreService().orderStream(orderId),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final order = snap.data;
            if (order == null) {
              return const Center(child: Text('Order not found'));
            }
            return _OrderView(order: order);
          },
        ),
      ),
    );
  }
}

class _OrderView extends StatelessWidget {
  final Order order;
  const _OrderView({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPending   = order.status == OrderStatus.pending;
    final isConfirmed = order.status == OrderStatus.confirmed;
    final isReady     = order.status == OrderStatus.ready;
    final isCancelled = order.status == OrderStatus.cancelled;

    final Color iconBg = isCancelled
        ? Colors.grey.shade100
        : isReady
            ? AppColors.success.withValues(alpha: 0.1)
            : isConfirmed
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.primaryBg;

    final Color iconColor = isCancelled
        ? AppColors.textMuted
        : isReady
            ? AppColors.success
            : isConfirmed
                ? AppColors.primary
                : AppColors.primary;

    final IconData iconData = isCancelled
        ? Icons.cancel_rounded
        : isReady
            ? Icons.delivery_dining_rounded
            : isConfirmed
                ? Icons.restaurant_rounded
                : Icons.hourglass_top_rounded;

    final String title = isCancelled
        ? 'Pedido cancelado'
        : isReady
            ? '¡Listo para entregar!'
            : isConfirmed
                ? '¡Pedido confirmado!'
                : '¡Pedido enviado!';

    final String subtitle = isCancelled
        ? 'El restaurante canceló tu pedido.'
        : isReady
            ? 'Tu pedido está listo. El restaurante lo entregará pronto.'
            : isConfirmed
                ? 'Tu pedido está siendo preparado.'
                : 'Esperando confirmación del restaurante.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ── Status icon ──────────────────────────────────
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(iconData, color: iconColor, size: 48),
          ),
          const SizedBox(height: 20),

          Text(title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Order #${order.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 28),

          // ── Restaurant info ──────────────────────────────
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.store_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.restaurantName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const Text('Cash payment on delivery',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.grey.shade100
                        : isReady
                            ? AppColors.success.withValues(alpha: 0.1)
                            : isConfirmed
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCancelled ? 'Cancelado' : isReady ? 'Listo' : isConfirmed ? 'Confirmado' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCancelled
                          ? AppColors.textMuted
                          : isReady
                              ? AppColors.success
                              : isConfirmed
                                  ? AppColors.primary
                                  : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Impact / Cause ───────────────────────────────
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Impact',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text(order.causeName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text(
                  '+\$${order.donationAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Delivery address ─────────────────────────
          if ((order.deliveryAddress ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          Text(order.deliveryAddress!,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Items ────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text('${item.quantity}x',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item.name,
                                style:
                                    const TextStyle(fontSize: 13)),
                          ),
                          Text('\$${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
                const Divider(color: AppColors.border, height: 20),
                if (order.deliveryFee > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Envío', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('\$${order.deliveryFee.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text('\$${(order.subtotal + order.deliveryFee).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Cash note ────────────────────────────────────
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
                    'Remember to pay in cash when you receive your order.',
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

          const SizedBox(height: 28),

          // ── Chat con restaurante ──────────────────────────
          Builder(builder: (ctx) {
            final auth = ctx.read<AuthProvider>();
            return OutlinedButton.icon(
              onPressed: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => OrderChatScreen(
                  orderId:         order.id,
                  currentUserId:   auth.user?.uid ?? '',
                  currentUserRole: 'customer',
                  currentUserName: order.customerName,
                  otherPartyName:  order.restaurantName,
                ),
              )),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Chat con el restaurante'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            );
          }),
          const SizedBox(height: 12),

          AppButton(
            label: 'Back to Home',
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
