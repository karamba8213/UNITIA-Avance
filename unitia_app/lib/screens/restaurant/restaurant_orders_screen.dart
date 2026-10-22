import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/order.dart';
import '../../core/models/restaurant.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../shared/order_chat_screen.dart';
import 'restaurant_credits_screen.dart';

class RestaurantOrdersScreen extends StatefulWidget {
  final String uid;
  const RestaurantOrdersScreen({super.key, required this.uid});

  @override
  State<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends State<RestaurantOrdersScreen> {
  int _tab = 0;
  final Set<String> _knownOrderIds = {};
  List<Order> _latestOrders = [];
  Timer? _urgentTimer;

  @override
  void initState() {
    super.initState();
    _urgentTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      for (final order in _latestOrders) {
        if (order.status != OrderStatus.pending) continue;
        final waited = now.difference(order.createdAt);
        if (waited.inSeconds >= 60) {
          NotificationService.showUrgentOrder(order, waited.inMinutes);
        }
      }
    });
  }

  @override
  void dispose() {
    _urgentTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            StreamBuilder<Restaurant?>(
              stream: fs.restaurantStream(widget.uid),
              builder: (ctx, snap) {
                final restaurant = snap.data;
                final isActive = restaurant?.isActive ?? true;
                return Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pedidos',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          // Live indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PulseDot(),
                                SizedBox(width: 5),
                                Text('En vivo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ── Toggle activo / inactivo ──────────
                      GestureDetector(
                        onTap: restaurant == null ? null : () {
                          fs.setRestaurantActive(widget.uid, !isActive);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? AppColors.success : AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.success : AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isActive
                                      ? 'Abierto — aceptando pedidos'
                                      : 'Cerrado — no acepta pedidos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ),
                              Text(
                                'Cambiar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
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

            const SizedBox(height: 16),

            // ── Tabs ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: cardShadow,
                ),
                child: Row(
                  children: [
                    _TabBtn(
                        label: 'Activos',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0)),
                    _TabBtn(
                        label: 'Historial',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Orders list ──────────────────────────────────
            Expanded(
              child: StreamBuilder<Restaurant?>(
                stream: fs.restaurantStream(widget.uid),
                builder: (ctx, restaurantSnap) {
                  final restaurant = restaurantSnap.data;
                  return StreamBuilder<List<Order>>(
                    stream: fs.restaurantOrdersStream(widget.uid),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }

                      final all = snap.data ?? [];
                      _latestOrders = all;

                      // Detectar pedidos nuevos y disparar notificación local
                      for (final order in all) {
                        if (order.status == OrderStatus.pending &&
                            !_knownOrderIds.contains(order.id)) {
                          if (_knownOrderIds.isNotEmpty) {
                            NotificationService.showNewOrder(order);
                          }
                          _knownOrderIds.add(order.id);
                        }
                      }

                      // Split: activos = pending + confirmed + ready
                      final activos = all
                          .where((o) =>
                              o.status == OrderStatus.pending ||
                              o.status == OrderStatus.confirmed ||
                              o.status == OrderStatus.ready)
                          .toList()
                        ..sort((a, b) {
                          const rank = {
                            OrderStatus.pending:   0,
                            OrderStatus.confirmed: 1,
                            OrderStatus.ready:     2,
                            OrderStatus.cancelled: 3,
                          };
                          final r = rank[a.status]!.compareTo(rank[b.status]!);
                          if (r != 0) return r;
                          // Dentro de pending: más viejos primero (más urgentes)
                          if (a.status == OrderStatus.pending) {
                            return a.createdAt.compareTo(b.createdAt);
                          }
                          return b.createdAt.compareTo(a.createdAt);
                        });

                      final historial = all
                          .where((o) => o.status == OrderStatus.cancelled)
                          .toList();

                      final orders = _tab == 0 ? activos : historial;

                      if (orders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📦',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                _tab == 0
                                    ? 'Sin pedidos activos'
                                    : 'Sin historial aún',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      }

                      // Contar pedidos por cliente
                      final customerCounts = <String, int>{};
                      for (final o in all) {
                        final key = o.customerEmail?.isNotEmpty == true
                            ? o.customerEmail!
                            : o.customerName;
                        customerCounts[key] = (customerCounts[key] ?? 0) + 1;
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: orders.length,
                        itemBuilder: (_, i) {
                          final o = orders[i];
                          final key = o.customerEmail?.isNotEmpty == true
                              ? o.customerEmail!
                              : o.customerName;
                          return _OrderCard(
                            order: o,
                            restaurant: restaurant,
                            restaurantUid: widget.uid,
                            customerOrderCount: customerCounts[key] ?? 1,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab button ─────────────────────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Order card ─────────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final Order order;
  final Restaurant? restaurant;
  final String restaurantUid;
  final int customerOrderCount;
  const _OrderCard({
    required this.order,
    required this.restaurant,
    required this.restaurantUid,
    required this.customerOrderCount,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  final _fs    = FirestoreService();
  bool _acting = false;
  Timer? _ticker;

  // Auto-expand pending orders
  bool get _expanded =>
      widget.order.status == OrderStatus.pending || _manualExpand;
  bool _manualExpand = false;

  @override
  void initState() {
    super.initState();
    if (widget.order.status == OrderStatus.pending) {
      // Rebuild cada segundo para actualizar el contador de tiempo
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool _isUrgent(Order o) =>
      o.status == OrderStatus.pending &&
      DateTime.now().difference(o.createdAt).inSeconds >= 60;

  String _elapsed(Order o) {
    final d = DateTime.now().difference(o.createdAt);
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes >= 1) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  bool _canAcceptOrders(Restaurant? restaurant) {
    if (restaurant == null) return true;
    if (restaurant.creditBalance > 0) return true;
    // Same-day grace period
    final negDate = restaurant.negativeBalanceDate;
    if (negDate == null) return true;
    final today = DateTime.now();
    return negDate.year == today.year &&
        negDate.month == today.month &&
        negDate.day == today.day;
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _acting = true);
    try {
      await _fs.updateOrderStatus(widget.order.id, status);
      // Deduct 1% commission when order is confirmed
      if (status == 'confirmed') {
        await _fs.deductCommission(
            widget.restaurantUid, widget.order.subtotal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    if (mounted) setState(() => _acting = false);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final statusInfo = _statusInfo(o.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
        border: o.status == OrderStatus.pending
            ? Border.all(
                color: _isUrgent(o) ? AppColors.error : AppColors.warning,
                width:  _isUrgent(o) ? 2.5 : 1.5)
            : null,
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () =>
                setState(() => _manualExpand = !_manualExpand),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Status icon
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: statusInfo.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusInfo.icon,
                        color: statusInfo.color, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Customer info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(o.customerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                            if (widget.customerOrderCount > 1)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${widget.customerOrderCount} pedidos',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusInfo.bgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(statusInfo.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: statusInfo.color,
                                  )),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${o.createdAt.hour}:${o.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                            if (o.status == OrderStatus.pending) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isUrgent(o)
                                      ? AppColors.error.withValues(alpha: 0.12)
                                      : AppColors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _elapsed(o),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _isUrgent(o) ? AppColors.error : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${o.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      Text(
                        '+\$${o.donationAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ──────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items
                  ...o.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}× ${item.name}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                            Text(
                              '\$${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),

                  const Divider(color: AppColors.border),

                  // Envío
                  if (o.deliveryFee > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Envío:',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('\$${o.deliveryFee.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],

                  // Causa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Causa:',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      Text(o.causeName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),

                  // Dirección
                  if (o.deliveryAddress != null &&
                      o.deliveryAddress!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      text: o.deliveryAddress!,
                    ),
                  ],

                  // Teléfono
                  if (o.customerPhone != null &&
                      o.customerPhone!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => launchUrl(
                          Uri.parse('tel:${o.customerPhone}')),
                      child: _InfoRow(
                        icon: Icons.phone_rounded,
                        text: o.customerPhone!,
                        trailing: 'Llamar',
                        tappable: true,
                      ),
                    ),
                  ],

                  // Nota
                  if (o.notes != null && o.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.notes_rounded,
                      text: '"${o.notes!}"',
                      italic: true,
                    ),
                  ],

                  // ── Chat button ──────────────────────────
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      final auth = context.read<AuthProvider>();
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => OrderChatScreen(
                          orderId:         o.id,
                          currentUserId:   auth.user!.uid,
                          currentUserRole: 'restaurant',
                          currentUserName: o.restaurantName,
                          otherPartyName:  o.customerName,
                        ),
                      ));
                    },
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: AppColors.primary, size: 16),
                          SizedBox(width: 6),
                          Text('Chat con cliente',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              )),
                        ],
                      ),
                    ),
                  ),

                  // ── Action buttons ───────────────────────
                  if (o.status == OrderStatus.pending ||
                      o.status == OrderStatus.confirmed) ...[
                    const SizedBox(height: 14),
                    _ActionButtons(
                      status: o.status,
                      acting: _acting,
                      canAccept: _canAcceptOrders(widget.restaurant),
                      restaurantUid: widget.restaurantUid,
                      onConfirm: () =>
                          _updateStatus('confirmed'),
                      onReady:   () => _updateStatus('ready'),
                      onCancel:  () => _confirmCancel(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar pedido?',
            style:
                TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: const Text(
            'Esta acción no se puede deshacer. El cliente será notificado.',
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar',
                style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) _updateStatus('cancelled');
  }
}

// ── Action buttons ─────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final OrderStatus status;
  final bool acting;
  final bool canAccept;
  final String restaurantUid;
  final VoidCallback onConfirm;
  final VoidCallback onReady;
  final VoidCallback onCancel;

  const _ActionButtons({
    required this.status,
    required this.acting,
    required this.canAccept,
    required this.restaurantUid,
    required this.onConfirm,
    required this.onReady,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (acting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (status == OrderStatus.pending) {
      // If restaurant is blocked, show a blocked message instead of confirm
      if (!canAccept) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block_rounded,
                      color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cuenta suspendida — recarga créditos para continuar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RestaurantCreditsScreen(uid: restaurantUid),
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: primaryShadow,
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Recargar créditos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          // Cancelar
          Expanded(
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('Cancelar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      )),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Confirmar
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onConfirm,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: primaryShadow,
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Confirmar pedido',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // confirmed → Listo para entregar
    return GestureDetector(
      onTap: onReady,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delivery_dining_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Listo para entregar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? trailing;
  final bool tappable;
  final bool italic;
  const _InfoRow({
    required this.icon,
    required this.text,
    this.trailing,
    this.tappable = false,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tappable ? AppColors.primaryBg : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: tappable
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: tappable
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: tappable
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontStyle:
                    italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (trailing != null)
            Text(trailing!,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Status info helper ─────────────────────────────────────────────────────────
class _StatusInfo {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _StatusInfo(
      {required this.label,
      required this.color,
      required this.bgColor,
      required this.icon});
}

_StatusInfo _statusInfo(OrderStatus s) => switch (s) {
      OrderStatus.pending => _StatusInfo(
            label: 'NUEVO',
            color: AppColors.warning,
            bgColor: const Color(0xFFFFF3E0),
            icon: Icons.notifications_active_rounded),
      OrderStatus.confirmed => _StatusInfo(
            label: 'EN PREPARACIÓN',
            color: AppColors.primary,
            bgColor: AppColors.primaryBg,
            icon: Icons.restaurant_rounded),
      OrderStatus.ready => _StatusInfo(
            label: 'LISTO',
            color: AppColors.success,
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.delivery_dining_rounded),
      OrderStatus.cancelled => _StatusInfo(
            label: 'CANCELADO',
            color: AppColors.textMuted,
            bgColor: const Color(0xFFF5F5F5),
            icon: Icons.cancel_outlined),
    };

// ── Pulse dot (live indicator) ─────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
