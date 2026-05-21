import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_usage.dart';
import '../providers/superadmin_providers.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_stat_card.dart';

/// Superadmin AI usage — aligns with web: metrics, model billing bar, daily
/// cost chart, Overview / By feature / Top creators.
class AiUsageScreen extends ConsumerStatefulWidget {
  const AiUsageScreen({super.key});

  @override
  ConsumerState<AiUsageScreen> createState() => _AiUsageScreenState();
}

class _AiUsageScreenState extends ConsumerState<AiUsageScreen> {
  String _period = '30d';
  int _detailSection = 0;

  static const _purple = Color(0xFF7C3AED);
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);
  static const _burgundy = Color(0xFF9D174D);

  @override
  Widget build(BuildContext context) {
    final aiUsageAsync = ref.watch(aiUsageProvider(period: _period));

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.psychology_rounded,
              size: 22,
              color: AppColors.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            const Text('AI usage'),
          ],
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _PeriodChip(
                  label: '24h',
                  isSelected: _period == '24h',
                  onTap: () => setState(() => _period = '24h'),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: '7 days',
                  isSelected: _period == '7d',
                  onTap: () => setState(() => _period = '7d'),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: '30 days',
                  isSelected: _period == '30d',
                  onTap: () => setState(() => _period = '30d'),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: '90 days',
                  isSelected: _period == '90d',
                  onTap: () => setState(() => _period = '90d'),
                ),
              ],
            ),
          ),
          Expanded(
            child: aiUsageAsync.when(
              data: (stats) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(aiUsageProvider(period: _period));
                  await ref.read(aiUsageProvider(period: _period).future);
                },
                child: _buildContent(context, stats),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load AI usage',
                        style: TextStyle(color: AppColors.textSecondaryOf(context)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(aiUsageProvider(period: _period)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AiUsageStats stats) {
    final fmtMoney = NumberFormat.currency(symbol: '\$', decimalDigits: 4);
    final fmtMoneyShort = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final compact = NumberFormat.decimalPattern();
    final s = stats.summary;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Platform-wide LLM usage, costs, and breakdown by feature, model, and creator.',
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          if (stats.byModel.isNotEmpty) ...[
            _ModelBillingBar(stats: stats, fmtMoney: fmtMoneyShort, compact: compact),
            const SizedBox(height: 16),
          ],
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.22,
            children: [
              AdminStatCard(
                title: 'Total Cost',
                value: fmtMoneyShort.format(s.totalCostUsd),
                icon: Icons.attach_money_rounded,
                iconColor: _purple,
              ),
              AdminStatCard(
                title: 'Total Requests',
                value: compact.format(s.totalRequests),
                icon: Icons.show_chart_rounded,
                iconColor: _blue,
              ),
              Tooltip(
                message:
                    'Input: ${compact.format(s.totalInputTokens)} · Output: ${compact.format(s.totalOutputTokens)}',
                child: AdminStatCard(
                  title: 'Tokens Used',
                  value: compact.format(s.totalTokens),
                  subtitle: 'input + output',
                  icon: Icons.memory_rounded,
                  iconColor: _green,
                ),
              ),
              AdminStatCard(
                title: 'Avg Cost/Req',
                value: _formatAvgCost(s.avgCostPerRequest, fmtMoney),
                icon: Icons.trending_flat_rounded,
                iconColor: AppColors.primary,
              ),
              AdminStatCard(
                title: 'Active Creators',
                value: compact.format(s.activeCreators),
                icon: Icons.people_outline_rounded,
                iconColor: _purple,
              ),
              AdminStatCard(
                title: 'Tokens Charged',
                value: compact.format(s.tokensCharged),
                icon: Icons.stars_rounded,
                iconColor: _burgundy,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailSectionChips(
            selected: _detailSection,
            onChanged: (i) => setState(() => _detailSection = i),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_detailSection) {
              0 => _OverviewSection(
                  key: const ValueKey('overview'),
                  stats: stats,
                ),
              1 => _ByFeatureSection(
                  key: const ValueKey('feature'),
                  stats: stats,
                ),
              _ => _TopCreatorsSection(
                  key: const ValueKey('creators'),
                  stats: stats,
                  fmtMoneyShort: fmtMoneyShort,
                  compact: compact,
                ),
            },
          ),
        ],
      ),
    );
  }

  String _formatAvgCost(double v, NumberFormat fmtMoney) {
    if (v <= 0) return '\$0';
    if (v < 0.0001) return fmtMoney.format(v);
    if (v < 0.01) return NumberFormat.currency(symbol: '\$', decimalDigits: 6).format(v);
    if (v < 1) return NumberFormat.currency(symbol: '\$', decimalDigits: 4).format(v);
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(v);
  }
}

class _ModelBillingBar extends StatelessWidget {
  const _ModelBillingBar({
    required this.stats,
    required this.fmtMoney,
    required this.compact,
  });

  final AiUsageStats stats;
  final NumberFormat fmtMoney;
  final NumberFormat compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = stats.byModel
        .map(
          (m) =>
              '${m.name} (${compact.format(m.requests)} — ${fmtMoney.format(m.costUsd)})',
        )
        .join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated.withValues(alpha: 0.55)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.memory_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'LLM models (billing records): $parts',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionChips extends StatelessWidget {
  const _DetailSectionChips({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int index) {
      final on = selected == index;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: on
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : AppColors.surfaceElevatedOf(context).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: on
                      ? AppColors.primary.withValues(alpha: 0.55)
                      : AppColors.borderOf(context).withValues(alpha: 0.4),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: on ? AppColors.primary : AppColors.textSecondaryOf(context),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Overview', 0),
        const SizedBox(width: 8),
        chip('By Feature', 1),
        const SizedBox(width: 8),
        chip('Top Creators', 2),
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    super.key,
    required this.stats,
  });

  final AiUsageStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          title: 'Daily Cost Trend',
          subtitle: 'Platform AI costs over time',
        ),
        const SizedBox(height: 8),
        if (stats.dailyCosts.isEmpty)
          _ChartPlaceholder(context)
        else
          _AiDailyCostAreaChart(daily: List.of(stats.dailyCosts)..sort((a, b) => a.date.compareTo(b.date))),
        if (stats.byProvider.isNotEmpty) ...[
          const SizedBox(height: 24),
          AdminSectionHeader(
            title: 'By Provider',
            subtitle: 'Usage breakdown by AI provider',
          ),
          const SizedBox(height: 8),
          _UsageBreakdownCard(items: stats.byProvider),
        ],
      ],
    );
  }

  Widget _ChartPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'No daily cost data for this period',
        style: TextStyle(color: AppColors.textMutedOf(context)),
      ),
    );
  }
}

class _ByFeatureSection extends StatelessWidget {
  const _ByFeatureSection({
    super.key,
    required this.stats,
  });

  final AiUsageStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stats.byFeature.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No usage by feature for this period',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMutedOf(context)),
            ),
          )
        else ...[
          AdminSectionHeader(
            title: 'By Feature',
            subtitle: 'Costs and requests per product area',
          ),
          const SizedBox(height: 8),
          _UsageBreakdownCard(items: stats.byFeature),
        ],
        if (stats.byModel.isNotEmpty) ...[
          const SizedBox(height: 20),
          AdminSectionHeader(
            title: 'By Model',
            subtitle: 'Per-model cost and volume',
          ),
          const SizedBox(height: 8),
          _UsageBreakdownCard(items: stats.byModel),
        ],
      ],
    );
  }
}

class _TopCreatorsSection extends StatelessWidget {
  const _TopCreatorsSection({
    super.key,
    required this.stats,
    required this.fmtMoneyShort,
    required this.compact,
  });

  final AiUsageStats stats;
  final NumberFormat fmtMoneyShort;
  final NumberFormat compact;

  @override
  Widget build(BuildContext context) {
    if (stats.topCreators.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No creator usage for this period',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMutedOf(context)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          title: 'Top Creators',
          subtitle: 'Highest AI consumers',
        ),
        const SizedBox(height: 8),
        ...List.generate(
          stats.topCreators.length.clamp(0, 20),
          (index) => _TopCreatorCard(
            rank: index + 1,
            creator: stats.topCreators[index],
            fmtMoney: fmtMoneyShort,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _AiDailyCostAreaChart extends StatelessWidget {
  const _AiDailyCostAreaChart({required this.daily});

  final List<AiDailyCost> daily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: LayoutBuilder(
        builder: (context, c) {
          return CustomPaint(
            painter: _DailyCostAreaPainter(
              daily: daily,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _DailyCostAreaPainter extends CustomPainter {
  const _DailyCostAreaPainter({
    required this.daily,
    required this.isDark,
  });

  final List<AiDailyCost> daily;
  final bool isDark;

  static const Color _line = Color(0xFF8B5CF6);

  @override
  void paint(Canvas canvas, Size size) {
    if (daily.isEmpty) return;

    const padL = 44.0;
    const padR = 12.0;
    const padT = 12.0;
    const padB = 28.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    final maxCost = daily.map((e) => e.costUsd).reduce(math.max);
    final minY = 0.0;
    final spanY = (maxCost <= 0 ? 1.0 : maxCost * 1.08).clamp(0.0001, double.infinity);

    Offset point(int i) {
      final n = daily.length;
      final x = n <= 1 ? padL + w / 2 : padL + w * (i / (n - 1));
      final yNorm = (daily[i].costUsd - minY) / spanY;
      final y = padT + h * (1 - yNorm.clamp(0.0, 1.0));
      return Offset(x, y);
    }

    final fillPath = Path()..moveTo(point(0).dx, padT + h);
    for (var i = 0; i < daily.length; i++) {
      fillPath.lineTo(point(i).dx, point(i).dy);
    }
    fillPath
      ..lineTo(point(daily.length - 1).dx, padT + h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _line.withValues(alpha: 0.35),
          _line.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, padT, size.width, h));

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < daily.length; i++) {
      final p0 = point(i - 1);
      final p1 = point(i);
      final mx = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = _line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = padT + h * (i / 3);
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);
    }

    final labelStyle = TextStyle(
      fontSize: 10,
      color: isDark
          ? Colors.white.withValues(alpha: 0.45)
          : Colors.black.withValues(alpha: 0.45),
    );
    void drawLabel(String text, Offset offset) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, offset);
    }

    final moneyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 4);
    for (var i = 0; i <= 3; i++) {
      final v = spanY * (1 - i / 3);
      drawLabel(
        moneyFmt.format(v),
        Offset(4, padT + h * (i / 3) - 6),
      );
    }

    if (daily.isNotEmpty) {
      final df = DateFormat.Md();
      drawLabel(df.format(daily.first.date), Offset(padL, size.height - 18));
      if (daily.length > 1) {
        final mid = daily[daily.length ~/ 2];
        drawLabel(
          df.format(mid.date),
          Offset(padL + w / 2 - 16, size.height - 18),
        );
        drawLabel(
          df.format(daily.last.date),
          Offset(size.width - padR - 36, size.height - 18),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DailyCostAreaPainter oldDelegate) {
    return oldDelegate.daily != daily || oldDelegate.isDark != isDark;
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primarySoft.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isSelected ? null : AppColors.surfaceElevatedOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.borderOf(context).withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _UsageBreakdownCard extends StatelessWidget {
  const _UsageBreakdownCard({required this.items});

  final List<AiUsageByCategory> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final compactFormat = NumberFormat.decimalPattern();

    final maxCost = items.map((e) => e.costUsd).reduce(math.max);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated.withValues(alpha: 0.55)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: items.map((item) {
          final percentage = maxCost > 0 ? (item.costUsd / maxCost) : 0.0;
          return _UsageRow(
            name: item.name,
            cost: currencyFormat.format(item.costUsd),
            requests: compactFormat.format(item.requests),
            tokens: compactFormat.format(item.tokens),
            percentage: percentage,
            isLast: item == items.last,
          );
        }).toList(),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.name,
    required this.cost,
    required this.requests,
    required this.tokens,
    required this.percentage,
    required this.isLast,
  });

  final String name;
  final String cost;
  final String requests;
  final String tokens;
  final double percentage;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  Text(
                    cost,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$requests req · $tokens tok',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppColors.surfaceElevatedOf(context),
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.primary.withValues(alpha: 0.6),
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: AppColors.borderOf(context).withValues(alpha: 0.2),
          ),
      ],
    );
  }
}

class _TopCreatorCard extends StatelessWidget {
  const _TopCreatorCard({
    required this.rank,
    required this.creator,
    required this.fmtMoney,
    required this.compact,
  });

  final int rank;
  final AiTopCreator creator;
  final NumberFormat fmtMoney;
  final NumberFormat compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated.withValues(alpha: 0.55)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: rank <= 3
                    ? AppColors.primary
                    : AppColors.textMutedOf(context),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.name ?? creator.email,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${compact.format(creator.requests)} requests · ${compact.format(creator.tokens)} tokens',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fmtMoney.format(creator.costUsd),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
