import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/service_model.dart';
import '../../../../core/constants/app_colors.dart';

/// Desktop table view for the Admin Services tab.
/// Pagination footer is embedded inside the same card so the FAB never overlaps it.
class AdminServicesTable extends StatelessWidget {
  final List<ServiceModel> services;
  final void Function(ServiceModel) onEdit;
  final void Function(ServiceModel) onToggle;
  final void Function(ServiceModel) onDelete;

  // Pagination
  final int  currentPage;
  final int  totalPages;
  final int  total;
  final int  pageSize;
  final bool isLoading;
  final void Function(int) onPageChanged;

  const AdminServicesTable({
    super.key,
    required this.services,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.isLoading,
    required this.onPageChanged,
  });

  static const _colWidths = {
    0: FlexColumnWidth(2.2),
    1: FlexColumnWidth(1.2),
    2: FlexColumnWidth(2.5),
    3: FlexColumnWidth(1.0),
    4: FlexColumnWidth(0.8),
    5: FlexColumnWidth(1.0),
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 90),
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Data table ────────────────────────────────────────────────
              Table(
                columnWidths: _colWidths,
                children: [
                  // Header
                  const TableRow(
                    decoration: BoxDecoration(color: AppColors.adminColor),
                    children: [
                      _TH('Service Name'),
                      _TH('Category'),
                      _TH('Description'),
                      _TH('Price'),
                      _TH('Status'),
                      _TH('Actions'),
                    ],
                  ),
                  // Data rows
                  ...services.asMap().entries.map((entry) {
                    final i   = entry.key;
                    final svc = entry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.white : const Color(0xFFFAFAFB),
                      ),
                      children: [
                        _TD(child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color:        AppColors.adminColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.medical_services_outlined,
                                color: AppColors.adminColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(svc.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ])),
                        _TD(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:        AppColors.adminColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(svc.category,
                              style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.adminColor)),
                        )),
                        _TD(child: Text(svc.description,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                        _TD(child: Text(
                          svc.price != null
                              ? '₹${svc.price!.toStringAsFixed(2)}/day'
                              : '—',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: svc.price != null
                                ? FontWeight.w600 : FontWeight.w400,
                            color: svc.price != null
                                ? AppColors.success : AppColors.textHint),
                        )),
                        _TD(child: _StatusBadge(isActive: svc.isActive)),
                        _TD(child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TableAction(
                              icon: Icons.edit_outlined,
                              color: AppColors.adminColor,
                              tooltip: 'Edit',
                              onTap: () => onEdit(svc),
                            ),
                            const SizedBox(width: 4),
                            _TableAction(
                              icon: svc.isActive
                                  ? Icons.toggle_off_outlined
                                  : Icons.toggle_on_outlined,
                              color: svc.isActive
                                  ? AppColors.warning : AppColors.success,
                              tooltip: svc.isActive ? 'Deactivate' : 'Activate',
                              onTap: () => onToggle(svc),
                            ),
                            const SizedBox(width: 4),
                            _TableAction(
                              icon: Icons.delete_outline,
                              color: AppColors.error,
                              tooltip: 'Delete',
                              onTap: () => onDelete(svc),
                            ),
                          ],
                        )),
                      ],
                    );
                  }),
                ],
              ),

              // ── Pagination footer — inside the card ───────────────────────
              if (totalPages > 1) ...[
                const Divider(height: 1, color: AppColors.divider),
                _TablePagination(
                  currentPage:   currentPage,
                  totalPages:    totalPages,
                  total:         total,
                  pageSize:      pageSize,
                  isLoading:     isLoading,
                  onPageChanged: onPageChanged,
                ),
              ] else ...[
                // Just show the record count when no pagination needed
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: AppColors.divider))),
                  child: Text(
                    'Showing all $total service${total == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pagination footer widget ──────────────────────────────────────────────────
class _TablePagination extends StatelessWidget {
  final int  currentPage;
  final int  totalPages;
  final int  total;
  final int  pageSize;
  final bool isLoading;
  final void Function(int) onPageChanged;

  const _TablePagination({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.isLoading,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = ((currentPage - 1) * pageSize) + 1;
    final end   = (currentPage * pageSize).clamp(1, total);

    // Page number slots with ellipsis — max 7 slots
    final slots = <int?>[];
    if (totalPages <= 7) {
      slots.addAll(List.generate(totalPages, (i) => i + 1));
    } else {
      slots.add(1);
      if (currentPage > 3) slots.add(null);
      for (int p = (currentPage - 1).clamp(2, totalPages - 1);
           p <= (currentPage + 1).clamp(2, totalPages - 1);
           p++) {
        slots.add(p);
      }
      if (currentPage < totalPages - 2) slots.add(null);
      slots.add(totalPages);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        // Record count
        Text(
          'Showing $start–$end of $total',
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        // Prev
        _Btn(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1 && !isLoading,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 4),
        // Page slots
        ...slots.map((p) {
          if (p == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('…',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textHint)),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _Btn(
              label:    '$p',
              selected: p == currentPage,
              enabled:  p != currentPage && !isLoading,
              onTap:    () => onPageChanged(p),
            ),
          );
        }),
        const SizedBox(width: 4),
        // Next
        _Btn(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages && !isLoading,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final String?      label;
  final IconData?    icon;
  final bool         selected;
  final bool         enabled;
  final VoidCallback onTap;

  const _Btn({
    this.label,
    this.icon,
    this.selected = false,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.adminColor
                : enabled
                    ? Colors.white
                    : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.adminColor
                  : AppColors.divider,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 17,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textHint)
                : Text(label ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : enabled
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                    )),
          ),
        ),
      ),
    );
  }
}

// ── Private table helpers ─────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Text(text, style: GoogleFonts.poppins(
        color: Colors.white, fontSize: 12,
        fontWeight: FontWeight.w700, letterSpacing: 0.3)),
  );
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: child,
  );
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});
  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(isActive ? 'Active' : 'Inactive',
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _TableAction extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;
  const _TableAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    ),
  );
}
