import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/image_upload_widget.dart';

class CauseSettingsScreen extends StatefulWidget {
  final String uid;
  const CauseSettingsScreen({super.key, required this.uid});
  @override
  State<CauseSettingsScreen> createState() => _CauseSettingsScreenState();
}

class _CauseSettingsScreenState extends State<CauseSettingsScreen> {
  final _fs = FirestoreService();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _storyCtrl = TextEditingController();
  final _bancoCtrl = TextEditingController();
  final _titularCtrl = TextEditingController();
  final _clabeCtrl = TextEditingController();
  String? _logoUrl;
  String _category = 'General';
  bool _loading = true;
  bool _saving = false;

  static const _categories = [
    'General', 'Educación', 'Alimentación', 'Medio ambiente', 'Salud', 'Animales',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cause = await _fs.getCause(widget.uid);
    if (mounted && cause != null) {
      setState(() {
        _nameCtrl.text = cause.name;
        _descCtrl.text = cause.description;
        _targetCtrl.text = cause.targetAmount.toStringAsFixed(0);
        _storyCtrl.text = cause.story;
        _logoUrl = cause.logo;
        _category = cause.category;
        _bancoCtrl.text = cause.bankInfo?['banco'] ?? '';
        _titularCtrl.text = cause.bankInfo?['titular'] ?? '';
        _clabeCtrl.text = cause.bankInfo?['clabe'] ?? '';
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _fs.updateCause(widget.uid, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'targetAmount': double.tryParse(_targetCtrl.text) ?? 0.0,
        'story': _storyCtrl.text.trim(),
        if (_logoUrl != null) 'logo': _logoUrl,
        'category': _category,
        'bankInfo': {
          'banco': _bancoCtrl.text.trim(),
          'titular': _titularCtrl.text.trim(),
          'clabe': _clabeCtrl.text.trim(),
        },
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
    _targetCtrl.dispose();
    _storyCtrl.dispose();
    _bancoCtrl.dispose();
    _titularCtrl.dispose();
    _clabeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ──────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        ImageUploadWidget(
                          currentUrl: _logoUrl,
                          storagePath: 'causes/${widget.uid}/logo',
                          placeholder: Icons.volunteer_activism_rounded,
                          onUploaded: (url) => setState(() => _logoUrl = url),
                        ),
                        const SizedBox(height: 8),
                        const Text('Logo de la organización',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _Section(title: 'Información de la organización', children: [
                    _label('Nombre de la organización *'),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'Comedor Esperanza'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    _label('Descripción breve'),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Breve descripción de tu organización...'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ]),

                  _Section(title: 'Categoría', children: [
                    _label('Categoría de tu organización'),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _category = v); },
                    ),
                  ]),

                  _Section(title: 'Objetivo de recaudación', children: [
                    _label('Meta (en pesos)'),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      decoration: const InputDecoration(prefixText: '\$ ', hintText: '100000'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ]),

                  _Section(title: 'Tu historia', children: [
                    _label('Contá tu historia (aparece en tu perfil público)'),
                    TextField(
                      controller: _storyCtrl,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Contanos sobre tu organización, cómo nació, qué hacen...',
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ]),

                  _Section(title: 'Datos para donaciones directas', children: [
                    _label('Banco'),
                    TextField(
                      controller: _bancoCtrl,
                      decoration: const InputDecoration(hintText: 'Ej. BBVA, Santander, Banamex'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    _label('Titular de la cuenta'),
                    TextField(
                      controller: _titularCtrl,
                      decoration: const InputDecoration(hintText: 'Nombre completo del titular'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    _label('CLABE / No. de cuenta'),
                    TextField(
                      controller: _clabeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: '18 dígitos'),
                      style: const TextStyle(fontSize: 14, letterSpacing: 1),
                    ),
                  ]),

                  const SizedBox(height: 8),
                  AppButton(label: 'Guardar cambios', onPressed: _save, loading: _saving),
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
