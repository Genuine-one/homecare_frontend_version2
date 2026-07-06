import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// A white card with a tinted icon badge, a large numeric value, and a label.
/// Used across admin, nurse, and patient dashboards.
class KpiCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    accentColor;
  final Color    bgTint;

  /// Optional stagger delay for the entry animation (milliseconds).
  final int delay;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgTint,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon badge
          Container(
            width:  26,
            height: 26,
            decoration: BoxDecoration(
              color:        bgTint,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: accentColor, size: 14),
          ),
          const SizedBox(height: 6),

          // Numeric value
          FittedBox(
            fit:       BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color:      const Color(0xFF1A202C),
                fontSize:   18,
                fontWeight: FontWeight.w800,
                height:     1.1,
              ),
            ),
          ),
          const SizedBox(height: 1),

          // Label
          Text(
            label,
            style: GoogleFonts.poppins(
              color:      const Color(0xFF718096),
              fontSize:   9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 350.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end:   const Offset(1.0, 1.0),
          delay: delay.ms,
          duration: 280.ms,
          curve:  Curves.easeOut,
        );
  }
}
