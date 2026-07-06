import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum AppSnackType { success, error, warning, info }

/// KLE HOMECARE — Unified popup message helper.
/// Use this instead of building `SnackBar`s inline so every message in the
/// app (network errors, validation failures, success confirmations) shares
/// the same look, icon and behaviour.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final (Color color, IconData icon) = switch (type) {
      AppSnackType.success => (AppColors.success, Icons.check_circle_rounded),
      AppSnackType.error   => (AppColors.error, Icons.error_rounded),
      AppSnackType.warning => (AppColors.warning, Icons.warning_rounded),
      AppSnackType.info    => (AppColors.primary, Icons.info_rounded),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ));
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.error, duration: const Duration(seconds: 4));

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.info);
}
