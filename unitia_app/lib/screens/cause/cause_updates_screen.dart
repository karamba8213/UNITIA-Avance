import 'package:flutter/material.dart';
import '../../core/models/cause_update.dart';
import '../../core/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

class CauseUpdatesScreen extends StatefulWidget {
  final String uid;
  const CauseUpdatesScreen({super.key, required this.uid});
  @override
  State<CauseUpdatesScreen> createState() => _CauseUpdatesScreenState();
}

class _CauseUpdatesScreenState extends State<CauseUpdatesScreen> {
  final _fs       = FirestoreService();
  final _storage  = StorageService();
  final _msgCtrl  = TextEditingController();
  bool _posting   = false;
  bool _uploading = false;
  String? _pendingImageUrl;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    try {
      final url = await _storage.pickAndUpload(
        path: 'causes/${widget.uid}/updates/${DateTime.now().millisecondsSinceEpoch}.jpg',
        source: ImageSource.gallery,
      );
      if (url != null && mounted) setState(() => _pendingImageUrl = url);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editUpdate(CauseUpdate update) async {
    final ctrl = TextEditingController(text: update.message);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar actualización',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (confirmed != true || ctrl.text.trim().isEmpty || !mounted) return;
    try {
      await _fs.editCauseUpdate(widget.uid, update.id, ctrl.text.trim());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteUpdate(CauseUpdate update) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar actualización',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _fs.deleteCauseUpdate(widget.uid, update.id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _post() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _posting = true);
    try {
      await _fs.addCauseUpdate(widget.uid, msg, imageUrl: _pendingImageUrl);
      _msgCtrl.clear();
      if (mounted) setState(() => _pendingImageUrl = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Actualización publicada'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
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
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizaciones')),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Compose area ────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nueva actualización',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'Comparte el avance de tu causa con la comunidad',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'ej. "Gracias a Unitia ya juntamos el 60% para la cirugía de María..."',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 10),
                if (_pendingImageUrl != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_pendingImageUrl!,
                            height: 140, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6, right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _pendingImageUrl = null),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(children: [
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickImage,
                    icon: _uploading
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.photo_outlined, size: 18),
                    label: const Text('Foto'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Publicar',
                      onPressed: _post,
                      loading: _posting,
                    ),
                  ),
                ]),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ── Updates list ─────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<CauseUpdate>>(
              stream: _fs.causeUpdatesStream(widget.uid),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }
                final updates = snap.data ?? [];
                if (updates.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 48, color: AppColors.border),
                        SizedBox(height: 12),
                        Text('Aún no has publicado actualizaciones',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: updates.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.campaign_rounded,
                                    color: AppColors.primary, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _fmtDate(updates[i].createdAt),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                onPressed: () => _editUpdate(updates[i]),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () => _deleteUpdate(updates[i]),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            updates[i].message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
