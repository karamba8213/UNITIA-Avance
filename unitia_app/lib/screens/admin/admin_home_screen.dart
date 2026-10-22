import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  late TabController _tabs;

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _confirmed = [];
  List<Map<String, dynamic>> _restaurants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _fs.getAdminCommissions(status: 'transferred'),
      _fs.getAdminCommissions(status: 'confirmed'),
      _fs.adminGetAllRestaurants(),
    ]);
    if (mounted) {
      setState(() {
        _pending     = results[0];
        _confirmed   = results[1];
        _restaurants = results[2];
        _loading     = false;
      });
    }
  }

  Future<void> _addCredits(Map<String, dynamic> restaurant) async {
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();
    final confirmed  = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(restaurant['name'] ?? 'Restaurante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Balance actual: \$${((restaurant['creditBalance'] ?? 0.0) as num).toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a agregar (\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    await _fs.adminAddCredits(
      restaurant['id'] as String,
      amount,
      noteCtrl.text.trim().isEmpty ? 'Carga manual admin' : noteCtrl.text.trim(),
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\$${amount.toStringAsFixed(0)} agregados a ${restaurant['name']}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _confirm(Map<String, dynamic> item) async {
    await _fs.adminConfirmCommission(
      restaurantId: item['restaurantId'] as String,
      weekId: item['weekId'] as String,
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago confirmado'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _fmtMoney(double v) => '\$${v.toStringAsFixed(2)}';

  String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    final d = (ts as Timestamp).toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Unitia',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Por confirmar (${_pending.length})'),
            Tab(text: 'Confirmados (${_confirmed.length})'),
            const Tab(text: 'Créditos'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _CommissionList(
                  items: _pending,
                  emptyText: 'No hay transferencias pendientes de confirmar',
                  onConfirm: _confirm,
                  fmtMoney: _fmtMoney,
                  fmtDate: _fmtDate,
                ),
                _CommissionList(
                  items: _confirmed,
                  emptyText: 'No hay pagos confirmados aún',
                  fmtMoney: _fmtMoney,
                  fmtDate: _fmtDate,
                ),
                _CreditsList(
                  restaurants: _restaurants,
                  onAddCredits: _addCredits,
                ),
              ],
            ),
    );
  }
}

// ── Lista de comisiones ───────────────────────────────────────────────────────

class _CommissionList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyText;
  final Future<void> Function(Map<String, dynamic>)? onConfirm;
  final String Function(double) fmtMoney;
  final String Function(dynamic) fmtDate;

  const _CommissionList({
    required this.items,
    required this.emptyText,
    required this.fmtMoney,
    required this.fmtDate,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyText,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _CommissionCard(
          item: items[i],
          onConfirm: onConfirm,
          fmtMoney: fmtMoney,
          fmtDate: fmtDate,
        ),
      ),
    );
  }
}

// ── Tarjeta de comisión ───────────────────────────────────────────────────────

class _CommissionCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Future<void> Function(Map<String, dynamic>)? onConfirm;
  final String Function(double) fmtMoney;
  final String Function(dynamic) fmtDate;

  const _CommissionCard({
    required this.item,
    required this.fmtMoney,
    required this.fmtDate,
    this.onConfirm,
  });

  @override
  State<_CommissionCard> createState() => _CommissionCardState();
}

class _CommissionCardState extends State<_CommissionCard> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final item           = widget.item;
    final restaurantName = item['restaurantName'] as String? ?? 'Restaurante';
    final weekId         = item['weekId'] as String? ?? '';
    final commission     = (item['commissionAmount'] ?? 0.0 as num).toDouble();
    final totalSales     = (item['totalSales'] ?? 0.0 as num).toDouble();
    final reference      = item['transferReference'] as String?;
    final transferredAt  = item['transferredAt'];
    final isConfirmed    = item['status'] == 'confirmed';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
        border: isConfirmed
            ? Border.all(color: AppColors.success.withValues(alpha: 0.3))
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  restaurantName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFFECFDF5)
                      : AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isConfirmed ? 'Confirmado' : 'Por confirmar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isConfirmed ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row('Semana', weekId),
          _Row('Ventas', widget.fmtMoney(totalSales)),
          _Row('Comisión (1%)', widget.fmtMoney(commission),
              highlight: true),
          if (reference != null && reference.isNotEmpty)
            _Row('Referencia', reference),
          if (transferredAt != null)
            _Row('Transferido', widget.fmtDate(transferredAt)),
          if (!isConfirmed && widget.onConfirm != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirming
                    ? null
                    : () async {
                        setState(() => _confirming = true);
                        await widget.onConfirm!(item);
                        if (mounted) setState(() => _confirming = false);
                      },
                icon: _confirming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Confirmar pago recibido',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Lista de créditos ─────────────────────────────────────────────────────────

class _CreditsList extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  final Future<void> Function(Map<String, dynamic>) onAddCredits;

  const _CreditsList({required this.restaurants, required this.onAddCredits});

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const Center(
        child: Text('No hay restaurantes registrados',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _CreditsCard(
        restaurant: restaurants[i],
        onAddCredits: onAddCredits,
      ),
    );
  }
}

class _CreditsCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final Future<void> Function(Map<String, dynamic>) onAddCredits;

  const _CreditsCard({required this.restaurant, required this.onAddCredits});

  @override
  Widget build(BuildContext context) {
    final name    = restaurant['name'] as String? ?? 'Sin nombre';
    final id      = restaurant['id'] as String? ?? '';
    final balance = ((restaurant['creditBalance'] ?? 0.0) as num).toDouble();
    final isLow   = balance <= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
        border: isLow ? Border.all(color: AppColors.error.withValues(alpha: 0.3)) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: isLow ? AppColors.error : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'ID: $id',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  'Balance: \$${balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLow ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => onAddCredits(restaurant),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            child: const Text('+ Créditos'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Row(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 15 : 13,
              fontWeight:
                  highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
