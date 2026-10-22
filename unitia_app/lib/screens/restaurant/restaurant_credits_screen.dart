import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/models/restaurant.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

// ─── Product IDs ─────────────────────────────────────────────────────────────
const Set<String> _kProductIds = {
  'unitia_credits_100',
  'unitia_credits_500',
  'unitia_credits_1000',
};

const Map<String, double> _kCreditAmounts = {
  'unitia_credits_100': 100.0,
  'unitia_credits_500': 500.0,
  'unitia_credits_1000': 1000.0,
};

const Map<String, String> _kProductLabels = {
  'unitia_credits_100': '100 créditos',
  'unitia_credits_500': '500 créditos',
  'unitia_credits_1000': '1,000 créditos',
};

const Map<String, String> _kProductPrices = {
  'unitia_credits_100': '\$100 MXN',
  'unitia_credits_500': '\$500 MXN',
  'unitia_credits_1000': '\$1,000 MXN',
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class RestaurantCreditsScreen extends StatefulWidget {
  final String uid;
  const RestaurantCreditsScreen({super.key, required this.uid});

  @override
  State<RestaurantCreditsScreen> createState() =>
      _RestaurantCreditsScreenState();
}

class _RestaurantCreditsScreenState extends State<RestaurantCreditsScreen> {
  final _fs = FirestoreService();
  final _iap = InAppPurchase.instance;

  bool _iapAvailable = false;
  bool _iapLoading = true;
  bool _purchasing = false;

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _initIap();
  }

  Future<void> _initIap() async {
    try {
      final available = await _iap.isAvailable()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);

      if (!available) {
        if (mounted) setState(() { _iapAvailable = false; _iapLoading = false; });
        return;
      }

      // Listen to purchase updates
      _purchaseSubscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (e) {
          if (mounted) _showSnack('Error en compra: $e', isError: true);
        },
      );

      // Load products
      final response = await _iap
          .queryProductDetails(_kProductIds)
          .timeout(const Duration(seconds: 8), onTimeout: () => ProductDetailsResponse(
            productDetails: [],
            notFoundIDs: _kProductIds.toList(),
            error: null,
          ));

      if (mounted) {
        setState(() {
          _iapAvailable = true;
          _iapLoading = false;
          _products = response.productDetails
            ..sort((a, b) {
              final aAmt = _kCreditAmounts[a.id] ?? 0;
              final bAmt = _kCreditAmounts[b.id] ?? 0;
              return aAmt.compareTo(bAmt);
            });
        });
      }
    } catch (_) {
      if (mounted) setState(() { _iapAvailable = false; _iapLoading = false; });
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _purchasing = true);
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Deliver the credits
        final amount = _kCreditAmounts[purchase.productID] ?? 0.0;
        if (amount > 0) {
          await _fs.addCredits(
            widget.uid,
            amount,
            purchase.purchaseID ?? '',
            purchase.productID,
          );
          if (mounted) {
            _showSnack(
              '${amount.toStringAsFixed(0)} créditos agregados exitosamente',
              isError: false,
            );
          }
        }
        await _iap.completePurchase(purchase);
        if (mounted) setState(() => _purchasing = false);
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          _showSnack(
            'Error: ${purchase.error?.message ?? 'Compra fallida'}',
            isError: true,
          );
          setState(() => _purchasing = false);
        }
        await _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _purchasing = false);
      }
    }
  }

  void _buyProduct(ProductDetails product) {
    if (_purchasing) return;
    final param = PurchaseParam(productDetails: product);
    _iap.buyConsumable(purchaseParam: param);
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  // ── Credit status helpers ─────────────────────────────────────────────────

  _CreditStatus _computeStatus(double balance, DateTime? negDate) {
    if (balance > 0) return _CreditStatus.active;
    if (negDate == null) return _CreditStatus.active;
    final today = DateTime.now();
    final sameDay = negDate.year == today.year &&
        negDate.month == today.month &&
        negDate.day == today.day;
    return sameDay ? _CreditStatus.warningToday : _CreditStatus.blocked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Créditos de plataforma',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<double>(
        stream: _fs.creditBalanceStream(widget.uid),
        builder: (context, balanceSnap) {
          // Also listen to restaurant for negativeBalanceDate
          return StreamBuilder<Restaurant?>(
            stream: _fs.restaurantStream(widget.uid),
            builder: (context, restSnap) {
              final balance = balanceSnap.data ?? 0.0;
              final negDate = restSnap.data?.negativeBalanceDate;
              final creditStatus = _computeStatus(balance, negDate);

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Balance card ────────────────────────────────────────
                  _BalanceCard(
                    balance: balance,
                    status: creditStatus,
                    loading: balanceSnap.connectionState == ConnectionState.waiting,
                  ),

                  const SizedBox(height: 24),

                  // ── Buy credits section ─────────────────────────────────
                  const Text(
                    'Recargar créditos',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1 crédito = \$1 peso MXN. Se descuenta 1% de cada pedido confirmado.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_iapLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (!_iapAvailable)
                    _IapUnavailableCard()
                  else if (_products.isEmpty)
                    _DevModeCard(
                      onSimulate: (productId) async {
                        final amount = _kCreditAmounts[productId] ?? 0.0;
                        await _fs.addCredits(
                          widget.uid,
                          amount,
                          'dev_${DateTime.now().millisecondsSinceEpoch}',
                          productId,
                        );
                        if (mounted) {
                          _showSnack(
                            '${amount.toStringAsFixed(0)} créditos agregados (modo dev)',
                            isError: false,
                          );
                        }
                      },
                    )
                  else
                    // Real IAP products
                    Column(
                      children: _products
                          .map(
                            (p) => _ProductCard(
                              product: p,
                              creditAmount: _kCreditAmounts[p.id] ?? 0,
                              onBuy: _purchasing ? null : () => _buyProduct(p),
                              loading: _purchasing,
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 28),

                  // ── Transaction history ─────────────────────────────────
                  const Text(
                    'Historial de créditos',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _fs.creditTransactionsStream(widget.uid),
                    builder: (context, txSnap) {
                      if (txSnap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        );
                      }
                      final txs = txSnap.data ?? [];
                      if (txs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: cardShadow,
                          ),
                          child: const Column(
                            children: [
                              Text('💳',
                                  style: TextStyle(fontSize: 36)),
                              SizedBox(height: 8),
                              Text(
                                'Sin transacciones aún',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children:
                            txs.map((tx) => _TransactionTile(tx: tx)).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

enum _CreditStatus { active, warningToday, blocked }

class _BalanceCard extends StatelessWidget {
  final double balance;
  final _CreditStatus status;
  final bool loading;

  const _BalanceCard({
    required this.balance,
    required this.status,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusBg, statusIcon) = switch (status) {
      _CreditStatus.active => (
          'Activo',
          AppColors.success,
          const Color(0xFFE8F5E9),
          Icons.check_circle_rounded,
        ),
      _CreditStatus.warningToday => (
          'Se suspende mañana',
          AppColors.warning,
          const Color(0xFFFFF8E1),
          Icons.warning_amber_rounded,
        ),
      _CreditStatus.blocked => (
          'Suspendido',
          AppColors.error,
          const Color(0xFFFFEBEE),
          Icons.pause_circle_outline_rounded,
        ),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance de créditos',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (loading)
            const SizedBox(
              height: 52,
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            Text(
              balance.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'créditos disponibles',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Status pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (status == _CreditStatus.warningToday) ...[
            const SizedBox(height: 10),
            const Text(
              'Tu balance está en negativo. Puedes seguir aceptando pedidos hoy, pero mañana quedarás suspendido hasta que recargues créditos.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ] else if (status == _CreditStatus.blocked) ...[
            const SizedBox(height: 10),
            const Text(
              'Tu cuenta está suspendida. Recarga créditos para volver a aceptar pedidos.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── IAP unavailable card ───────────────────────────────────────────────────────

class _IapUnavailableCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardShadow,
      ),
      child: const Row(
        children: [
          Icon(Icons.store_outlined, color: AppColors.textMuted, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'IAP no disponible en este dispositivo.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dev mode card (products not registered in store) ─────────────────────────

class _DevModeCard extends StatelessWidget {
  final Future<void> Function(String productId) onSimulate;

  const _DevModeCard({required this.onSimulate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.developer_mode_rounded,
                  color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Text(
                'Productos no disponibles en modo desarrollo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Los productos IAP no están registrados en la tienda. En producción aparecerán los botones de compra reales. Puedes simular una recarga:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ..._kProductIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DevProductRow(productId: id, onSimulate: onSimulate),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevProductRow extends StatefulWidget {
  final String productId;
  final Future<void> Function(String productId) onSimulate;

  const _DevProductRow({
    required this.productId,
    required this.onSimulate,
  });

  @override
  State<_DevProductRow> createState() => _DevProductRowState();
}

class _DevProductRowState extends State<_DevProductRow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final label = _kProductLabels[widget.productId] ?? widget.productId;
    final price = _kProductPrices[widget.productId] ?? '';

    return GestureDetector(
      onTap: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              await widget.onSimulate(widget.productId);
              if (mounted) setState(() => _loading = false);
            },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Text('💳', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(price,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            if (_loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Simular',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Real IAP product card ─────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductDetails product;
  final double creditAmount;
  final VoidCallback? onBuy;
  final bool loading;

  const _ProductCard({
    required this.product,
    required this.creditAmount,
    required this.onBuy,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlight = creditAmount >= 1000;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighlight
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.border),
        boxShadow: cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isHighlight ? AppColors.primaryBg : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: isHighlight ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kProductLabels[product.id] ?? product.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : '${creditAmount.toStringAsFixed(0)} créditos para aceptar pedidos',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Buy button
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else
              GestureDetector(
                onTap: onBuy,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isHighlight ? AppColors.primary : AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.price,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isHighlight ? Colors.white : AppColors.primary,
                    ),
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
  final Map<String, dynamic> tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final type = tx['type'] as String? ?? 'commission';
    final amount = (tx['amount'] ?? 0.0).toDouble();
    final createdAt = tx['createdAt'];
    final isPurchase = type == 'purchase';

    DateTime? date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    }

    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}  '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPurchase
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                isPurchase ? '🟢' : '🔴',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPurchase ? 'Recarga de créditos' : 'Comisión de pedido',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),

          // Amount
          Text(
            '${isPurchase ? '+' : ''}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isPurchase ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

