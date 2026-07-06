import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/pagination_bar.dart';
import 'admin_nurse_shared.dart';

const Map<int, TableColumnWidth> _kColWidths = {
  0: FixedColumnWidth(44),
  1: FlexColumnWidth(2.0),
  2: FlexColumnWidth(2.2),
  3: FlexColumnWidth(1.2),
  4: FlexColumnWidth(1.0),
  5: FlexColumnWidth(0.9),
  6: FlexColumnWidth(0.8),
  7: FlexColumnWidth(1.2),
};

/// Desktop table listing registered resources — fixed header, scrollable rows, pagination.
class AdminNursesTable extends StatelessWidget {
  final List<Map<String, dynamic>> nurses;
  final int  totalNurses;
  final int  currentPage;
  final int  pageSize;
  final bool isLoadingPage;
  final void Function(Map<String, dynamic>) onView;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onToggle;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(int page) onPageChanged;

  const AdminNursesTable({
    super.key,
    required this.nurses,
    required this.totalNurses,
    required this.currentPage,
    required this.pageSize,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onPageChanged,
    this.isLoadingPage = false,
  });

  int get _totalPages => pageSize > 0 ? (totalNurses / pageSize).ceil() : 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Fixed header ──────────────────────────────────────────
            Container(
              color: AppColors.adminColor,
              child: Table(
                columnWidths: _kColWidths,
                children: const [
                  TableRow(children: [
                    _TH(''),
                    _TH('Name'),
                    _TH('Email'),
                    _TH('Phone'),
                    _TH('Area / Location'),
                    _TH('Status'),
                    _TH('Availability'),
                    _TH('Actions'),
                  ]),
                ],
              ),
            ),

            // ── Scrollable rows (fixed height) ────────────────────────
            SizedBox(
              height: 480,
              child: isLoadingPage
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.adminColor))
                  : nurses.isEmpty
                      ? Center(
                          child: Text('No resources found.',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary)))
                      : SingleChildScrollView(
                          child: Column(
                            children: nurses.asMap().entries.map((entry) {
                              final i     = entry.key;
                              final nurse = entry.value;
                              final first = nurse['first_name'] as String? ?? '';
                              final last  = nurse['last_name']  as String? ?? '';
                              return _NurseTableRow(
                                nurse:       nurse,
                                initials: '${first.isNotEmpty ? first[0] : ''}'
                                    '${last.isNotEmpty ? last[0] : ''}'
                                    .toUpperCase(),
                                isActive:    nurse['is_active']    as bool? ?? false,
                                isAvailable: nurse['is_available'] as bool? ?? true,
                                isEven:      i.isEven,
                                onView:   () => onView(nurse),
                                onEdit:   () => onEdit(nurse),
                                onToggle: () => onToggle(nurse),
                                onDelete: () => onDelete(nurse),
                              );
                            }).toList(),
                          ),
                        ),
            ),

            // ── Pagination bar ─────────────────────────────────────────
            PaginationBar(
              currentPage:   currentPage,
              totalPages:    _totalPages,
              totalItems:    totalNurses,
              pageSize:      pageSize,
              isLoading:     isLoadingPage,
              onPageChanged: onPageChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private table widgets ─────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: Text(text,
        style: GoogleFonts.poppins(
          color:         Colors.white,
          fontSize:      11,
          fontWeight:    FontWeight.w700,
          letterSpacing: 0.2,
        )),
  );
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    child: child,
  );
}

class _TableBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _TableBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Three-dot popup menu with View / Edit / Activate|Deactivate / Remove.
class _NurseActionsMenu extends StatelessWidget {
  final bool         isActive;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NurseActionsMenu({
    required this.isActive,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_NurseAction>(
      tooltip: 'Actions',
      icon:    Icon(Icons.more_vert_rounded,
          size: 18, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (action) {
        switch (action) {
          case _NurseAction.view:   onView();   break;
          case _NurseAction.edit:   onEdit();   break;
          case _NurseAction.toggle: onToggle(); break;
          case _NurseAction.delete: onDelete(); break;
        }
      },
      itemBuilder: (_) => [
        _item(_NurseAction.view,
            Icons.visibility_outlined,   'View',
            AppColors.primary),
        _item(_NurseAction.edit,
            Icons.edit_outlined,         'Edit',
            AppColors.adminColor),
        _item(
          _NurseAction.toggle,
          isActive ? Icons.toggle_off_rounded : Icons.toggle_on_rounded,
          isActive ? 'Deactivate' : 'Activate',
          isActive ? AppColors.warning : AppColors.success,
        ),
        const PopupMenuDivider(),
        _item(_NurseAction.delete,
            Icons.delete_outline_rounded, 'Remove',
            AppColors.error),
      ],
    );
  }

  PopupMenuItem<_NurseAction> _item(
      _NurseAction value, IconData icon, String label, Color color) {
    return PopupMenuItem<_NurseAction>(
      value: value,
      child: Row(children: [
        Container(
          width:  28,
          height: 28,
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.poppins(
              fontSize:   13,
              fontWeight: FontWeight.w500,
              color: value == _NurseAction.delete
                  ? AppColors.error
                  : AppColors.textPrimary,
            )),
      ]),
    );
  }
}

enum _NurseAction { view, edit, toggle, delete }

class _NurseTableRow extends StatefulWidget {
  final Map<String, dynamic> nurse;
  final String   initials;
  final bool     isActive;
  final bool     isAvailable;
  final bool     isEven;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NurseTableRow({
    required this.nurse,
    required this.initials,
    required this.isActive,
    required this.isAvailable,
    required this.isEven,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_NurseTableRow> createState() => _NurseTableRowState();
}

class _NurseTableRowState extends State<_NurseTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final nurse      = widget.nurse;
    final first      = nurse['first_name'] as String? ?? '';
    final last       = nurse['last_name']  as String? ?? '';
    final email      = nurse['email']      as String? ?? '—';
    final phone      = nurse['phone']      as String? ?? '—';
    final area       = (nurse['area'] as String?)?.isNotEmpty == true
        ? nurse['area'] as String
        : null;
    final city       = nurse['city']    as String? ?? '';
    final address    = nurse['address'] as String? ?? '';
    final areaLabel  = area ?? (city.isNotEmpty ? city : '—');

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? AppColors.adminColor.withValues(alpha: 0.04)
              : (widget.isEven ? Colors.white : const Color(0xFFFAFAFB)),
          child: Table(
            columnWidths: _kColWidths,
            children: [
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: NurseAvatar(
                    initials: widget.initials,
                    size: 28, fontSize: 10, borderRadius: 8,
                  ),
                ),
                _TD(child: Text('$first $last',
                    style: GoogleFonts.poppins(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      AppColors.textPrimary,
                    ))),
                _TD(child: Text(email,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis)),
                _TD(child: Text(phone.isNotEmpty ? phone : '—',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary))),
                _TD(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (address.isNotEmpty)
                        Text(address,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 10, color: AppColors.adminColor),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(areaLabel,
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.adminColor,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  )),
                _TD(child: _TableBadge(
                  label: widget.isActive ? 'Active' : 'Inactive',
                  color: widget.isActive ? AppColors.success : AppColors.error,
                )),
                _TD(child: _TableBadge(
                  label: widget.isAvailable ? 'Available' : 'Busy',
                  color: widget.isAvailable
                      ? const Color(0xFF00897B)
                      : AppColors.warning,
                )),
                _TD(child: _NurseActionsMenu(
                  isActive:    widget.isActive,
                  onView:      widget.onView,
                  onEdit:      widget.onEdit,
                  onToggle:    widget.onToggle,
                  onDelete:    widget.onDelete,
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
