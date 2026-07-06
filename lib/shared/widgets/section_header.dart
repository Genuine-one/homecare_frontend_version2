import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// A section title with a small coloured vertical bar on the left.
/// Used in cards and detail sheets across all role screens.
class SectionHeader extends StatelessWidget {
  final String title;

  /// Colour of the left accent bar. Defaults to [AppColors.primary].
  final Color? accentColor;

  const SectionHeader(this.title, {super.key, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Row(
      children: [
        Container(
          width:  4,
          height: 16,
          decoration: BoxDecoration(
            color:        color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize:   13,
          ),
        ),
      ],
    );
  }
}
