import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class OrderChatScreen extends StatefulWidget {
  final String orderId;
  final String currentUserId;
  final String currentUserRole; // 'restaurant' | 'customer'
  final String currentUserName;
  final String otherPartyName;

  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.currentUserId,
    required this.currentUserRole,
    required this.currentUserName,
    required this.otherPartyName,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _fs         = FirestoreService();
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending     = false;

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
      await _fs.sendOrderChatMessage(
        orderId:    widget.orderId,
        senderId:   widget.currentUserId,
        senderRole: widget.currentUserRole,
        senderName: widget.currentUserName,
        text:       text,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherPartyName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text('Pedido #${widget.orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Messages list ──────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fs.orderChatStream(widget.orderId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
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
                        const Text('Sin mensajes aún',
                            style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          widget.currentUserRole == 'restaurant'
                              ? 'Envía un mensaje al cliente'
                              : 'Envía un mensaje al restaurante',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
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
                    final msg   = msgs[i];
                    final isMine = msg['senderId'] == widget.currentUserId;
                    return _MessageBubble(
                      text:       msg['text'] ?? '',
                      senderName: msg['senderName'] ?? '',
                      isMine:     isMine,
                      timestamp:  msg['createdAt'],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ──────────────────────────────────────────
          SafeArea(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
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
                      width: 42, height: 42,
                      decoration: const BoxDecoration(
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
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isMine;
  final dynamic timestamp;

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.isMine,
    this.timestamp,
  });

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
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
                child: Text(senderName,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            Text(text,
                style: TextStyle(
                    fontSize: 14,
                    color: isMine ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(_formatTime(timestamp),
                style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.65)
                        : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
