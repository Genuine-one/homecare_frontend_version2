import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/nurses_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kpi_card.dart';

/// Responsive KPI header for the Admin Nurses tab.
/// Desktop: flat banner + 3-col KPI row.
/// Mobile:  gradient banner with floating cards.
class AdminNursesHeader extends StatelessWidget {
  final NursesState state;
  const AdminNursesHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final kpiCards = [
      KpiCard(
        label:       'Total',
        value:       '${state.total}',
        icon:        Icons.people_rounded,
        accentColor: AppColors.adminColor,
        bgTint:      const Color(0xFFF3E5F5),
        delay:       0,
      ),
      KpiCard(
        label:       'Active',
        value:       '${state.activeCount}',
        icon:        Icons.check_circle_rounded,
        accentColor: AppColors.success,
        bgTint:      const Color(0xFFE8F5E9),
        delay:       80,
      ),
      KpiCard(
        label:       'Inactive',
        value:       '${state.inactiveCount}',
        icon:        Icons.cancel_rounded,
        accentColor: AppColors.error,
        bgTint:      const Color(0xFFFFEBEE),
        delay:       160,
      ),
    ];

    if (isDesktop) {
      return Column(
        children: [
          // Flat compact banner
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: const BoxDecoration(gradient: AppColors.adminGradient),
            child: Row(
              children: [
                Expanded(
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.badge_rounded,
                          color: Colors.white, size: 13),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resource Registry',
                            style: GoogleFonts.poppins(
                              color:      Colors.white.withValues(alpha: 0.70),
                              fontSize:   10,
                              fontWeight: FontWeight.w500,
                            )),
                        Text('Registered Resources',
                            style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   18,
                              fontWeight: FontWeight.w700,
                              height:     1.2,
                            )),
                      ],
                    ),
                  ]),
                ),
                Text('${state.total} total',
                    style: GoogleFonts.poppins(
                      color:    Colors.white.withValues(alpha: 0.60),
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          // KPI row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: kpiCards.asMap().entries.map((e) {
                final isLast = e.key == kpiCards.length - 1;
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

    // Mobile: gradient banner + floating KPI cards
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.adminGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
          child: Row(children: [
            Container(
              padding:    const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.badge_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Registered Resources',
                  style: GoogleFonts.poppins(
                    color:      Colors.white.withValues(alpha: 0.72),
                    fontSize:   11,
                    fontWeight: FontWeight.w500,
                  )),
              Text('All Resources',
                  style: GoogleFonts.poppins(
                    color:      Colors.white,
                    fontSize:   18,
                    fontWeight: FontWeight.w700,
                  )),
            ]),
          ]),
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: kpiCards.asMap().entries.map((e) {
                final isLast = e.key == kpiCards.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 10),
                    child: e.value,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
