import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';

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
  bool _loading = true;
  bool _saving = false;

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

                  const SizedBox(height: 8),
                  AppButton(label: 'Guardar cambios', onPressed: _save, loading: _saving),
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
