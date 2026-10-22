import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/image_upload_widget.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  final String uid;
  const RestaurantSettingsScreen({super.key, required this.uid});
  @override
  State<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final _fs = FirestoreService();

  // controllers
  final _nameCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _pctCtrl     = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _latCtrl     = TextEditingController();
  final _lngCtrl     = TextEditingController();

  String? _logoUrl;
  bool _loading = true;
  bool _saving  = false;

  String? _selectedCategory;
  // Delivery tiers: [{maxKm: 2, price: 30.0}, ...]
  List<Map<String, dynamic>> _deliveryTiers = [];
  final List<TextEditingController> _tierPriceCtrl = [];


  static const _categories = [
    'Comida mexicana',
    'Comida italiana',
    'Comida asiática',
    'Hamburguesas',
    'Pizzas',
    'Mariscos',
    'Saludable',
    'Postres',
    'Cafetería',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final restaurant = await _fs.getRestaurant(widget.uid);
    if (!mounted) return;
    setState(() {
      if (restaurant != null) {
        _nameCtrl.text    = restaurant.name ?? '';
        _descCtrl.text    = restaurant.description ?? '';
        _pctCtrl.text     = restaurant.donationPercentage.toStringAsFixed(0);
        _addressCtrl.text = restaurant.address ?? '';
        _phoneCtrl.text   = restaurant.phone ?? '';
        _cityCtrl.text    = restaurant.city ?? '';
        _selectedCategory  = _categories.contains(restaurant.category)
            ? restaurant.category
            : null;
        _latCtrl.text = restaurant.latitude?.toString() ?? '';
        _lngCtrl.text = restaurant.longitude?.toString() ?? '';
        _logoUrl = restaurant.logo;
        _setTiers(restaurant.deliveryTiers);
      }
      _loading = false;
    });
  }

  void _setTiers(List<Map<String, dynamic>> tiers) {
    for (final c in _tierPriceCtrl) c.dispose();
    _tierPriceCtrl.clear();
    _deliveryTiers = List.from(tiers);
    for (final t in _deliveryTiers) {
      _tierPriceCtrl.add(TextEditingController(
          text: (t['price'] as num).toStringAsFixed(0)));
    }
  }

  void _addTier() {
    setState(() {
      final nextKm = _deliveryTiers.isEmpty
          ? 2
          : (_deliveryTiers.last['maxKm'] as int) + 2;
      _deliveryTiers.add({'maxKm': nextKm, 'price': 0.0});
      _tierPriceCtrl.add(TextEditingController(text: '0'));
    });
  }

  void _removeTier(int index) {
    setState(() {
      _tierPriceCtrl[index].dispose();
      _tierPriceCtrl.removeAt(index);
      _deliveryTiers.removeAt(index);
    });
  }

  List<Map<String, dynamic>> _buildTiers() {
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < _deliveryTiers.length; i++) {
      result.add({
        'maxKm': _deliveryTiers[i]['maxKm'],
        'price': double.tryParse(_tierPriceCtrl[i].text) ?? 0.0,
      });
    }
    return result;
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El nombre del restaurante es requerido'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _fs.updateRestaurant(widget.uid, {
        'name':               _nameCtrl.text.trim(),
        'description':        _descCtrl.text.trim(),
        'donationPercentage': double.tryParse(_pctCtrl.text) ?? 5.0,
        'address':            _addressCtrl.text.trim(),
        'phone':              _phoneCtrl.text.trim(),
        'city':               _cityCtrl.text.trim(),
        if (_selectedCategory != null) 'category': _selectedCategory,
        if (_latCtrl.text.isNotEmpty) 'latitude':  double.tryParse(_latCtrl.text),
        if (_lngCtrl.text.isNotEmpty) 'longitude': double.tryParse(_lngCtrl.text),
        'deliveryTiers': _buildTiers(),
        if (_logoUrl != null) 'logo': _logoUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cambios guardados'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _pctCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    for (final c in _tierPriceCtrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        ImageUploadWidget(
                          currentUrl: _logoUrl,
                          storagePath: 'restaurants/${widget.uid}/logo',
                          placeholder: Icons.restaurant_rounded,
                          onUploaded: (url) => setState(() => _logoUrl = url),
                        ),
                        const SizedBox(height: 8),
                        const Text('Logo del restaurante',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Información básica ───────────────────────
                  _Section(
                    title: 'Información del restaurante',
                    children: [
                      _label('Nombre *'),
                      TextField(
                        controller: _nameCtrl,
                        decoration:
                            const InputDecoration(hintText: 'La Familiar'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      _label('Descripción'),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            hintText:
                                'Cuéntanos sobre tu restaurante...'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      _label('Categoría'),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text('Selecciona una categoría',
                            style: TextStyle(fontSize: 14)),
                        decoration: const InputDecoration(),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v),
                      ),
                    ],
                  ),

                  // ── Contacto ─────────────────────────────────
                  _Section(
                    title: 'Contacto y ubicación',
                    children: [
                      _label('Dirección'),
                      TextField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Calle, número, colonia'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      _label('Ciudad'),
                      TextField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Ciudad de México'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      _label('Coordenadas (para calcular envío)'),
                      const Text(
                        'Búscalas en Google Maps → mantén presionado tu local → copia las coordenadas.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _latCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-\d.]'))],
                            decoration: const InputDecoration(hintText: 'Latitud (ej. 25.789)'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _lngCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-\d.]'))],
                            decoration: const InputDecoration(hintText: 'Longitud (ej. -108.986)'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      _label('Teléfono'),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\s\+\-\(\)]'))
                        ],
                        decoration: const InputDecoration(
                            hintText: '+52 55 1234 5678'),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                  // ── Donación ──────────────────────────────────
                  _Section(
                    title: 'Donación',
                    children: [
                      _label('Porcentaje de donación'),
                      TextField(
                        controller: _pctCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'))
                        ],
                        decoration:
                            const InputDecoration(suffixText: '%'),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'De cada pedido, el ${_pctCtrl.text.isEmpty ? '5' : _pctCtrl.text}% va a la causa vinculada.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  // ── Tarifas de envío ──────────────────────────
                  _Section(
                    title: 'Tarifas de envío a domicilio',
                    children: [
                      const Text(
                        'Define el costo de entrega según la distancia al cliente. Se agregan en rangos de 2 km.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      if (_deliveryTiers.isEmpty)
                        const Text('Sin tarifas configuradas — envío gratuito.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ...List.generate(_deliveryTiers.length, (i) {
                        final fromKm = i == 0 ? 0 : (_deliveryTiers[i - 1]['maxKm'] as int);
                        final toKm   = _deliveryTiers[i]['maxKm'] as int;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.delivery_dining_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('$fromKm – $toKm km',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              const Text('\$  ',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              SizedBox(
                                width: 70,
                                child: TextField(
                                  controller: _tierPriceCtrl[i],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeTier(i),
                                child: const Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _addTier,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _deliveryTiers.isEmpty
                                    ? 'Agregar tarifa (0 – 2 km)'
                                    : 'Agregar tarifa (${_deliveryTiers.last['maxKm']} – ${(_deliveryTiers.last['maxKm'] as int) + 2} km)',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  AppButton(
                      label: 'Guardar cambios',
                      onPressed: _save,
                      loading: _saving),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Cerrar sesión',
                    onPressed: () async {
                      await context.read<AuthProvider>().signOut();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}
