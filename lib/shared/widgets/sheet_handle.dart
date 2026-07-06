import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// The small drag-handle bar shown at the top of every bottom sheet.
/// Renders a 40×4 rounded rectangle centred horizontally.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width:  40,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        decoration: BoxDecoration(
          color:        AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
