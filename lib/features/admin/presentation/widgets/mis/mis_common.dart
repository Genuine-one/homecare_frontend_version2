/// KLE HOMECARE — MIS Report shared constants & small widgets
/// Used across the header, filter row, KPI row, and both report tabs.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';

const kMisColor = AppColors.adminColor;
const kMisGrad  = AppColors.adminGradient;

/// Compact revenue label: ₹1.2L / ₹3.5k / ₹500
String fmtRupee(double v) {
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}k';
  return '₹${v.toInt()}';
}

/// Centred empty-state placeholder for a tab with no rows to show.
class MisEmpty extends StatelessWidget {
  final String label;
  const MisEmpty({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textHint),
      const SizedBox(height: 10),
      Text(label, style: GoogleFonts.poppins(
          fontSize: 13, color: AppColors.textHint)),
    ]),
  );
}
