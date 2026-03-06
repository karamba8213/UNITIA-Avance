import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_card.dart';

class CauseRankingScreen extends StatefulWidget {
  const CauseRankingScreen({super.key});
  @override
  State<CauseRankingScreen> createState() => _CauseRankingScreenState();
}

class _CauseRankingScreenState extends State<CauseRankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _fs = FirestoreService();

  // Cache por periodo
  final Map<String, List<Map<String, dynamic>>?> _data = {
    'all': null,
    'monthly': null,
    'weekly': null,
  };
  final Map<String, bool> _loading = {
    'all': true,
    'monthly': true,
    'weekly': true,
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load('all');
    _load('monthly');
    _load('weekly');
  }

  Future<void> _load(String period) async {
    final result = await _fs.getCausesRanking(period: period);
    if (mounted) {
      setState(() {
        _data[period]    = result;
        _loading[period] = false;
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ranking de Causas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Histórico'),
            Tab(text: 'Mensual'),
            Tab(text: 'Semanal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _RankingList(
            data: _data['all'],
            loading: _loading['all']!,
            onRefresh: () => _load('all'),
          ),
          _RankingList(
            data: _data['monthly'],
            loading: _loading['monthly']!,
            onRefresh: () => _load('monthly'),
          ),
          _RankingList(
            data: _data['weekly'],
            loading: _loading['weekly']!,
            onRefresh: () => _load('weekly'),
          ),
        ],
      ),
    );
  }
}

// ── Ranking list ──────────────────────────────────────────────────────────────
class _RankingList extends StatelessWidget {
  final List<Map<String, dynamic>>? data;
  final bool loading;
  final VoidCallback onRefresh;

  const _RankingList({
    required this.data,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (data == null || data!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: AppColors.border),
            SizedBox(height: 12),
            Text('No hay datos para este periodo',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: data!.length,
        itemBuilder: (_, i) => _RankingTile(rank: i + 1, item: data![i]),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> item;
  const _RankingTile({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    final name       = (item['name'] ?? item['causeName'] ?? '') as String;
    final raised     = (item['totalRaised'] ?? 0.0).toDouble();
    final target     = (item['targetAmount'] ?? 0.0).toDouble();
    final helpers    = (item['helpersCount'] ?? 0) as int;
    final logo       = item['logo'] as String?;
    final progress   = target > 0 ? (raised / target).clamp(0.0, 1.0) : 0.0;

    final isTop3     = rank <= 3;
    final medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isTop3 ? medalColor.withOpacity(0.15) : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isTop3
                    ? Text(
                        rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                        style: const TextStyle(fontSize: 18),
                      )
                    : Text(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Logo
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: logo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(logo, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.volunteer_activism,
                                  color: AppColors.primary, size: 22)),
                    )
                  : const Icon(Icons.volunteer_activism,
                      color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  LinearPercentIndicator(
                    lineHeight: 5,
                    percent: progress,
                    backgroundColor: AppColors.border,
                    progressColor: isTop3 ? medalColor : AppColors.primary,
                    barRadius: const Radius.circular(3),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _fmt(raised),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(' · ',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      Text(
                        '$helpers personas',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}
