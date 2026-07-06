import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A frosted-glass feature row used on the left branded panel of login screens.
class LoginFeatureTile extends StatelessWidget {
  final IconData icon;
  final String   label;

  const LoginFeatureTile({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color:      Colors.white.withValues(alpha: 0.90),
                fontSize:   12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: Colors.white.withValues(alpha: 0.35), size: 14),
        ],
      ),
    );
  }
}
