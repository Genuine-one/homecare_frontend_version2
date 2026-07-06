import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/resource_categories_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/belgaum_areas.dart';
import '../../../../core/network/api_service.dart';
import '../../../../shared/widgets/sheet_handle.dart';

class AdminAssignNurseSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> nurses; // kept for API compat
  final Future<String?> Function(List<String> nurseIds, String? notes,
      Map<String, String> shiftAssignmentMap) onAssign;

  const AdminAssignNurseSheet({
    super.key,
    required this.request,
    required this.nurses,
    required this.onAssign,
  });

  @override
  ConsumerState<AdminAssignNurseSheet> createState() =>
      _AdminAssignNurseSheetState();
}

class _AdminAssignNurseSheetState
    extends ConsumerState<AdminAssignNurseSheet> {
  final Set<String>  _selectedIds      = {};
  String?            _selectedCategory;
  final              _notesCtrl        = TextEditingController();
  bool               _isLoading        = false;
  bool               _isFetching       = true;
  String?            _error;
  List<Map<String, dynamic>> _allNurses = [];

  /// Area name extracted from the service request address (e.g. "Subhash Nagar").
  String? _requestArea;
  /// When true, only resources from the request's area are shown.
  /// Default is FALSE — show all resources; admin can click to filter by area.
  bool    _locationFilterEnabled = false;

  /// resource_id -> that resource's shift-roster assignments on the request's date.
  /// Lets the admin see who's actually on shift before assigning the job.
  Map<String, List<Map<String, dynamic>>> _shiftsByResource = {};
  bool _shiftsOnlyFilter = false;

  /// resource_id -> the ResourceShiftAssignment id the admin picked for that
  /// resource. This is what ties the resulting job to a specific shift.
  final Map<String, String> _selectedShiftByResource = {};

  @override
  void initState() {
    super.initState();
    _requestArea = _extractAreaFromRequest();
    _fetchNurses();
    _fetchShiftsForRequestDate();
  }

  /// Loads every shift-roster assignment on the request's preferred date (one
  /// call for all resources) so each resource tile can show its shift, if any.
  Future<void> _fetchShiftsForRequestDate() async {
    final rawDate = widget.request['preferred_date'];
    if (rawDate == null) return;
    final dateStr = rawDate.toString().split('T').first;
    try {
      final resp = await ApiService.instance.get(
        ApiConstants.adminShifts,
        queryParams: {'date': dateStr, 'limit': 1000},
      );
      final list = List<Map<String, dynamic>>.from(resp['assignments'] ?? []);
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final a in list) {
        final rid = a['resource_id'] as String?;
        if (rid == null) continue;
        grouped.putIfAbsent(rid, () => []).add(a);
      }
      if (mounted) setState(() => _shiftsByResource = grouped);
    } catch (_) {
      // Non-critical — the sheet still works without shift info.
    }
  }

  /// Extracts the area name for location-based resource filtering.
  /// Checks the `location` field first (stored as plain area name since GPS is
  /// now resolved before saving), then falls back to scanning the `address` string.
  String? _extractAreaFromRequest() {
    final location = (widget.request['location'] as String? ?? '').trim();
    // Check if `location` is already a known area name (exact match, case-insensitive)
    if (location.isNotEmpty) {
      final match = belgaumAreas.where(
        (a) => a.name.toLowerCase() == location.toLowerCase(),
      );
      if (match.isNotEmpty) return match.first.name;
    }
    // Fallback: scan the full address string for any known area name
    final addr = (widget.request['address'] as String? ?? '').toLowerCase();
    for (final area in belgaumAreas) {
      if (addr.contains(area.name.toLowerCase())) return area.name;
    }
    return null;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Fetch ALL nurses (no server-side filter) then filter locally.
  /// This avoids the Beanie bug where missing `is_available` fields
  /// don't match `is_available == True`.
  Future<void> _fetchNurses() async {
    setState(() { _isFetching = true; _error = null; });
    try {
      final resp = await ApiService.instance.get(
        ApiConstants.adminNurses,
        queryParams: {'limit': 100},
      );
      final list = List<Map<String, dynamic>>.from(resp['nurses'] ?? []);
      if (mounted) {
        setState(() {
          // Keep only active nurses where is_available is not explicitly false
          _allNurses  = list.where((n) =>
              (n['is_active']    as bool? ?? false) == true &&
              (n['is_available'] as bool? ?? true)  != false,
          ).toList();
          _isFetching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _error = 'Failed to load resources. Please try again.';
        });
      }
    }
  }

  /// Nurses filtered to the request's area (or all nurses if filter is off / no area match).
  List<Map<String, dynamic>> get _locationBase {
    if (!_locationFilterEnabled || _requestArea == null) return _allNurses;
    return _allNurses.where((n) {
      return (n['area'] as String? ?? '').toLowerCase().trim() ==
          _requestArea!.toLowerCase().trim();
    }).toList();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _locationBase;
    if (_selectedCategory != null) {
      list = list.where((n) => (n['category'] as String?) == _selectedCategory).toList();
    }
    if (_shiftsOnlyFilter) {
      list = list.where((n) => _shiftsByResource.containsKey(n['id'] as String)).toList();
    }
    if (_shiftsByResource.isNotEmpty) {
      list = [...list]..sort((a, b) {
        final aHas = _shiftsByResource.containsKey(a['id'] as String) ? 0 : 1;
        final bHas = _shiftsByResource.containsKey(b['id'] as String) ? 0 : 1;
        return aHas.compareTo(bHas);
      });
    }
    return list;
  }

  int get _onShiftCount =>
      _locationBase.where((n) => _shiftsByResource.containsKey(n['id'] as String)).length;

  /// Toggles which shift a resource's job is tied to. Tapping the same shift
  /// again clears the selection.
  void _selectShift(String resourceId, String shiftAssignmentId) {
    setState(() {
      if (_selectedShiftByResource[resourceId] == shiftAssignmentId) {
        _selectedShiftByResource.remove(resourceId);
      } else {
        _selectedShiftByResource[resourceId] = shiftAssignmentId;
      }
    });
  }

  /// When a resource is checked and has exactly one shift that day, pick it
  /// automatically so the admin doesn't have to tap it manually.
  void _autoSelectShiftIfSingle(String resourceId) {
    final shifts = _shiftsByResource[resourceId];
    if (shifts != null && shifts.length == 1) {
      _selectedShiftByResource[resourceId] = shifts.first['id'] as String;
    }
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) return;
    setState(() { _isLoading = true; _error = null; });

    final shiftMap = <String, String>{
      for (final id in _selectedIds)
        if (_selectedShiftByResource[id] != null) id: _selectedShiftByResource[id]!,
    };

    final err = await widget.onAssign(
      _selectedIds.toList(),
      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      shiftMap,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames =
        ref.watch(resourceCategoriesProvider).valueOrNull?.activeNames ?? [];
    final all      = _locationBase;   // category counts use location-filtered base
    final filtered = _filtered;
    final canSubmit = _selectedIds.isNotEmpty && !_isLoading && !_isFetching;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),

            // ── Header ──────────────────────────────────────────────────────
            Row(children: [
              Container(
                padding:    const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient:     AppColors.adminGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_ind_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assign Resource',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      '${_serviceLabel(widget.request['service_type'] as String? ?? '')}  •  ${widget.request['city'] ?? ''}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        AppColors.adminColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedIds.length} selected',
                    style: GoogleFonts.poppins(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      color:      AppColors.adminColor,
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 12),

            // ── Area filter row ──────────────────────────────────────────────
            if (_requestArea != null)
              _AreaFilterRow(
                area:    _requestArea!,
                enabled: _locationFilterEnabled,
                areaCount: _locationFilterEnabled
                    ? _locationBase.length
                    : _allNurses.where((n) =>
                        (n['area'] as String? ?? '').toLowerCase().trim() ==
                        _requestArea!.toLowerCase().trim()).length,
                allCount: _allNurses.length,
                onToggle: () => setState(() {
                  _locationFilterEnabled = !_locationFilterEnabled;
                  _selectedCategory = null;
                }),
              ),
            const SizedBox(height: 12),

            // ── On-shift filter row ───────────────────────────────────────────
            if (_shiftsByResource.isNotEmpty) ...[
              Row(children: [
                _FilterPill(
                  label: 'All Resources (${_locationBase.length})',
                  selected: !_shiftsOnlyFilter,
                  color: AppColors.textSecondary,
                  onTap: _shiftsOnlyFilter ? () => setState(() => _shiftsOnlyFilter = false) : null,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'On Shift This Day ($_onShiftCount)',
                  selected: _shiftsOnlyFilter,
                  color: AppColors.info,
                  icon: Icons.schedule_rounded,
                  onTap: _shiftsOnlyFilter ? null : () => setState(() => _shiftsOnlyFilter = true),
                ),
              ]),
              const SizedBox(height: 12),
            ],

            // ── Category filter chips ────────────────────────────────────────
            if (categoryNames.isNotEmpty) ...[
              Text('Filter by Category',
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label:    'All  (${all.length})',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() {
                        _selectedCategory = null;
                      }),
                    ),
                    ...categoryNames.map((cat) {
                      final count = all
                          .where((n) => (n['category'] as String?) == cat)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _CategoryChip(
                          label:    '$cat  ($count)',
                          selected: _selectedCategory == cat,
                          onTap: () => setState(() {
                            _selectedCategory = cat;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Error banner ─────────────────────────────────────────────────
            if (_error != null) ...[
              _ErrorRow(message: _error!, onRetry: _fetchNurses),
              const SizedBox(height: 12),
            ],

            // ── Resource list ────────────────────────────────────────────────
            if (_isFetching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.adminColor),
                ),
              )
            else if (filtered.isEmpty)
              _EmptyResources(
                allEmpty:        _allNurses.isEmpty,
                category:        _selectedCategory,
                locationArea:    (_locationFilterEnabled && _requestArea != null) ? _requestArea : null,
                locationFiltered: _locationFilterEnabled && _requestArea != null && _locationBase.isEmpty,
                onShowAll: () => setState(() {
                  _locationFilterEnabled = false;
                  _selectedCategory = null;
                }),
              )
            else ...[
              // Select-all row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${filtered.length} resource${filtered.length == 1 ? '' : 's'} available',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => setState(() {
                      if (_selectedIds.containsAll(
                          filtered.map((n) => n['id'] as String))) {
                        _selectedIds.removeAll(
                            filtered.map((n) => n['id'] as String));
                      } else {
                        for (final n in filtered) {
                          final id = n['id'] as String;
                          _selectedIds.add(id);
                          _autoSelectShiftIfSingle(id);
                        }
                      }
                    }),
                    child: Text(
                      _selectedIds.containsAll(
                              filtered.map((n) => n['id'] as String))
                          ? 'Deselect All'
                          : 'Select All',
                      style: GoogleFonts.poppins(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.adminColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final nurse     = filtered[i];
                    final id        = nurse['id'] as String;
                    final isChecked = _selectedIds.contains(id);
                    return _ResourceCheckTile(
                      nurse:      nurse,
                      isChecked:  isChecked,
                      shifts:     _shiftsByResource[id] ?? const [],
                      selectedShiftId: _selectedShiftByResource[id],
                      onShiftTap: (shiftAssignmentId) => _selectShift(id, shiftAssignmentId),
                      onChanged:  (v) => setState(() {
                        if (v == true) {
                          _selectedIds.add(id);
                          _autoSelectShiftIfSingle(id);
                        } else {
                          _selectedIds.remove(id);
                        }
                      }),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),

            // ── Notes ────────────────────────────────────────────────────────
            TextField(
              controller: _notesCtrl,
              maxLines:   2,
              style:      GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText:  'Admin notes (optional)',
                hintText:   'Any special instructions…',
                labelStyle: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // ── Submit ───────────────────────────────────────────────────────
            _SubmitButton(
              canSubmit:     canSubmit,
              isLoading:     _isLoading,
              selectedCount: _selectedIds.length,
              onTap:         _submit,
            ),
          ],
        ),
      ),
    );
  }
}

String _serviceLabel(String raw) {
  if (raw.isEmpty) return 'Service';
  return raw
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.adminColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.adminColor : AppColors.divider),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:      AppColors.adminColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset:     const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}

class _ResourceCheckTile extends StatelessWidget {
  final Map<String, dynamic> nurse;
  final bool     isChecked;
  final List<Map<String, dynamic>> shifts;
  final String?  selectedShiftId;
  final ValueChanged<String>? onShiftTap;
  final ValueChanged<bool?> onChanged;

  const _ResourceCheckTile({
    required this.nurse,
    required this.isChecked,
    required this.onChanged,
    this.shifts = const [],
    this.selectedShiftId,
    this.onShiftTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = nurse['first_name'] as String? ?? '';
    final lastName  = nurse['last_name']  as String? ?? '';
    final category  = nurse['category']   as String?;
    // Show area if available, fall back to city
    final areaOrCity = ((nurse['area'] as String?)?.isNotEmpty == true
        ? nurse['area'] as String
        : nurse['city'] as String? ?? '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isChecked
            ? AppColors.adminColor.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked
              ? AppColors.adminColor.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: CheckboxListTile(
        dense:           true,
        shape:           RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        value:           isChecked,
        onChanged:       onChanged,
        activeColor:     AppColors.adminColor,
        checkColor:      Colors.white,
        secondary: CircleAvatar(
          radius:          18,
          backgroundColor: AppColors.nurseColor.withValues(alpha: 0.15),
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: const TextStyle(
              color:      AppColors.nurseColor,
              fontWeight: FontWeight.bold,
              fontSize:   14,
            ),
          ),
        ),
        title: Text(
          '$firstName $lastName',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                if (category != null) ...[
                  const Icon(Icons.category_outlined,
                      size: 10, color: AppColors.adminColor),
                  const SizedBox(width: 3),
                  Text(category,
                      style: GoogleFonts.poppins(
                        fontSize:   10,
                        color:      AppColors.adminColor,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(areaOrCity,
                      style: GoogleFonts.poppins(fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _ShiftBadge(
              shifts: shifts,
              selectedShiftId: selectedShiftId,
              onShiftTap: onShiftTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the resource's shift(s) on the request's date — tap one to tell the
/// admin which shift this job should be linked to. Helps assign to whoever's
/// actually on duty, and the selection carries through to the created job so
/// future attendance / vitals flows can reference the same shift.
class _ShiftBadge extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;
  final String? selectedShiftId;
  final ValueChanged<String>? onShiftTap;
  const _ShiftBadge({required this.shifts, this.selectedShiftId, this.onShiftTap});

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.textHint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.event_busy_rounded, size: 10, color: AppColors.textHint),
          const SizedBox(width: 3),
          Text('No shift scheduled',
              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textHint)),
        ]),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: shifts.map((s) {
        final shiftId = s['id'] as String;
        final selected = shiftId == selectedShiftId;
        final label = '${s['shift_name'] ?? ''} ${s['start_time'] ?? ''}–${s['end_time'] ?? ''}';
        return GestureDetector(
          onTap: onShiftTap == null ? null : () => onShiftTap!(shiftId),
          child: MouseRegion(
            cursor: onShiftTap == null ? MouseCursor.defer : SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? AppColors.info : AppColors.info.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppColors.info : AppColors.info.withValues(alpha: 0.30)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(selected ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    size: 10, color: selected ? Colors.white : AppColors.info),
                const SizedBox(width: 3),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 9, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.info)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AreaFilterRow extends StatelessWidget {
  final String       area;
  final bool         enabled;
  final int          areaCount;
  final int          allCount;
  final VoidCallback onToggle;

  const _AreaFilterRow({
    required this.area,
    required this.enabled,
    required this.areaCount,
    required this.allCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // "All resources" pill
        _FilterPill(
          label:    'All Resources ($allCount)',
          selected: !enabled,
          color:    AppColors.textSecondary,
          onTap:    enabled ? onToggle : null,
        ),
        const SizedBox(width: 8),
        // Area-specific pill
        _FilterPill(
          label:    '$area ($areaCount)',
          selected: enabled,
          color:    AppColors.adminColor,
          icon:     Icons.location_on_rounded,
          onTap:    enabled ? null : onToggle,
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final IconData?    icon;
  final VoidCallback? onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.50)
                : AppColors.divider,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color:      color.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset:     const Offset(0, 2),
                )]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11,
                  color: selected ? color : AppColors.textHint),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize:   11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:      selected ? color : AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _EmptyResources extends StatelessWidget {
  final bool         allEmpty;
  final String?      category;
  final String?      locationArea;
  final bool         locationFiltered;
  final VoidCallback? onShowAll;
  const _EmptyResources({
    required this.allEmpty,
    this.category,
    this.locationArea,
    this.locationFiltered = false,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final String message;
    if (allEmpty) {
      message = 'No available resources.\nResources must mark themselves as Available.';
    } else if (locationFiltered) {
      message = 'No resources found in "$locationArea".';
    } else {
      message = 'No resources in the "$category" category.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              allEmpty ? Icons.person_off_outlined : Icons.search_off_rounded,
              size: 36, color: AppColors.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (locationFiltered && onShowAll != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onShowAll,
                icon: const Icon(Icons.public_outlined, size: 14),
                label: Text('Show all available resources',
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.adminColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.error, fontSize: 13))),
          GestureDetector(
            onTap: onRetry,
            child: const Icon(Icons.refresh, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool         canSubmit;
  final bool         isLoading;
  final int          selectedCount;
  final VoidCallback onTap;
  const _SubmitButton({
    required this.canSubmit,
    required this.isLoading,
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = selectedCount > 1
        ? 'Confirm Assignment ($selectedCount Resources)'
        : 'Confirm Assignment';

    return Container(
      height:     52,
      decoration: BoxDecoration(
        gradient:     canSubmit ? AppColors.adminGradient : null,
        color:        canSubmit ? null : AppColors.textHint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap:        canSubmit ? onTap : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(label,
                    style: GoogleFonts.poppins(
                      color:      Colors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                    )),
          ),
        ),
      ),
    );
  }
}
