import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kpi_card.dart';

/// Responsive header for the Admin Services tab.
/// Desktop: gradient banner + 3 KPI cards.
/// Mobile: solid admin-colour pill bar.
class AdminServicesHeader extends StatelessWidget {
  final int          total;
  final int          active;
  final int          inactive;
  final bool         isDesktop;
  final VoidCallback onRefresh;

  const AdminServicesHeader({
    super.key,
    required this.total,
    required this.active,
    required this.inactive,
    required this.isDesktop,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: const BoxDecoration(gradient: AppColors.adminGradient),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service Catalogue',
                          style: GoogleFonts.poppins(
                            color:         Colors.white.withValues(alpha: 0.72),
                            fontSize:      12,
                            fontWeight:    FontWeight.w500,
                            letterSpacing: 0.5,
                          )),
                      Text('Manage Services',
                          style: GoogleFonts.poppins(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
                IconButton(
                  icon:     const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: onRefresh,
                  tooltip:  'Refresh',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: KpiCard(
                    label:       'Total Services',
                    value:       '$total',
                    icon:        Icons.medical_services_rounded,
                    accentColor: AppColors.adminColor,
                    bgTint:      const Color(0xFFF3E5F5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    label:       'Active',
                    value:       '$active',
                    icon:        Icons.check_circle_rounded,
                    accentColor: AppColors.success,
                    bgTint:      const Color(0xFFE8F5E9),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    label:       'Inactive',
                    value:       '$inactive',
                    icon:        Icons.cancel_rounded,
                    accentColor: AppColors.error,
                    bgTint:      const Color(0xFFFFEBEE),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    // Mobile: gradient pill bar
    return Container(
      color:   AppColors.adminColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _Pill('Total',    '$total',    Colors.white),
          const SizedBox(width: 8),
          _Pill('Active',   '$active',   Colors.green.shade300),
          const SizedBox(width: 8),
          _Pill('Inactive', '$inactive', Colors.orange.shade300),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _Pill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:        Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
