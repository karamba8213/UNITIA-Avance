import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String uid;
  const RestaurantMenuScreen({super.key, required this.uid});
  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final _fs      = FirestoreService();
  final _storage = StorageService();

  static const _defaultCategories = [
    'Entradas', 'Sopas', 'Ensaladas', 'Platos principales',
    'Carnes', 'Mariscos', 'Pastas', 'Pizzas', 'Hamburguesas',
    'Tacos', 'Vegetariano', 'Desayunos', 'Bebidas', 'Postres', 'Snacks',
  ];

  List<String> _categories = [..._defaultCategories]..sort();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final saved = await _fs.getMenuCategories(widget.uid);
    if (saved.isEmpty) return;
    final merged = {..._defaultCategories, ...saved}.toList()..sort();
    if (mounted) setState(() => _categories = merged);
  }

  // Normaliza a Title Case
  String _normalize(String s) => s
      .trim()
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  // Levenshtein distance
  int _levenshtein(String a, String b) {
    final al = a.toLowerCase(), bl = b.toLowerCase();
    if (al == bl) return 0;
    final m = al.length, n = bl.length;
    final dp = List.generate(m + 1, (i) => List.generate(n + 1, (j) => j == 0 ? i : (i == 0 ? j : 0)));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = al[i - 1] == bl[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[m][n];
  }

  // Retorna categoría similar si existe (distancia <= 2), o null
  String? _findSimilar(String name) {
    final norm = name.toLowerCase();
    for (final cat in _categories) {
      if (cat.toLowerCase() == norm) return cat; // exacto
      if (_levenshtein(norm, cat.toLowerCase()) <= 2) return cat;
    }
    return null;
  }

  // Retorna null si OK, o mensaje de error/advertencia
  String? _validateCategory(String name) {
    final norm = _normalize(name);
    if (norm.isEmpty) return 'Escribe un nombre';
    final similar = _findSimilar(norm);
    if (similar != null) return 'Ya existe "$similar"';
    return null;
  }

  Future<String?> _addCategory(String raw) async {
    final name = _normalize(raw);
    final error = _validateCategory(name);
    if (error != null) return error;
    final updated = [..._categories, name]..sort();
    final custom = updated.where((c) => !_defaultCategories.contains(c)).toList();
    await _fs.saveMenuCategories(widget.uid, custom);
    if (mounted) setState(() => _categories = updated);
    return null;
  }

  void _showManageCategories() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final newCtrl = TextEditingController();
          String? errorMsg;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Categorías del menú',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Las predeterminadas no se pueden eliminar',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final isDefault = _defaultCategories.contains(cat);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(cat, style: const TextStyle(fontSize: 14)),
                        trailing: isDefault
                            ? const Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted)
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () async {
                                  final updated = _categories.where((c) => c != cat).toList();
                                  final custom = updated.where((c) => !_defaultCategories.contains(c)).toList();
                                  await _fs.saveMenuCategories(widget.uid, custom);
                                  if (mounted) setState(() => _categories = updated);
                                  setModal(() {});
                                },
                              ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: newCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nueva categoría...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        errorText: errorMsg,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) { if (errorMsg != null) setModal(() => errorMsg = null); },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final err = await _addCategory(newCtrl.text);
                      if (err != null) {
                        setModal(() => errorMsg = err);
                      } else {
                        newCtrl.clear();
                        setModal(() => errorMsg = null);
                      }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: const Text('Agregar'),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showForm({Map<String, dynamic>? item}) {
    final nameCtrl  = TextEditingController(text: item?['name'] ?? '');
    final priceCtrl = TextEditingController(text: item != null ? '${item['price']}' : '');
    final descCtrl  = TextEditingController(text: item?['description'] ?? '');
    String? selectedCat = item?['category'] as String?;
    String? imageUrl = item?['imageUrl'] as String?;
    bool saving      = false;
    bool uploading   = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> pickImage(ImageSource source) async {
            setModal(() => uploading = true);
            try {
              final path = 'restaurants/${widget.uid}/menu/${DateTime.now().millisecondsSinceEpoch}.jpg';
              final url  = await _storage.pickAndUpload(path: path, source: source);
              if (url != null) setModal(() => imageUrl = url);
            } finally {
              setModal(() => uploading = false);
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item == null ? 'Nuevo platillo' : 'Editar platillo',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),

                  // Imagen
                  GestureDetector(
                    onTap: uploading ? null : () => showModalBottomSheet(
                      context: ctx,
                      builder: (_) => SafeArea(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library_rounded),
                            title: const Text('Elegir de galería'),
                            onTap: () { Navigator.pop(ctx); pickImage(ImageSource.gallery); },
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt_rounded),
                            title: const Text('Tomar foto'),
                            onTap: () { Navigator.pop(ctx); pickImage(ImageSource.camera); },
                          ),
                        ]),
                      ),
                    ),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(12),
                        image: imageUrl != null && imageUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: uploading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : imageUrl == null || imageUrl!.isEmpty
                              ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 32),
                                  SizedBox(height: 6),
                                  Text('Agregar foto', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ])
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.black45,
                                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _field('Nombre *', nameCtrl),
                  _field('Precio *', priceCtrl,
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]),

                  // ── Categoría selector ──────────────────
                  const Text('Categoría',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: _categories.contains(selectedCat) ? selectedCat : null,
                    hint: const Text('Selecciona una categoría'),
                    decoration: const InputDecoration(),
                    items: [
                      ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      const DropdownMenuItem(
                        value: '__nueva__',
                        child: Row(children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Agregar otra categoría', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                    onChanged: (v) async {
                      if (v == '__nueva__') {
                        Navigator.pop(ctx);
                        _showManageCategories();
                      } else {
                        setModal(() => selectedCat = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _field('Descripción', descCtrl, maxLines: 2),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                      child: const Text('Cancelar'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      onPressed: saving || uploading ? null : () async {
                        if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                        setModal(() => saving = true);
                        final data = {
                          'name':        nameCtrl.text.trim(),
                          'price':       double.tryParse(priceCtrl.text) ?? 0.0,
                          'category':    selectedCat ?? '',
                          'description': descCtrl.text.trim(),
                          'imageUrl':    imageUrl ?? '',
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
          );
        },
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
          IconButton(
            icon: const Icon(Icons.category_outlined, color: AppColors.textSecondary),
            tooltip: 'Categorías',
            onPressed: _showManageCategories,
          ),
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
