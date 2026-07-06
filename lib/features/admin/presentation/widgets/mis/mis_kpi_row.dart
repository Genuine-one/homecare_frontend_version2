/// KLE HOMECARE — MIS Report animated KPI summary cards.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/mis_report_provider.dart';

class MisKpiRow extends StatelessWidget {
  final MisReportState state;
  final AnimationController kpi;
  const MisKpiRow({super.key, required this.state, required this.kpi});

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: kpi, curve: Curves.easeOut);
    final s = state.summary;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final cards = [
      _KpiSpec('Total Revenue',  s.totalRevenue.toDouble(),       true,
          Icons.currency_rupee_rounded,
          const [Color(0xFF00695C), Color(0xFF004D40)]),
      _KpiSpec('Total Requests', s.totalRequests.toDouble(),      false,
          Icons.assignment_outlined,
          const [Color(0xFF1565C0), Color(0xFF0D47A1)]),
      _KpiSpec('Completed',      s.totalCompleted.toDouble(),     false,
          Icons.check_circle_outline_rounded,
          const [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
      _KpiSpec('Patients Served', s.totalPatients.toDouble(),     false,
          Icons.people_outline_rounded,
          const [Color(0xFFE65100), Color(0xFFBF360C)]),
    ];

    if (isDesktop) {
      return Row(children: cards.asMap().entries.map((e) =>
          Expanded(child: Padding(
            padding: EdgeInsets.only(right: e.key < cards.length - 1 ? 12 : 0),
            child: _KpiCard(spec: e.value, anim: anim, delay: e.key * 70),
          ))).toList());
    }
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10, crossAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: cards.asMap().entries.map((e) =>
          _KpiCard(spec: e.value, anim: anim, delay: e.key * 70)).toList(),
    );
  }
}

class _KpiSpec {
  final String label;
  final double value;
  final bool   isRupee;
  final IconData icon;
  final List<Color> gradient;
  const _KpiSpec(this.label, this.value, this.isRupee, this.icon, this.gradient);
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: spec.gradient.last.withValues(alpha: 0.38),
          blurRadius: 14, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(children: [
        Positioned(right: -8, bottom: -8,
          child: Icon(spec.icon, size: 64,
              color: Colors.white.withValues(alpha: 0.10))),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(spec.icon, color: Colors.white, size: 16)),
          const SizedBox(height: 8),
          AnimatedBuilder(animation: anim, builder: (_, __) {
            final v = (anim.value * spec.value).round();
            final label = spec.isRupee
                ? (v >= 100000 ? '₹${(v / 100000).toStringAsFixed(1)}L'
                   : v >= 1000 ? '₹${(v / 1000).toStringAsFixed(1)}k'
                   : '₹$v')
                : '$v';
            return Text(label, style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: Colors.white, height: 1.0));
          }),
          const SizedBox(height: 2),
          Text(spec.label, style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.80))),
        ]),
      ]),
    )
    .animate()
    .fadeIn(delay: delay.ms, duration: 340.ms)
    .scale(begin: const Offset(.88, .88), end: const Offset(1, 1),
           delay: delay.ms, duration: 280.ms, curve: Curves.easeOut);
  }
}
