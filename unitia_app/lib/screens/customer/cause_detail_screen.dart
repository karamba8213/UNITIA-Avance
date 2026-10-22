import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/cause.dart';
import '../../core/models/cause_update.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import 'direct_donation_screen.dart';

class CauseDetailScreen extends StatelessWidget {
  final Cause cause;
  const CauseDetailScreen({super.key, required this.cause});

  @override
  Widget build(BuildContext context) {
    final progress = cause.targetAmount > 0
        ? (cause.totalRaised / cause.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B4332), AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  if (cause.logo != null)
                    Opacity(
                      opacity: 0.15,
                      child: Image.network(cause.logo!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  // Content
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cause.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Verificada',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        Text(
                          cause.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cause.description,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Progress card ─────────────────────────────
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progreso de la causa',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearPercentIndicator(
                          lineHeight: 12,
                          percent: progress,
                          backgroundColor: AppColors.border,
                          progressColor: AppColors.primary,
                          barRadius: const Radius.circular(6),
                          padding: EdgeInsets.zero,
                          animation: true,
                          animationDuration: 1000,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _StatChip(
                              icon: Icons.savings_rounded,
                              label: 'Recaudado',
                              value: _fmt(cause.totalRaised),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _StatChip(
                              icon: Icons.flag_rounded,
                              label: 'Meta',
                              value: _fmt(cause.targetAmount),
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            _StatChip(
                              icon: Icons.people_rounded,
                              label: 'Helpers',
                              value: '${cause.helpersCount}',
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Story ─────────────────────────────────────
                  if (cause.story.isNotEmpty) ...[
                    const Text('Nuestra historia',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    AppCard(
                      child: Text(
                        cause.story,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Direct donation ───────────────────────────
                  _DirectDonateSection(cause: cause),
                  const SizedBox(height: 20),

                  // ── Updates ───────────────────────────────────
                  const Text('Actualizaciones',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  _UpdatesList(causeId: cause.id),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}

// ── Direct donate section ──────────────────────────────────────────────────────
class _DirectDonateSection extends StatelessWidget {
  final Cause cause;
  const _DirectDonateSection({required this.cause});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bank = cause.bankInfo;
    final hasBank =
        bank != null && (bank['clabe']?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Donación directa',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasBank) ...[
                Row(children: [
                  const Icon(Icons.account_balance_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.directDonationBankInfo,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 14),
                _DetailBankRow(label: l10n.directDonationBank,
                    value: bank['banco'] ?? ''),
                _DetailBankRow(label: l10n.directDonationHolder,
                    value: bank['titular'] ?? ''),
                _DetailBankRow(
                  label: l10n.directDonationClabe,
                  value: bank['clabe'] ?? '',
                  copyable: true,
                ),
                const SizedBox(height: 4),
              ] else ...[
                const Text(
                  'Esta causa aún no ha configurado sus datos bancarios.',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4),
                ),
                const SizedBox(height: 12),
              ],
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DirectDonationScreen(cause: cause),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasBank ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism_rounded,
                          color: hasBank
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.directDonateButton,
                        style: TextStyle(
                          color: hasBank
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailBankRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _DetailBankRow(
      {required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Copiado'),
                  duration: Duration(seconds: 1),
                ));
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.copy_rounded,
                    size: 15, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Updates list ──────────────────────────────────────────────────────────────
class _UpdatesList extends StatelessWidget {
  final String causeId;
  const _UpdatesList({required this.causeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CauseUpdate>>(
      stream: FirestoreService().causeUpdatesStream(causeId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final updates = snap.data ?? [];
        if (updates.isEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 36, color: AppColors.border),
                    const SizedBox(height: 8),
                    const Text('Aún no hay actualizaciones',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
        return Column(
          children: updates.map((u) => _UpdateTile(update: u)).toList(),
        );
      },
    );
  }
}

class _UpdateTile extends StatelessWidget {
  final CauseUpdate update;
  const _UpdateTile({required this.update});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (update.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  update.imageUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.message,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtDate(update.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
