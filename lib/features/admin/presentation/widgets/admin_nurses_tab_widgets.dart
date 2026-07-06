/// Private-use widgets extracted from admin_nurses_tab.dart.
/// All widgets here are only used by that one screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/nurses_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'admin_nurse_shared.dart';

// ── Dual FAB (Categories + Add Resource) ─────────────────────────────────────
class NursesFab extends StatelessWidget {
  final VoidCallback onCategories;
  final VoidCallback onAdd;
  const NursesFab({
    super.key,
    required this.onCategories,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize:       MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag:         'categories_fab',
          onPressed:       onCategories,
          backgroundColor: AppColors.adminColor.withValues(alpha: 0.15),
          foregroundColor: AppColors.adminColor,
          elevation:       0,
          icon:  const Icon(Icons.category_outlined, size: 18),
          label: Text('Categories',
              style: GoogleFonts.poppins(
                  color:      AppColors.adminColor,
                  fontWeight: FontWeight.w600,
                  fontSize:   13)),
          tooltip: 'Manage resource categories',
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag:         'resources_fab',
          onPressed:       onAdd,
          backgroundColor: AppColors.adminColor,
          icon:  const Icon(Icons.person_add_rounded, color: Colors.white),
          label: Text('Add Resource',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          tooltip: 'Create new resource account',
        ),
      ],
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
class NursesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String               query;
  final bool                 isDesktop;
  final ValueChanged<String> onChanged;
  final VoidCallback         onClear;

  const NursesSearchBar({
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
          isDesktop ? 20 : 16, 4, isDesktop ? 20 : 16, 0),
      child: TextField(
        controller: controller,
        onChanged:  (v) => onChanged(v.trim()),
        style:      GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText:  'Search by name, email, city…',
          hintStyle: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textSecondary),
                  onPressed: onClear,
                )
              : null,
          filled:    true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

// ── Filter pills bar ──────────────────────────────────────────────────────────
class NursesFilterBar extends StatelessWidget {
  final NursesState        state;
  final bool?              selected;
  final bool               isDesktop;
  final ValueChanged<bool?> onSelect;

  const NursesFilterBar({
    super.key,
    required this.state,
    required this.selected,
    required this.isDesktop,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 16, vertical: 5),
        children: [
          NurseFilterPill(
            label:    'All  (${state.total})',
            selected: selected == null,
            color:    AppColors.adminColor,
            onTap:    () => onSelect(null),
          ),
          const SizedBox(width: 8),
          NurseFilterPill(
            label:    'Active  (${state.activeCount})',
            selected: selected == true,
            color:    AppColors.success,
            onTap:    () => onSelect(true),
          ),
          const SizedBox(width: 8),
          NurseFilterPill(
            label:    'Inactive  (${state.inactiveCount})',
            selected: selected == false,
            color:    AppColors.error,
            onTap:    () => onSelect(false),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }
}

// ── Count row with optional desktop action buttons ────────────────────────────
class NursesCountRow extends StatelessWidget {
  final int          count;
  final bool         isDesktop;
  final VoidCallback onCategories;
  final VoidCallback onAdd;

  const NursesCountRow({
    super.key,
    required this.count,
    required this.isDesktop,
    required this.onCategories,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 20 : 16, 2, isDesktop ? 20 : 16, 4),
      child: Row(children: [
        Container(
          width: 3, height: 13,
          decoration: BoxDecoration(
            color:        AppColors.adminColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count registered resource${count == 1 ? '' : 's'}',
          style: GoogleFonts.poppins(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (isDesktop) ...[
          _DesktopBtn(
            icon:    Icons.category_outlined,
            label:   'Categories',
            onTap:   onCategories,
            outline: true,
          ),
          const SizedBox(width: 8),
          _DesktopBtn(
            icon:  Icons.person_add_rounded,
            label: 'Add Resource',
            onTap: onAdd,
          ),
        ],
      ]),
    );
  }
}

class _DesktopBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final bool         outline;

  const _DesktopBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:        outline
                ? AppColors.adminColor.withValues(alpha: 0.10)
                : null,
            gradient:     outline ? null : AppColors.adminGradient,
            borderRadius: BorderRadius.circular(20),
            border: outline
                ? Border.all(
                    color: AppColors.adminColor.withValues(alpha: 0.30))
                : null,
            boxShadow: outline
                ? []
                : [BoxShadow(
                    color:      AppColors.adminColor.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset:     const Offset(0, 3),
                  )],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size:  14,
                color: outline ? AppColors.adminColor : Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                  color:      outline ? AppColors.adminColor : Colors.white,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                )),
          ]),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class NursesEmptyState extends StatelessWidget {
  final bool         hasSearch;
  final VoidCallback onAdd;

  const NursesEmptyState({
    super.key,
    required this.hasSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width:  88,
            height: 88,
            decoration: BoxDecoration(
              color:        AppColors.adminColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 44, color: AppColors.adminColor),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No nurses match your search.'
                : 'No nurses registered yet.',
            style: GoogleFonts.poppins(
              fontSize:   15,
              fontWeight: FontWeight.w600,
              color:      AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Nurses will be created by the admin from this screen.',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient:     AppColors.adminGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_add_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Add First Resource',
                      style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      )),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class NursesErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const NursesErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 52, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      ),
    );
  }
}
