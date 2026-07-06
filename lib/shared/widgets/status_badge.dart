import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A small pill-shaped badge used for status, urgency, and category labels.
///
/// Identical in structure to the former `_Chip` (admin), `_StatusBadge` (nurse),
/// `_Badge` (nurses-tab), and `_TableBadge` (nurses-tab table) — all unified here.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;

  /// When `true` uses slightly smaller font/padding (urgency chips in cards).
  final bool small;

  const StatusBadge(
    this.label,
    this.color, {
    super.key,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical:   small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color:      color,
          fontSize:   small ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
