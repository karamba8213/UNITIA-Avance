import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/cause.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

class DirectDonationScreen extends StatefulWidget {
  final Cause cause;
  const DirectDonationScreen({super.key, required this.cause});

  @override
  State<DirectDonationScreen> createState() => _DirectDonationScreenState();
}

class _DirectDonationScreenState extends State<DirectDonationScreen> {
  final _fs = FirestoreService();
  final _storage = StorageService();
  final _amountCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _chatMsgCtrl = TextEditingController();
  bool _submitting = false;
  bool _sendingMsg = false;
  bool _uploadingImg = false;
  String? _donationId;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _msgCtrl.dispose();
    _chatMsgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(AppLocalizations.of(context).directDonationInvalidAmount),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    final user = context.read<AuthProvider>().user;
    setState(() => _submitting = true);
    try {
      final id = await _fs.createDirectDonation(
        causeId: widget.cause.id,
        causeName: widget.cause.name,
        customerId: user?.uid,
        customerName: user?.name ?? '',
        customerEmail: user?.email ?? '',
        proposedAmount: amount,
        notes: _msgCtrl.text.trim(),
      );
      if (mounted) setState(() { _donationId = id; _submitting = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _sendMsg() async {
    final text = _chatMsgCtrl.text.trim();
    if (text.isEmpty || _donationId == null) return;
    final user = context.read<AuthProvider>().user;
    _chatMsgCtrl.clear();
    setState(() => _sendingMsg = true);
    try {
      await _fs.sendDirectDonationChatMessage(
        donationId: _donationId!,
        senderId: user?.uid ?? '',
        senderRole: 'customer',
        senderName: user?.name ?? '',
        text: text,
      );
    } finally {
      if (mounted) setState(() => _sendingMsg = false);
    }
  }

  Future<void> _sendImage() async {
    if (_donationId == null) return;
    final user = context.read<AuthProvider>().user;
    setState(() => _uploadingImg = true);
    try {
      final url = await _storage.pickAndUpload(
        path: 'direct_donations/$_donationId/proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (url != null && mounted) {
        await _fs.sendDirectDonationChatMessage(
          donationId: _donationId!,
          senderId: user?.uid ?? '',
          senderRole: 'customer',
          senderName: user?.name ?? '',
          text: '',
          imageUrl: url,
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImg = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bank = widget.cause.bankInfo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.directDonationTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cause header ──────────────────────────────
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: widget.cause.logo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(widget.cause.logo!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: AppColors.primary, size: 22)),
                            )
                          : const Icon(Icons.volunteer_activism_rounded,
                              color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.cause.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(widget.cause.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Bank info card ─────────────────────────────
                  if (bank != null &&
                      (bank['clabe']?.isNotEmpty ?? false)) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.account_balance_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.directDonationBankInfo,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5)),
                          ]),
                          const SizedBox(height: 16),
                          _BankRow(label: l10n.directDonationBank,
                              value: bank['banco'] ?? ''),
                          _BankRow(label: l10n.directDonationHolder,
                              value: bank['titular'] ?? ''),
                          _BankRow(
                            label: l10n.directDonationClabe,
                            value: bank['clabe'] ?? '',
                            copyable: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else if (bank == null) ...[
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.textMuted, size: 16),
                          const SizedBox(width: 8),
                          Text(l10n.directDonationNoBankInfo,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Form (before submission) ───────────────────
                  if (_donationId == null) ...[
                    Text(l10n.directDonationFormTitle,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.directDonationAmountLabel,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.,]'))
                            ],
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              hintText: '500.00',
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.directDonationMessageLabel,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _msgCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: l10n.directDonationMessageHint,
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: l10n.directDonationSubmit,
                      onPressed: _submit,
                      loading: _submitting,
                    ),
                  ] else ...[
                    // ── Chat area (after submission) ───────────────
                    Text(l10n.directDonationChatTitle,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(l10n.directDonationChatHint,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ChatMessages(
                      donationId: _donationId!,
                      currentUserId:
                          context.read<AuthProvider>().user?.uid ?? '',
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Chat input ─────────────────────────────────────────
          if (_donationId != null)
            _ChatInput(
              controller: _chatMsgCtrl,
              sending: _sendingMsg,
              uploadingImg: _uploadingImg,
              onSend: _sendMsg,
              onAttach: _sendImage,
            ),
        ],
      ),
    );
  }
}

// ── Bank info row ──────────────────────────────────────────────────────────────
class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _BankRow(
      {required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Copiado al portapapeles'),
                  duration: Duration(seconds: 1),
                ));
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.copy_rounded,
                    size: 16, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Chat messages ──────────────────────────────────────────────────────────────
class _ChatMessages extends StatelessWidget {
  final String donationId;
  final String currentUserId;
  const _ChatMessages(
      {required this.donationId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().directDonationChatStream(donationId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final messages = snap.data ?? [];
        if (messages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(l10n.directDonationNoChatYet,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
          );
        }
        return Column(
          children: messages
              .map((m) => _ChatBubble(
                    message: m,
                    isMe: m['senderId'] == currentUserId,
                  ))
              .toList(),
        );
      },
    );
  }
}

// ── Chat bubble ────────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final text = message['text'] as String? ?? '';
    final imageUrl = message['imageUrl'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volunteer_activism_rounded,
                  color: AppColors.primary, size: 15),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMuted),
                      ),
                    ),
                    if (text.isNotEmpty) const SizedBox(height: 6),
                  ],
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(
                          fontSize: 14,
                          color:
                              isMe ? Colors.white : AppColors.textPrimary,
                          height: 1.4),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat input ─────────────────────────────────────────────────────────────────
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool uploadingImg;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.uploadingImg,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
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
          // Image attach button
          GestureDetector(
            onTap: uploadingImg ? null : onAttach,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: uploadingImg
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file_rounded,
                      color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).directDonationTypeMessage,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: sending
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
    );
  }
}
