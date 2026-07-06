import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kpi_card.dart';

// ── Reusable KPI data ─────────────────────────────────────────────────────────
List<KpiCard> _buildKpiCards(Map<String, dynamic> stats) => [
  KpiCard(
    label:       'Total Patients',
    value:       '${stats['total_patients'] ?? 0}',
    icon:        Icons.people_alt_rounded,
    accentColor: const Color(0xFF1565C0),
    bgTint:      const Color(0xFFE3F0FF),
    delay:       0,
  ),
  KpiCard(
    label:       'Active Nurses',
    value:       '${stats['total_nurses'] ?? 0}',
    icon:        Icons.medical_services_rounded,
    accentColor: const Color(0xFF00897B),
    bgTint:      const Color(0xFFE0F5F3),
    delay:       80,
  ),
  KpiCard(
    label:       'Pending',
    value:       '${stats['pending_requests'] ?? 0}',
    icon:        Icons.pending_actions_rounded,
    accentColor: const Color(0xFFF57F17),
    bgTint:      const Color(0xFFFFF3E0),
    delay:       160,
  ),
  KpiCard(
    label:       'Completed',
    value:       '${stats['completed_requests'] ?? 0}',
    icon:        Icons.task_alt_rounded,
    accentColor: const Color(0xFF2E7D32),
    bgTint:      const Color(0xFFE8F5E9),
    delay:       240,
  ),
];

String _monthName(int m) => const [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
][m];

// ── Admin dashboard header (responsive) ──────────────────────────────────────
class AdminDashboardHeader extends StatelessWidget {
  final Map<String, dynamic> stats;
  const AdminDashboardHeader({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    return isDesktop
        ? _DesktopHeader(stats: stats)
        : _MobileHeader(stats: stats);
  }
}

// ── Desktop: compact banner + 4-column KPI row ────────────────────────────────
class _DesktopHeader extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _DesktopHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final now     = DateTime.now();
    final dateStr =
        '${_monthName(now.month)} ${now.day}, ${now.year}';
    final kpis = _buildKpiCards(stats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient banner
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: const BoxDecoration(gradient: AppColors.adminGradient),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left — title
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.dashboard_rounded,
                          color: Colors.white, size: 13),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard Overview',
                            style: GoogleFonts.poppins(
                              color:         Colors.white.withValues(alpha: 0.70),
                              fontSize:      10,
                              fontWeight:    FontWeight.w500,
                              letterSpacing: 0.3,
                            )),
                        Text('Service Requests',
                            style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   18,
                              fontWeight: FontWeight.w700,
                              height:     1.2,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              // Right — date + live indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.calendar_today_rounded,
                          size:  11,
                          color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 5),
                      Text(dateStr,
                          style: GoogleFonts.poppins(
                            color:      Colors.white.withValues(alpha: 0.90),
                            fontSize:   11,
                            fontWeight: FontWeight.w500,
                          )),
                    ]),
                  ),
                  const SizedBox(height: 3),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Live · auto-refreshes every 15s',
                        style: GoogleFonts.poppins(
                          color:    Colors.white.withValues(alpha: 0.60),
                          fontSize: 10,
                        )),
                  ]),
                ],
              ),
            ],
          ),
        ),
        // KPI row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: kpis.asMap().entries.map((e) {
              final isLast = e.key == kpis.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 10),
                  child: e.value,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Mobile: gradient banner + floating 2×2 KPI grid ──────────────────────────
class _MobileHeader extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _MobileHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.adminGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color:        Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin Dashboard',
                  style: GoogleFonts.poppins(
                    color:         Colors.white.withValues(alpha: 0.72),
                    fontSize:      11,
                    fontWeight:    FontWeight.w500,
                    letterSpacing: 0.6,
                  )),
              Text('Overview',
                  style: GoogleFonts.poppins(
                    color:      Colors.white,
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                  )),
            ]),
          ]),
        ),
        // KPI cards float over banner
        Transform.translate(
          offset: const Offset(0, -32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(builder: (context, constraints) {
              final cardW = (constraints.maxWidth - 12) / 2;
              final ratio = cardW / 110;
              return GridView.count(
                crossAxisCount:   2,
                shrinkWrap:       true,
                physics:          const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: ratio,
                children: _buildKpiCards(stats),
              );
            }),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
