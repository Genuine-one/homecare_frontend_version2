/// KLE HOMECARE — MIS Report shared table cell widgets.
/// Used by both the Resources and Services paginated tables.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// White-on-color header cell for a fixed table header row.
class MisTableHeaderCell extends StatelessWidget {
  final String text;
  const MisTableHeaderCell(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    child: Text(text, style: GoogleFonts.poppins(
      color: Colors.white, fontSize: 10,
      fontWeight: FontWeight.w700, letterSpacing: 0.2)));
}

/// Standard padded table data cell.
class MisTableCell extends StatelessWidget {
  final Widget child;
  const MisTableCell({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    child: child);
}

/// Small pill showing a count, tinted with [color].
class MisCountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const MisCountBadge(this.count, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.25))),
    child: Text('$count', style: GoogleFonts.poppins(
      fontSize: 11, fontWeight: FontWeight.w700, color: color)));
}
