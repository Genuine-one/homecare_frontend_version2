import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Full-screen centred error state with a retry button.
/// [roleColor] tints the retry button; defaults to [AppColors.primary].
class ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  final Color?       roleColor;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = roleColor ?? AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color:    AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: Text('Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: color),
            ),
          ],
        ),
      ),
    );
  }
}
