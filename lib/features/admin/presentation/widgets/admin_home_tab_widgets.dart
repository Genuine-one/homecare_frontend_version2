/// Private widgets for AdminHomeTab.
/// Extracted to keep the main tab file under 300 LOC.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';

// ── "Updated X ago" pill in mobile AppBar ────────────────────────────────────
class UpdatedAgoPill extends StatelessWidget {
  final String updatedAgo;
  const UpdatedAgoPill({super.key, required this.updatedAgo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin:  const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sync_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(updatedAgo,
              style: GoogleFonts.poppins(
                color:      Colors.white,
                fontSize:   10,
                fontWeight: FontWeight.w500,
              )),
        ]),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
class AdminSearchBar extends StatelessWidget {
  final TextEditingController  controller;
  final String                 query;
  final bool                   isDesktop;
  final ValueChanged<String>   onChanged;
  final VoidCallback           onClear;

  const AdminSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.isDesktop,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 20 : 12, 4, isDesktop ? 20 : 12, 0),
      child: TextField(
        controller: controller,
        onChanged:  (v) => onChanged(v.trim()),
        style:      GoogleFonts.poppins(fontSize: 12),
        decoration: InputDecoration(
          hintText:  'Search by name, city, service…',
          hintStyle: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 18),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textSecondary),
                  onPressed: onClear,
                )
              : null,
          filled:    true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.adminColor, width: 1.5)),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }
}

// ── Status filter chips ───────────────────────────────────────────────────────
class AdminStatusFilterChips extends StatelessWidget {
  final String?                selected;
  final bool                   isDesktop;
  final void Function(String?) onSelect;

  static const _statuses = <String?>[
    null, 'pending', 'assigned', 'in_progress', 'completed', 'cancelled',
  ];

  const AdminStatusFilterChips({
    super.key,
    required this.selected,
    required this.isDesktop,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 12, vertical: 4),
        children: _statuses.map((s) {
          final label      = s == null ? 'All' : AppHelpers.statusLabel(s);
          final isSelected = selected == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label,
                  style: GoogleFonts.poppins(
                    fontSize:   11,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  )),
              selected:        isSelected,
              selectedColor:   AppColors.adminColor,
              checkmarkColor:  Colors.white,
              backgroundColor: Colors.white,
              side: BorderSide(
                  color: isSelected
                      ? AppColors.adminColor
                      : AppColors.divider),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (_) => onSelect(s),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }
}

// ── Count row (with optional refresh button on desktop/web) ──────────────────
class AdminCountRow extends StatelessWidget {
  final int          count;
  final String       updatedAgo;
  final bool         isDesktop;
  final VoidCallback onRefresh;

  const AdminCountRow({
    super.key,
    required this.count,
    required this.updatedAgo,
    required this.isDesktop,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 20 : 12, 0, isDesktop ? 20 : 12, 2),
      child: Row(children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color:        AppColors.adminColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count request${count == 1 ? '' : 's'}',
          style: GoogleFonts.poppins(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (kIsWeb || isDesktop)
          AdminRefreshButton(
              updatedAgo: updatedAgo, onRefresh: onRefresh),
      ]),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class AdminEmptyState extends StatelessWidget {
  final bool         isDesktop;
  final VoidCallback onRefresh;
  const AdminEmptyState({
    super.key,
    required this.isDesktop,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 72, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('No requests found',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          if (kIsWeb || isDesktop)
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon:  const Icon(Icons.refresh_rounded,
                  color: AppColors.adminColor, size: 18),
              label: Text('Refresh',
                  style: GoogleFonts.poppins(
                      color: AppColors.adminColor, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.adminColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            )
          else
            Text('Pull down to refresh',
                style: GoogleFonts.poppins(
                    color: AppColors.textHint, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Animated refresh button (web/desktop) ────────────────────────────────────
class AdminRefreshButton extends StatefulWidget {
  final String       updatedAgo;
  final VoidCallback onRefresh;
  const AdminRefreshButton({
    super.key,
    required this.updatedAgo,
    required this.onRefresh,
  });

  @override
  State<AdminRefreshButton> createState() => _AdminRefreshButtonState();
}

class _AdminRefreshButtonState extends State<AdminRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _onTap() {
    _spin.forward(from: 0);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        AppColors.adminColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.adminColor.withValues(alpha: 0.20)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            RotationTransition(
              turns: _spin,
              child: const Icon(Icons.refresh_rounded,
                  size: 14, color: AppColors.adminColor),
            ),
            const SizedBox(width: 5),
            Text(
              widget.updatedAgo == 'just now'
                  ? 'Refresh'
                  : 'Updated ${widget.updatedAgo}',
              style: GoogleFonts.poppins(
                color:      AppColors.adminColor,
                fontSize:   11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
