import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_provider.dart';
import '../../../../core/constants/app_colors.dart';

class AdminAnalyticsTab extends ConsumerStatefulWidget {
  const AdminAnalyticsTab({super.key});
  @override
  ConsumerState<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends ConsumerState<AdminAnalyticsTab>
    with SingleTickerProviderStateMixin {
  String     _period     = 'month';
  DateTimeRange? _customRange;
  late AnimationController _counter;

  static const _periods = [
    ('day', 'Today'), ('week', 'Week'), ('month', 'Month'), ('year', 'Year'),
  ];

  @override
  void initState() {
    super.initState();
    _counter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() { _counter.dispose(); super.dispose(); }

  void _applyPeriod(String p) {
    setState(() { _period = p; _customRange = null; });
    _counter.reset();
    ref.read(analyticsProvider.notifier).setPeriod(p).then((_) => _counter.forward());
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate:  DateTime.now(),
      initialDateRange: _customRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.adminColor)),
        child: child!),
    );
    if (picked != null && mounted) {
      setState(() { _customRange = picked; _period = 'custom'; });
      _counter.reset();
      // Pass custom range as a special period string
      final from = DateFormat('yyyy-MM-dd').format(picked.start);
      final to   = DateFormat('yyyy-MM-dd').format(picked.end);
      ref.read(analyticsProvider.notifier)
          .setPeriodCustom(from, to)
          .then((_) => _counter.forward());
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(analyticsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.adminColor)),
        error: (e, _) => _ErrView(
            message: e.toString(),
            onRetry: () => ref.read(analyticsProvider.notifier).refresh()),
        data: (s) {
          if (s.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.adminColor));
          }
          if (s.error != null) {
            return _ErrView(message: s.error!,
                onRetry: () => ref.read(analyticsProvider.notifier).refresh());
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_counter.status == AnimationStatus.dismissed) _counter.forward();
          });
          return _build(s);
        },
      ),
    );
  }

  Widget _build(AnalyticsState s) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: RefreshIndicator(
          color: AppColors.adminColor,
          onRefresh: () async {
            _counter.reset();
            await ref.read(analyticsProvider.notifier).refresh();
            _counter.forward();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Gradient header ─────────────────────────────────────
                _Header(
                  period: _period, periods: _periods,
                  customRange: _customRange,
                  onPeriod: _applyPeriod,
                  onCustom: _pickCustomRange,
                  onRefresh: () {
                    _counter.reset();
                    ref.read(analyticsProvider.notifier).refresh()
                        .then((_) => _counter.forward());
                  },
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      isDesktop ? 24 : 16, 20,
                      isDesktop ? 24 : 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── KPI grid ──────────────────────────────────────
                      _KpiGrid(state: s, counter: _counter),
                      const SizedBox(height: 20),
                      // ── Revenue breakdown card ────────────────────────
                      _RevenueCard(state: s, counter: _counter),
                      const SizedBox(height: 20),
                      // ── Charts ────────────────────────────────────────
                      if (isDesktop)
                        Row(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _RequestsChart(state: s)),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _PieChart(state: s)),
                          ])
                      else ...[
                        _RequestsChart(state: s),
                        const SizedBox(height: 16),
                        _PieChart(state: s),
                      ],
                      const SizedBox(height: 20),
                      _RevenueBar(state: s),
                      const SizedBox(height: 20),
                      _Leaderboard(state: s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gradient header with period chips + calendar ──────────────────────────────
class _Header extends StatelessWidget {
  final String   period;
  final List<(String, String)> periods;
  final DateTimeRange? customRange;
  final void Function(String) onPeriod;
  final VoidCallback onCustom, onRefresh;
  const _Header({required this.period, required this.periods,
    required this.customRange, required this.onPeriod,
    required this.onCustom, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.adminGradient),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics', style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 10, fontWeight: FontWeight.w500)),
              Text('Reports & Insights', style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w700, height: 1.2)),
            ])),
          // Refresh
          IconButton(icon: const Icon(Icons.refresh_rounded,
              color: Colors.white, size: 18),
            onPressed: onRefresh, padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 12),
        // Period chips + calendar button
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            ...periods.map((p) {
              final sel = period == p.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onPeriod(p.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35))),
                    child: Text(p.$2, style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: sel ? AppColors.adminColor : Colors.white)),
                  ),
                ),
              );
            }),
            // Calendar picker button
            GestureDetector(
              onTap: onCustom,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: period == 'custom'
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: period == 'custom'
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 13,
                      color: period == 'custom'
                          ? AppColors.adminColor : Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    period == 'custom' && customRange != null
                        ? '${DateFormat('dd MMM').format(customRange!.start)} – '
                          '${DateFormat('dd MMM').format(customRange!.end)}'
                        : 'Custom',
                    style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: period == 'custom'
                          ? AppColors.adminColor : Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Animated counter helper ───────────────────────────────────────────────────
class _AnimCount extends StatelessWidget {
  final Animation<double> anim;
  final double target;
  final bool isRupee;
  const _AnimCount({required this.anim, required this.target,
      this.isRupee = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final v = (anim.value * target).round();
        final label = isRupee
            ? (v >= 100000 ? '₹${(v / 100000).toStringAsFixed(1)}L'
               : v >= 1000 ? '₹${(v / 1000).toStringAsFixed(1)}k'
               : '₹$v')
            : '$v';
        return Text(label, style: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w800,
          color: Colors.white, height: 1.0));
      },
    );
  }
}

// ── KPI grid — 2×2 + 1 wide on desktop ───────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final AnalyticsState       state;
  final AnimationController  counter;
  const _KpiGrid({required this.state, required this.counter});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 900;

    final anim = CurvedAnimation(parent: counter, curve: Curves.easeOut);

    final cards = [
      _KpiSpec('Total Requests', state.totalRequests.toDouble(), false,
          Icons.assignment_outlined,
          const [Color(0xFF7B1FA2), Color(0xFF4A148C)], ''),
      _KpiSpec('Pending', state.totalPending.toDouble(), false,
          Icons.pending_actions_rounded,
          const [Color(0xFFF57F17), Color(0xFFE65100)], ''),
      _KpiSpec('Assigned', state.totalAssigned.toDouble(), false,
          Icons.assignment_ind_rounded,
          const [Color(0xFF1565C0), Color(0xFF0D47A1)], ''),
      _KpiSpec('Completed', state.totalCompleted.toDouble(), false,
          Icons.check_circle_outline_rounded,
          const [Color(0xFF2E7D32), Color(0xFF1B5E20)], ''),
    ];

    if (isDesktop) {
      return Row(children: cards.asMap().entries.map((e) =>
          Expanded(child: Padding(
            padding: EdgeInsets.only(right: e.key < cards.length - 1 ? 14 : 0),
            child: _KpiCard(spec: e.value, anim: anim, delay: e.key * 80),
          ))).toList());
    }
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards.asMap().entries.map((e) =>
          _KpiCard(spec: e.value, anim: anim, delay: e.key * 80)).toList(),
    );
  }
}

class _KpiSpec {
  final String label;
  final double value;
  final bool   isRupee;
  final IconData icon;
  final List<Color> gradient;
  final String sub;
  const _KpiSpec(this.label, this.value, this.isRupee,
      this.icon, this.gradient, this.sub);
}

class _KpiCard extends StatelessWidget {
  final _KpiSpec spec;
  final Animation<double> anim;
  final int delay;
  const _KpiCard({required this.spec, required this.anim, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: spec.gradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: spec.gradient.last.withValues(alpha: 0.40),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(18),
      child: Stack(children: [
        // Background watermark icon
        Positioned(right: -8, bottom: -8,
          child: Icon(spec.icon, size: 72,
              color: Colors.white.withValues(alpha: 0.10))),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(spec.icon, color: Colors.white, size: 18)),
            const SizedBox(height: 10),
            _AnimCount(anim: anim, target: spec.value, isRupee: spec.isRupee),
            const SizedBox(height: 4),
            Text(spec.label, style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.80))),
          ]),
      ]),
    ).animate()
        .fadeIn(delay: delay.ms, duration: 350.ms)
        .scale(begin: const Offset(.88, .88), end: const Offset(1, 1),
               delay: delay.ms, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ── Revenue breakdown card ────────────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  final AnalyticsState      state;
  final AnimationController counter;
  const _RevenueCard({required this.state, required this.counter});

  String _fmt(double v) => v >= 100000
      ? '₹${(v / 100000).toStringAsFixed(2)}L'
      : v >= 1000 ? '₹${(v / 1000).toStringAsFixed(1)}k'
      : '₹${v.toInt()}';

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: counter, curve: Curves.easeOut);
    // totalRevenue = sum of completed payments in period
    // totalExpected = sum of total_amount for all requests in period
    final received  = state.totalRevenue;
    final expected  = state.totalExpectedRevenue;
    final pending   = (expected - received).clamp(0.0, double.infinity);
    final pct       = expected > 0 ? received / expected : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF004D40)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: const Color(0xFF00695C).withValues(alpha: 0.35),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(22),
      child: Stack(children: [
        Positioned(right: -10, top: -10,
          child: Icon(Icons.account_balance_wallet_rounded,
              size: 100, color: Colors.white.withValues(alpha: 0.07))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.currency_rupee_rounded,
                  color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Text('Revenue Summary', style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          // Three cells
          Row(children: [
            Expanded(child: _RevCell(
              label: 'Received',
              anim: anim, value: received,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF80CBC4))),
            const SizedBox(width: 1),
            Container(width: 1, height: 48,
                color: Colors.white.withValues(alpha: 0.20)),
            const SizedBox(width: 1),
            Expanded(child: _RevCell(
              label: 'Pending',
              anim: anim, value: pending,
              icon: Icons.hourglass_top_rounded,
              color: const Color(0xFFFFCC80))),
            Container(width: 1, height: 48,
                color: Colors.white.withValues(alpha: 0.20)),
            Expanded(child: _RevCell(
              label: 'Total Expected',
              anim: anim, value: expected,
              icon: Icons.pie_chart_rounded,
              color: Colors.white)),
          ]),
          const SizedBox(height: 18),
          // Progress bar
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Collection Rate', style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 11, fontWeight: FontWeight.w500)),
                AnimatedBuilder(animation: anim, builder: (_, __) =>
                  Text('${(anim.value * pct * 100).round()}%',
                      style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700))),
              ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AnimatedBuilder(animation: anim, builder: (_, __) =>
                LinearProgressIndicator(
                  value: (anim.value * pct).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF80CBC4))))),
          ]),
        ]),
      ]),
    ).animate().fadeIn(delay: 320.ms, duration: 400.ms)
        .slideY(begin: 0.06, end: 0,
                delay: 320.ms, duration: 350.ms, curve: Curves.easeOut);
  }
}

class _RevCell extends StatelessWidget {
  final String label;
  final Animation<double> anim;
  final double value;
  final IconData icon;
  final Color color;
  const _RevCell({required this.label, required this.anim,
      required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(height: 4),
    AnimatedBuilder(animation: anim, builder: (_, __) {
      final v = (anim.value * value).round();
      final s = v >= 100000 ? '₹${(v/100000).toStringAsFixed(1)}L'
              : v >= 1000   ? '₹${(v/1000).toStringAsFixed(1)}k'
              : '₹$v';
      return Text(s, style: GoogleFonts.poppins(
        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800));
    }),
    const SizedBox(height: 2),
    Text(label, style: GoogleFonts.poppins(
      color: Colors.white.withValues(alpha: 0.65),
      fontSize: 10, fontWeight: FontWeight.w500),
      textAlign: TextAlign.center),
  ]);
}

// ── Requests line chart ───────────────────────────────────────────────────────
class _RequestsChart extends StatelessWidget {
  final AnalyticsState state;
  const _RequestsChart({required this.state});

  @override
  Widget build(BuildContext context) {
    final spots = state.requestsSeries.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final maxY = (state.requestsSeries.isEmpty ? 1.0
        : state.requestsSeries.reduce((a, b) => a > b ? a : b)) + 1;
    return _Card(
      title: 'Service Requests', subtitle: 'Trend over period',
      icon: Icons.show_chart_rounded, color: AppColors.adminColor,
      child: SizedBox(height: 200,
        child: spots.isEmpty ? _Empty() : LineChart(LineChartData(
          minY: 0, maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false,
            horizontalInterval: (maxY / 4).ceilToDouble().clamp(1, 9999),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.divider, strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 9, color: AppColors.textHint)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 22,
              interval: (state.buckets.length / 6).ceilToDouble().clamp(1, 9999),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= state.buckets.length) return const SizedBox.shrink();
                return Text(state.buckets[i], style: GoogleFonts.poppins(
                    fontSize: 8, color: AppColors.textHint));
              })),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [LineChartBarData(
            spots: spots, isCurved: true, curveSmoothness: 0.35,
            color: AppColors.adminColor, barWidth: 2.5,
            dotData: FlDotData(show: spots.length <= 15),
            belowBarData: BarAreaData(show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [AppColors.adminColor.withValues(alpha: 0.18),
                         AppColors.adminColor.withValues(alpha: 0)])),
          )],
        ))),
    );
  }
}

// ── Status pie chart ─────────────────────────────────────────────────────────
class _PieChart extends StatefulWidget {
  final AnalyticsState state;
  const _PieChart({required this.state});
  @override State<_PieChart> createState() => _PieState();
}
class _PieState extends State<_PieChart> {
  int _touch = -1;
  static const _cols = {
    'pending':Color(0xFFF57F17),'assigned':Color(0xFF1565C0),
    'in_progress':Color(0xFF7B1FA2),'completed':Color(0xFF2E7D32),
    'cancelled':Color(0xFFB71C1C),
  };
  @override
  Widget build(BuildContext context) {
    final bd = widget.state.statusBreakdown;
    final total = bd.values.fold(0, (a, b) => a + b);
    if (total == 0) return _Card(title:'Status Breakdown',subtitle:'Distribution',
        icon:Icons.pie_chart_outline_rounded,color:const Color(0xFF7B1FA2),
        child:SizedBox(height:200,child:_Empty()));
    final sections = bd.entries.toList().asMap().entries.map((e) {
      final touched = e.key == _touch;
      final col = _cols[e.value.key] ?? AppColors.textSecondary;
      return PieChartSectionData(
        value: e.value.value.toDouble(), color: col,
        radius: touched ? 72.0 : 58.0,
        title: '${((e.value.value/total)*100).round()}%',
        titleStyle: GoogleFonts.poppins(fontSize: touched ? 13 : 10,
          fontWeight: FontWeight.w700, color: Colors.white));
    }).toList();
    return _Card(title:'Status Breakdown',subtitle:'Request distribution',
      icon:Icons.pie_chart_outline_rounded,color:const Color(0xFF7B1FA2),
      child:Column(children:[
        SizedBox(height:180,child:PieChart(PieChartData(
          sections:sections,centerSpaceRadius:36,sectionsSpace:2,
          startDegreeOffset:-90,
          pieTouchData:PieTouchData(touchCallback:(evt,res){
            setState((){_touch=res?.touchedSection?.touchedSectionIndex??-1;});
          })))),
        const SizedBox(height:12),
        Wrap(spacing:10,runSpacing:6,children:bd.entries.map((e){
          final col=_cols[e.key]??AppColors.textSecondary;
          final lbl=e.key.replaceAll('_',' ').split(' ')
              .map((w)=>w.isEmpty?'':'${w[0].toUpperCase()}${w.substring(1)}').join(' ');
          return Row(mainAxisSize:MainAxisSize.min,children:[
            Container(width:9,height:9,decoration:BoxDecoration(
                color:col,borderRadius:BorderRadius.circular(3))),
            const SizedBox(width:4),
            Text('$lbl (${e.value})',style:GoogleFonts.poppins(
                fontSize:10,color:AppColors.textSecondary)),
          ]);
        }).toList()),
      ]));
  }
}

// ── Revenue bar chart ────────────────────────────────────────────────────────
class _RevenueBar extends StatelessWidget {
  final AnalyticsState state;
  const _RevenueBar({required this.state});
  @override
  Widget build(BuildContext context) {
    final maxY = (state.revenueSeries.isEmpty ? 1.0
        : state.revenueSeries.reduce((a,b)=>a>b?a:b)) * 1.2;
    final groups = state.revenueSeries.asMap().entries.map((e) =>
      BarChartGroupData(x:e.key,barRods:[BarChartRodData(
        toY:e.value,
        gradient:const LinearGradient(
          begin:Alignment.bottomCenter,end:Alignment.topCenter,
          colors:[Color(0xFF00695C),Color(0xFF26A69A)]),
        width: state.buckets.length > 20 ? 6 : 14,
        borderRadius:const BorderRadius.vertical(top:Radius.circular(5)),
      )])).toList();
    return _Card(
      title:'Revenue (₹)',subtitle:'Collected payments by period',
      icon:Icons.bar_chart_rounded,color:const Color(0xFF00695C),
      child:SizedBox(height:220,
        child:state.revenueSeries.every((v)=>v==0)?_Empty():BarChart(BarChartData(
          maxY:maxY.clamp(1,double.infinity),
          gridData:FlGridData(show:true,drawVerticalLine:false,
            getDrawingHorizontalLine:(_)=>FlLine(
                color:AppColors.divider,strokeWidth:1)),
          titlesData:FlTitlesData(
            leftTitles:AxisTitles(sideTitles:SideTitles(
              showTitles:true,reservedSize:44,
              getTitlesWidget:(v,_){
                if(v==0)return const SizedBox.shrink();
                final s=v>=1000?'₹${(v/1000).toStringAsFixed(0)}k':'₹${v.toInt()}';
                return Text(s,style:GoogleFonts.poppins(
                    fontSize:9,color:AppColors.textHint));
              })),
            bottomTitles:AxisTitles(sideTitles:SideTitles(
              showTitles:true,reservedSize:22,
              interval:(state.buckets.length/6).ceilToDouble().clamp(1,9999),
              getTitlesWidget:(v,_){
                final i=v.toInt();
                if(i<0||i>=state.buckets.length) return const SizedBox.shrink();
                return Text(state.buckets[i],style:GoogleFonts.poppins(
                    fontSize:8,color:AppColors.textHint));
              })),
            rightTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),
            topTitles:  const AxisTitles(sideTitles:SideTitles(showTitles:false)),
          ),
          borderData:FlBorderData(show:false),
          barGroups:groups,
          barTouchData:BarTouchData(touchTooltipData:BarTouchTooltipData(
            getTooltipItem:(grp,_,rod,__)=>BarTooltipItem(
              '₹${rod.toY.toInt()}',GoogleFonts.poppins(
                  color:Colors.white,fontSize:11,fontWeight:FontWeight.w600)),
          )),
        ))),
    );
  }
}

// ── Nurse leaderboard ─────────────────────────────────────────────────────────
class _Leaderboard extends StatelessWidget {
  final AnalyticsState state;
  const _Leaderboard({required this.state});
  @override
  Widget build(BuildContext context) {
    final nurses = state.nurseLeaderboard;
    return _Card(
      title:'Resource Leaderboard',subtitle:'Jobs assigned this period',
      icon:Icons.leaderboard_rounded,color:AppColors.nurseColor,
      child:nurses.isEmpty
        ? Padding(padding:const EdgeInsets.symmetric(vertical:24),
            child:Center(child:Text('No assignments this period',
                style:GoogleFonts.poppins(color:AppColors.textHint,fontSize:12))))
        : Column(children:nurses.asMap().entries.map((e){
            final idx=e.key; final n=e.value;
            final jobs=n['jobs'] as int? ?? 0;
            final frac=(jobs/(nurses.first['jobs'] as int? ?? 1)).clamp(.0,1.0);
            final medal=idx==0?'🥇':idx==1?'🥈':idx==2?'🥉':'${idx+1}.';
            final barColor=idx==0?const Color(0xFFFFD700)
                :idx==1?const Color(0xFFC0C0C0)
                :idx==2?const Color(0xFFCD7F32):AppColors.nurseColor;
            return Padding(padding:const EdgeInsets.only(bottom:12),
              child:Row(children:[
                SizedBox(width:28,child:Text(medal,
                    style:const TextStyle(fontSize:14))),
                const SizedBox(width:8),
                Expanded(child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Row(children:[
                      Expanded(child:Text(n['name'] as String? ?? '—',
                          style:GoogleFonts.poppins(fontSize:12,
                              fontWeight:FontWeight.w600,
                              color:AppColors.textPrimary))),
                      Text('$jobs job${jobs==1?'':'s'}',
                          style:GoogleFonts.poppins(fontSize:11,
                              fontWeight:FontWeight.w700,
                              color:AppColors.nurseColor)),
                    ]),
                    const SizedBox(height:4),
                    ClipRRect(borderRadius:BorderRadius.circular(4),
                      child:LinearProgressIndicator(
                        value:frac,minHeight:6,
                        backgroundColor:AppColors.divider,
                        valueColor:AlwaysStoppedAnimation(barColor))),
                  ])),
              ]));
          }).toList()),
    );
  }
}

// ── Shared card wrapper ───────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title,subtitle;
  final IconData icon; final Color color; final Widget child;
  const _Card({required this.title,required this.subtitle,
    required this.icon,required this.color,required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding:const EdgeInsets.all(18),
    decoration:BoxDecoration(color:Colors.white,
      borderRadius:BorderRadius.circular(18),
      boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:0.06),
        blurRadius:14,offset:const Offset(0,5))]),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Container(width:34,height:34,
          decoration:BoxDecoration(color:color.withValues(alpha:.12),
              borderRadius:BorderRadius.circular(9)),
          child:Icon(icon,color:color,size:17)),
        const SizedBox(width:10),
        Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title,style:GoogleFonts.poppins(fontSize:13,
              fontWeight:FontWeight.w700,color:AppColors.textPrimary)),
          Text(subtitle,style:GoogleFonts.poppins(fontSize:10,
              color:AppColors.textSecondary)),
        ]),
      ]),
      const SizedBox(height:16),
      child,
    ]),
  ).animate().fadeIn(duration:350.ms);
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child:Column(
    mainAxisAlignment:MainAxisAlignment.center,children:[
      const Icon(Icons.bar_chart_rounded,size:40,color:AppColors.textHint),
      const SizedBox(height:8),
      Text('No data for this period',style:GoogleFonts.poppins(
          fontSize:12,color:AppColors.textHint)),
    ]));
}

class _ErrView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrView({required this.message,required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child:Padding(
    padding:const EdgeInsets.all(24),
    child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      const Icon(Icons.error_outline,size:52,color:AppColors.error),
      const SizedBox(height:16),
      Text(message,textAlign:TextAlign.center,
          style:GoogleFonts.poppins(color:AppColors.textSecondary)),
      const SizedBox(height:20),
      ElevatedButton.icon(onPressed:onRetry,
        icon:const Icon(Icons.refresh_rounded),label:const Text('Retry'),
        style:ElevatedButton.styleFrom(backgroundColor:AppColors.adminColor)),
    ])));
}
