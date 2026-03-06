import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String uid;
  const RestaurantMenuScreen({super.key, required this.uid});
  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final _fs = FirestoreService();

  void _showForm({Map<String, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final priceCtrl = TextEditingController(text: item != null ? '${item['price']}' : '');
    final catCtrl = TextEditingController(text: item?['category'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final imgCtrl = TextEditingController(text: item?['imageUrl'] ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item == null ? 'Nuevo item' : 'Editar item',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _field('Nombre *', nameCtrl),
                _field('Precio *', priceCtrl,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]),
                _field('Categoría', catCtrl, hint: 'Platos principales, Bebidas...'),
                _field('Descripción', descCtrl, maxLines: 2),
                _field('URL de imagen', imgCtrl, hint: 'https://...'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: const Text('Cancelar'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                      setModal(() => saving = true);
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'price': double.tryParse(priceCtrl.text) ?? 0.0,
                        'category': catCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'imageUrl': imgCtrl.text.trim(),
                      };
                      try {
                        if (item == null) {
                          await _fs.addMenuItem(widget.uid, data);
                        } else {
                          await _fs.updateMenuItem(widget.uid, item['id'], data);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (_) {}
                      setModal(() => saving = false);
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar'),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboard, List<TextInputFormatter>? formatters, int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          inputFormatters: formatters,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú'),
        actions: [
          TextButton.icon(
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text('Agregar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fs.menuItemsStream(widget.uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🍽', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Tu menú está vacío', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => _showForm(), child: const Text('Agregar primer plato')),
              ]),
            );
          }

          // Group by category
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final item in items) {
            final cat = (item['category'] as String?)?.isNotEmpty == true ? item['category'] as String : 'Sin categoría';
            grouped.putIfAbsent(cat, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Text(entry.key.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
                ),
                ...entry.value.map((item) => _MenuItemTile(
                  item: item,
                  onEdit: () => _showForm(item: item),
                  onDelete: () => _fs.deleteMenuItem(widget.uid, item['id']),
                )),
                const SizedBox(height: 8),
              ],
            )).toList(),
          );
        },
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MenuItemTile({required this.item, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final price = (item['price'] ?? 0.0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: cardShadow),
      child: Row(
        children: [
          if (item['imageUrl'] != null && (item['imageUrl'] as String).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item['imageUrl'], width: 48, height: 48, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.primary50,
                      child: const Icon(Icons.fastfood, color: AppColors.primary, size: 22))),
            )
          else
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.fastfood, color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            if (item['description'] != null && (item['description'] as String).isNotEmpty)
              Text(item['description'], style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('\$${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ])),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Quitar', style: TextStyle(color: AppColors.error))])),
            ],
            onSelected: (v) { if (v == 'edit') onEdit(); else onDelete(); },
          ),
        ],
      ),
    );
  }
}
