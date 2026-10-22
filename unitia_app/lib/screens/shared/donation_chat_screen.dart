import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/donation_badge.dart';

class DonationChatScreen extends StatefulWidget {
  final String donationId;
  final String currentUserId;
  final String currentUserRole; // 'restaurant' | 'cause'
  final String currentUserName;

  const DonationChatScreen({
    super.key,
    required this.donationId,
    required this.currentUserId,
    required this.currentUserRole,
    required this.currentUserName,
  });

  @override
  State<DonationChatScreen> createState() => _DonationChatScreenState();
}

class _DonationChatScreenState extends State<DonationChatScreen> {
  final _fs = FirestoreService();
  final _storage = StorageService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _actionLoading = false;
  bool _disputeLoading = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textCtrl.clear();
    try {
      await _fs.sendChatMessage(
        donationId: widget.donationId,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        senderName: widget.currentUserName,
        text: text,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage(ImageSource source) async {
    if (_uploadingImage) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await _storage.pickAndUpload(
        path: 'chat/${widget.donationId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        source: source,
      );
      if (url == null || !mounted) return;
      await _fs.sendChatMessage(
        donationId: widget.donationId,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        senderName: widget.currentUserName,
        text: '📎 Comprobante',
        imageUrl: url,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Tomar foto'),
              onTap: () { Navigator.pop(ctx); _sendImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Elegir de galería'),
              onTap: () { Navigator.pop(ctx); _sendImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaid(Map<String, dynamic> donation) async {
    final notesCtrl = TextEditingController();
    String? selectedMethod; // 'efectivo' | 'transferencia'

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confirmar pago',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Donación de \$${(donation['amount'] as num).toStringAsFixed(0)} a ${donation['causeName']}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Forma de pago',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _MethodChip(
                    label: 'Efectivo en persona',
                    icon: Icons.payments_rounded,
                    selected: selectedMethod == 'efectivo',
                    onTap: () => setModalState(() => selectedMethod = 'efectivo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MethodChip(
                    label: 'Transferencia',
                    icon: Icons.account_balance_rounded,
                    selected: selectedMethod == 'transferencia',
                    onTap: () => setModalState(() => selectedMethod = 'transferencia'),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    hintText: 'Ej: referencia #12345'),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44)),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedMethod == null
                        ? null
                        : () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44)),
                    child: const Text('Confirmar'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
      final methodLabel = selectedMethod == 'efectivo' ? 'Efectivo en persona' : 'Transferencia';
      await _fs.markDonationPaid(
        widget.donationId,
        donation['orderId'],
        notes: notes,
        paymentMethod: selectedMethod,
      );
      await _fs.sendChatMessage(
        donationId: widget.donationId,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        senderName: widget.currentUserName,
        text: '✅ Pagado — $methodLabel${notes != null ? '\n$notes' : ''}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _disputePayment(Map<String, dynamic> donation) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('No recibí el pago',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'La donación volverá a estado pendiente y el restaurante será notificado.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: no hubo contacto, monto incorrecto...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _disputeLoading = true);
    try {
      await _fs.disputeDonationPayment(widget.donationId, donation['orderId']);
      final reason = reasonCtrl.text.trim();
      await _fs.sendChatMessage(
        donationId: widget.donationId,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        senderName: widget.currentUserName,
        text: '⚠️ No recibí el pago${reason.isNotEmpty ? ' — $reason' : ''}. Por favor coordina el envío.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _disputeLoading = false);
    }
  }

  Future<void> _confirmReceived(Map<String, dynamic> donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar recibo',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          '¿Confirmas que recibiste \$${(donation['amount'] as num).toStringAsFixed(0)} de ${donation['restaurantName']}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      await _fs.confirmDonationReceived(
          widget.donationId, donation['orderId'], donation['causeId']);
      await _fs.sendChatMessage(
        donationId: widget.donationId,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        senderName: widget.currentUserName,
        text: '✅ Recibo confirmado. ¡Gracias por el apoyo!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _fs.donationStream(widget.donationId),
      builder: (context, donSnap) {
        final donation = donSnap.data;
        final status = donation?['status'] ?? '';
        final amount = (donation?['amount'] ?? 0.0 as num).toDouble();
        final isRestaurant = widget.currentUserRole == 'restaurant';
        final isCause = widget.currentUserRole == 'cause';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              isRestaurant
                  ? (donation?['causeName'] ?? 'Causa')
                  : (donation?['restaurantName'] ?? 'Restaurante'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              if (donation != null)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(child: DonationBadge(status: status)),
                ),
            ],
          ),
          body: Column(
            children: [
              // ── Donation info banner ─────────────────────────
              if (donation != null)
                Container(
                  color: AppColors.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.volunteer_activism_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donation['customerName'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              Text(
                                isRestaurant
                                    ? 'Para: ${donation['causeName'] ?? ''}'
                                    : 'De: ${donation['restaurantName'] ?? ''}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted),
                              ),
                            ]),
                      ),
                      Text(
                        '\$${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1, color: AppColors.border),

              // ── Messages list ────────────────────────────────
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _fs.donationChatStream(widget.donationId),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final msgs = snap.data ?? [];
                    if (msgs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text('Ningún mensaje aún',
                                style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              isRestaurant
                                  ? 'Inicia la conversación con la causa'
                                  : 'Inicia la conversación con el restaurante',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final msg = msgs[i];
                        final isMine =
                            msg['senderId'] == widget.currentUserId;
                        return _MessageBubble(
                          text: msg['text'] ?? '',
                          senderName: msg['senderName'] ?? '',
                          isMine: isMine,
                          timestamp: msg['createdAt'],
                          imageUrl: msg['imageUrl'],
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Action buttons ───────────────────────────────
              if (donation != null) ...[
                if (isRestaurant && status == 'pending')
                  _ActionBar(
                    label: 'Marcar como pagada',
                    color: AppColors.accent,
                    loading: _actionLoading,
                    onTap: () => _markPaid(donation),
                  ),
                if (isCause && status == 'paid') ...[
                  _ActionBar(
                    label: 'Sí me pagaron ✅',
                    color: AppColors.success,
                    loading: _actionLoading,
                    onTap: () => _confirmReceived(donation),
                  ),
                  _ActionBar(
                    label: 'No me pagaron ⚠️',
                    color: AppColors.error,
                    loading: _disputeLoading,
                    onTap: () => _disputePayment(donation),
                  ),
                ],
              ],

              // ── Input bar ────────────────────────────────────
              SafeArea(
                child: Container(
                  color: AppColors.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _uploadingImage ? null : _showImageSourceSheet,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _uploadingImage
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary, strokeWidth: 2),
                                )
                              : const Icon(Icons.attach_file_rounded,
                                  color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sending ? null : _send,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
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
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isMine;
  final dynamic timestamp;
  final String? imageUrl;

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.isMine,
    this.timestamp,
    this.imageUrl,
  });

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: isMine ? [] : cardShadow,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  senderName,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 120,
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2))),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isMine ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? Colors.white.withOpacity(0.65)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionBar({
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
