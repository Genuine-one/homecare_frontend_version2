/// KLE HOMECARE — MIS Report filter row (searchable Service / Resource pickers).
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/searchable_dropdown.dart';
import '../../providers/mis_report_provider.dart';
import 'mis_common.dart';

class MisFilterRow extends ConsumerWidget {
  final MisReportState state;
  const MisFilterRow({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services  = state.availableServices;
    final resources = state.availableResources;
    if (services.isEmpty && resources.isEmpty) return const SizedBox.shrink();

    final hasFilter =
        state.serviceFilter != null || state.resourceFilter != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Label + Clear ──────────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: kMisColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.tune_rounded,
                size: 13, color: kMisColor)),
          const SizedBox(width: 8),
          Text('Filters', style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                color: AppColors.adminColor,
                shape: BoxShape.circle)),
          ],
          const Spacer(),
          if (hasFilter)
            GestureDetector(
              onTap: () {
                ref.read(misReportProvider.notifier).setServiceFilter(null);
                ref.read(misReportProvider.notifier).setResourceFilter(null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.close_rounded,
                      size: 11, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text('Clear All', style: GoogleFonts.poppins(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: AppColors.error)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        // ── Searchable dropdowns ──────────────────────────────────────
        Row(children: [
          if (services.isNotEmpty)
            Expanded(
              child: SearchableDropdown<String>(
                label: 'Service Type',
                icon: Icons.medical_services_outlined,
                value: state.serviceFilter,
                allLabel: 'All Services',
                items: services
                    .map((s) => SearchableDropdownItem(value: s, label: s))
                    .toList(),
                onChanged: (v) => ref
                    .read(misReportProvider.notifier)
                    .setServiceFilter(v),
                activeColor: const Color(0xFF00695C),
              ),
            ),
          if (services.isNotEmpty && resources.isNotEmpty)
            const SizedBox(width: 10),
          if (resources.isNotEmpty)
            Expanded(
              child: SearchableDropdown<String>(
                label: 'Resource',
                icon: Icons.person_outline_rounded,
                value: state.resourceFilter,
                allLabel: 'All Resources',
                items: resources.map((r) {
                  final name = r['name'] as String? ?? '';
                  final cat  = r['category'] as String?;
                  return SearchableDropdownItem(
                    value: r['id'] as String,
                    label: name,
                    subtitle: cat,
                  );
                }).toList(),
                onChanged: (v) => ref
                    .read(misReportProvider.notifier)
                    .setResourceFilter(v),
                activeColor: AppColors.nurseColor,
              ),
            ),
        ]),
      ]),
    ).animate().fadeIn(duration: 280.ms);
  }
}
