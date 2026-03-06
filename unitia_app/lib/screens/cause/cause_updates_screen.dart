import 'package:flutter/material.dart';
import '../../core/models/cause_update.dart';
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
  final _msgCtrl  = TextEditingController();
  bool _posting   = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _posting = true);
    try {
      await _fs.addCauseUpdate(widget.uid, msg);
      _msgCtrl.clear();
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
                AppButton(
                  label: 'Publicar actualización',
                  onPressed: _post,
                  loading: _posting,
                ),
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
