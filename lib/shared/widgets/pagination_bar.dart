import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Desktop page-number pagination bar.
///
/// Shows:  ← Prev  [1] [2] … [n]  Next →
/// Only renders when [totalPages] > 1.
class PaginationBar extends StatelessWidget {
  final int  currentPage;
  final int  totalPages;
  final int  totalItems;
  final int  pageSize;
  final bool isLoading;
  final void Function(int page) onPageChanged;
  final Color accentColor;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.isLoading  = false,
    this.accentColor = AppColors.adminColor,
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final start = ((currentPage - 1) * pageSize) + 1;
    final end   = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Info label
          Text(
            'Showing $start–$end of $totalItems',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color:    AppColors.textSecondary,
            ),
          ),

          const Spacer(),

          if (isLoading)
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: accentColor),
            )
          else ...[
            // Prev button
            _NavBtn(
              icon:      Icons.chevron_left_rounded,
              label:     'Prev',
              enabled:   currentPage > 1,
              onTap:     () => onPageChanged(currentPage - 1),
              accentColor: accentColor,
            ),

            const SizedBox(width: 6),

            // Page number buttons
            ..._buildPageNumbers(context),

            const SizedBox(width: 6),

            // Next button
            _NavBtn(
              icon:      Icons.chevron_right_rounded,
              label:     'Next',
              iconRight: true,
              enabled:   currentPage < totalPages,
              onTap:     () => onPageChanged(currentPage + 1),
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context) {
    if (totalPages <= 1) return [];

    final pages = <Widget>[];

    // Build visible page numbers with ellipsis when needed
    final visible = <int>{};
    visible.add(1);
    visible.add(totalPages);
    for (int i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i >= 1 && i <= totalPages) visible.add(i);
    }

    final sorted = visible.toList()..sort();

    int? prev;
    for (final p in sorted) {
      if (prev != null && p - prev > 1) {
        pages.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('…',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
        ));
      }
      pages.add(_PageBtn(
        page:        p,
        isSelected:  p == currentPage,
        onTap:       () => onPageChanged(p),
        accentColor: accentColor,
      ));
      prev = p;
    }

    return pages;
  }
}

class _PageBtn extends StatelessWidget {
  final int  page;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _PageBtn({
    required this.page,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: MouseRegion(
        cursor: isSelected ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32, height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text('$page',
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      isSelected ? Colors.white : AppColors.textSecondary,
                )),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     iconRight;
  final bool     enabled;
  final VoidCallback onTap;
  final Color accentColor;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.accentColor,
    this.iconRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accentColor : AppColors.textHint;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: enabled ? accentColor : AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: iconRight
                ? [
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    const SizedBox(width: 2),
                    Icon(icon, size: 16, color: color),
                  ]
                : [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 2),
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ],
          ),
        ),
      ),
    );
  }
}
