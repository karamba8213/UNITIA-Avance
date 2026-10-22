import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

/// Screen used by the CAUSE app to view a direct donation and chat/confirm it.
class DirectDonationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> donation;
  final String causeId;
  final String causeName;
  const DirectDonationDetailScreen({
    super.key,
    required this.donation,
    required this.causeId,
    required this.causeName,
  });

  @override
  State<DirectDonationDetailScreen> createState() =>
      _DirectDonationDetailScreenState();
}

class _DirectDonationDetailScreenState
    extends State<DirectDonationDetailScreen> {
  final _fs = FirestoreService();
  final _storage = StorageService();
  final _msgCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _sending = false;
  bool _uploading = false;
  bool _confirming = false;
  bool _showAdjust = false;

  String get _donationId => widget.donation['id'] as String;
  double get _originalAmount =>
      (widget.donation['proposedAmount'] ?? 0.0).toDouble();
  String get _status => widget.donation['status'] ?? 'pending';

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = _originalAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMsg() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      await _fs.sendDirectDonationChatMessage(
        donationId: _donationId,
        senderId: widget.causeId,
        senderRole: 'cause',
        senderName: widget.causeName,
        text: text,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    setState(() => _uploading = true);
    try {
      final url = await _storage.pickAndUpload(
        path:
            'direct_donations/$_donationId/cause_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (url != null && mounted) {
        await _fs.sendDirectDonationChatMessage(
          donationId: _donationId,
          senderId: widget.causeId,
          senderRole: 'cause',
          senderName: widget.causeName,
          text: '',
          imageUrl: url,
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    setState(() => _confirming = true);
    try {
      await _fs.confirmDirectDonation(
        donationId: _donationId,
        causeId: widget.causeId,
        confirmedAmount: amount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Donación confirmada!'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
    if (mounted) setState(() => _confirming = false);
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmed = _status == 'confirmed';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donación directa',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Donation summary ─────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.donation['customerName'] ?? '',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            widget.donation['customerEmail'] ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isConfirmed ? 'Confirmada' : 'Pendiente',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isConfirmed
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '\$${_originalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    const Text('reportado por el cliente',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
                if (widget.donation['notes'] != null &&
                    (widget.donation['notes'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('"${widget.donation['notes']}"',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.4)),
                ],
                if (!isConfirmed) ...[
                  const SizedBox(height: 14),
                  // ── Confirm / adjust buttons ──────────────
                  if (!_showAdjust)
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              _confirming ? null : () => _confirm(),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _confirming
                                ? const Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          Icons
                                              .check_circle_rounded,
                                          color: Colors.white,
                                          size: 18),
                                      SizedBox(width: 6),
                                      Text('Confirmar',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 14)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showAdjust = true),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: AppColors.textSecondary,
                                  size: 16),
                              SizedBox(width: 4),
                              Text('Ajustar',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ])
                  else ...[
                    TextField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.,]'))
                      ],
                      decoration: InputDecoration(
                        labelText: 'Monto real recibido',
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _confirming ? null : _confirm,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Confirmar monto',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showAdjust = false),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.border),
                          ),
                          child: const Text('Cancelar',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ),
                    ]),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Chat messages ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fs.directDonationChatStream(_donationId),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Sin mensajes aún',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final isMe = m['senderId'] == widget.causeId;
                    final text = m['text'] as String? ?? '';
                    final imageUrl = m['imageUrl'] as String?;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            Container(
                              width: 28, height: 28,
                              margin:
                                  const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 14),
                            ),
                          ],
                          Flexible(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft:
                                      const Radius.circular(18),
                                  topRight:
                                      const Radius.circular(18),
                                  bottomLeft: Radius.circular(
                                      isMe ? 18 : 4),
                                  bottomRight: Radius.circular(
                                      isMe ? 4 : 18),
                                ),
                                boxShadow: cardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (imageUrl != null) ...[
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                              10),
                                      child: Image.network(
                                        imageUrl,
                                        width: 220,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_,
                                                __,
                                                ___) =>
                                            const Icon(
                                                Icons
                                                    .broken_image_outlined,
                                                color: AppColors
                                                    .textMuted),
                                      ),
                                    ),
                                    if (text.isNotEmpty)
                                      const SizedBox(height: 6),
                                  ],
                                  if (text.isNotEmpty)
                                    Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── Chat input ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 12, right: 12,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + 12,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _uploading ? null : _sendImage,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _uploading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file_rounded,
                            color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(24)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _sendMsg,
                  child: Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
