import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/cause.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  final String uid;
  const RestaurantSettingsScreen({super.key, required this.uid});
  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final _fs = FirestoreService();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pctCtrl = TextEditingController();
  String? _selectedCauseId;
  String? _selectedCauseName;
  List<Cause> _causes = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _fs.getRestaurant(widget.uid),
      _fs.getActiveCauses(),
    ]);
    final restaurant = results[0] as dynamic;
    final causes = results[1] as List<Cause>;
    if (mounted) {
      setState(() {
        _causes = causes;
        if (restaurant != null) {
          _nameCtrl.text = restaurant.name ?? '';
          _descCtrl.text = restaurant.description ?? '';
          _pctCtrl.text = restaurant.donationPercentage.toStringAsFixed(0);
          _selectedCauseId = restaurant.causeId;
          _selectedCauseName = restaurant.causeName;
        }
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _fs.updateRestaurant(widget.uid, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'donationPercentage': double.tryParse(_pctCtrl.text) ?? 5.0,
        'causeId': _selectedCauseId,
        'causeName': _selectedCauseName,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = double.tryParse(_pctCtrl.text) ?? 5.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(title: 'Información del restaurante', children: [
                    _label('Nombre del restaurante *'),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'La Familiar'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    _label('Descripción'),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Cuéntanos sobre tu restaurante...'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ]),

                  _Section(title: 'Causa que apoyás', children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCauseId,
                      decoration: const InputDecoration(hintText: 'Seleccionar causa'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sin causa seleccionada')),
                        ..._causes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (id) {
                        final cause = _causes.firstWhere((c) => c.id == id, orElse: () => _causes.first);
                        setState(() {
                          _selectedCauseId = id;
                          _selectedCauseName = id != null ? cause.name : null;
                        });
                      },
                    ),
                    if (_selectedCauseId != null) ...[
                      const SizedBox(height: 10),
                      Builder(builder: (_) {
                        final cause = _causes.firstWhere((c) => c.id == _selectedCauseId);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(cause.description,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ]),

                  _Section(title: 'Porcentaje de donación', children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pctCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                            decoration: const InputDecoration(suffixText: '%'),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pct% de \$1000 = \$${(1000 * pct / 100).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este porcentaje se aplica automáticamente a cada pedido.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ]),

                  const SizedBox(height: 8),
                  AppButton(label: 'Guardar cambios', onPressed: _save, loading: _saving),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}
