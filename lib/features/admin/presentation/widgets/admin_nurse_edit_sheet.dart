import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/resource_categories_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/belgaum_areas.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'admin_nurse_shared.dart';

/// Edit sheet — pre-fills all fields; only sends changed fields (dirty-track).
class AdminNurseEditSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>                   nurse;
  final Future<bool> Function(Map<String, dynamic> fields) onSave;

  const AdminNurseEditSheet({
    super.key,
    required this.nurse,
    required this.onSave,
  });

  @override
  ConsumerState<AdminNurseEditSheet> createState() =>
      _AdminNurseEditSheetState();
}

class _AdminNurseEditSheetState extends ConsumerState<AdminNurseEditSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;

  String? _selectedCategory;
  String? _selectedArea;
  bool    _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final n = widget.nurse;
    _firstNameCtrl = TextEditingController(text: n['first_name'] as String? ?? '');
    _lastNameCtrl  = TextEditingController(text: n['last_name']  as String? ?? '');
    _phoneCtrl     = TextEditingController(text: n['phone']      as String? ?? '');
    _addressCtrl   = TextEditingController(text: n['address']    as String? ?? '');
    _cityCtrl      = TextEditingController(text: n['city']       as String? ?? '');
    _stateCtrl     = TextEditingController(text: n['state']      as String? ?? '');
    _pincodeCtrl   = TextEditingController(text: n['pincode']    as String? ?? '');
    _selectedCategory = n['category'] as String?;
    // Pre-fill area from stored value (exact case-sensitive match from belgaumAreas)
    final storedArea = n['area'] as String? ?? '';
    _selectedArea = belgaumAreas.any((a) => a.name == storedArea)
        ? storedArea
        : null;
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _phoneCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Submit — only send changed fields ───────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final orig   = widget.nurse;
    final fields = <String, dynamic>{};

    void addIfChanged(String key, String ctrlText, String? origVal) {
      final trimmed = ctrlText.trim();
      if (trimmed != (origVal ?? '')) {
        fields[key] = trimmed.isEmpty ? null : trimmed;
      }
    }

    addIfChanged('first_name', _firstNameCtrl.text, orig['first_name'] as String?);
    addIfChanged('last_name',  _lastNameCtrl.text,  orig['last_name']  as String?);
    addIfChanged('phone',      _phoneCtrl.text,     orig['phone']      as String?);
    addIfChanged('address',    _addressCtrl.text,   orig['address']    as String?);
    addIfChanged('city',       _cityCtrl.text,      orig['city']       as String?);
    addIfChanged('state',      _stateCtrl.text,     orig['state']      as String?);
    addIfChanged('pincode',    _pincodeCtrl.text,   orig['pincode']    as String?);

    if (_selectedCategory != (orig['category'] as String?)) {
      fields['category'] = _selectedCategory;
    }

    // Area — compare against original stored value
    final origArea = orig['area'] as String? ?? '';
    final newArea  = _selectedArea ?? '';
    if (newArea != origArea) {
      fields['area'] = _selectedArea;
    }

    if (fields.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final ok = await widget.onSave(fields);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Failed to update resource. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(resourceCategoriesProvider);
    final categoryNames   = categoriesAsync.valueOrNull?.activeNames ?? [];
    final firstName = widget.nurse['first_name'] as String? ?? '';
    final lastName  = widget.nurse['last_name']  as String? ?? '';

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize:     0.5,
        maxChildSize:     0.97,
        expand:           false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SheetHandle(),
              NurseSheetHeader(
                icon:     Icons.edit_rounded,
                title:    'Edit Resource',
                subtitle: '$firstName $lastName',
              ),
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_error != null) ...[
                        NurseSheetErrorBanner(message: _error!),
                        const SizedBox(height: 14),
                      ],

                      // ── Category ─────────────────────────────────────
                      NurseCategoryDropdown(
                        categoryNames:    categoryNames,
                        selectedCategory: _selectedCategory,
                        disabled:         categoryNames.isEmpty,
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                      const SizedBox(height: 16),

                      // ── Name ─────────────────────────────────────────
                      Row(children: [
                        Expanded(child: NurseFormField(
                          label: 'First Name', ctrl: _firstNameCtrl,
                          icon: Icons.badge_outlined,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: NurseFormField(
                          label: 'Last Name', ctrl: _lastNameCtrl,
                          icon: Icons.badge_outlined,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // ── Phone ─────────────────────────────────────────
                      NurseFormField(
                        label: 'Phone (10 digits)', ctrl: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!RegExp(r'^\d{10}$').hasMatch(v.trim()))
                            return '10 digits required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Area dropdown ────────────────────────────────
                      _NurseAreaSection(
                        selectedArea:  _selectedArea,
                        onAreaChanged: (v) => setState(() => _selectedArea = v),
                      ),
                      const SizedBox(height: 10),

                      // ── Address ───────────────────────────────────────
                      NurseFormField(
                        label: 'Address (Street / Building)',
                        ctrl:  _addressCtrl, icon: Icons.home_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // ── City + State ──────────────────────────────────
                      Row(children: [
                        Expanded(child: NurseFormField(
                          label: 'City', ctrl: _cityCtrl,
                          icon: Icons.location_city_outlined,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: NurseFormField(
                          label: 'State (optional)', ctrl: _stateCtrl,
                          icon: Icons.map_outlined,
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // ── Pincode ───────────────────────────────────────
                      NurseFormField(
                        label: 'Pincode (optional)', ctrl: _pincodeCtrl,
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      NurseSheetSubmitButton(
                        label:     'Save Changes',
                        icon:      Icons.save_rounded,
                        isLoading: _isLoading,
                        onTap:     _submit,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Area section — section header + searchable area dropdown (Belgaum areas)
// ─────────────────────────────────────────────────────────────────────────────
class _NurseAreaSection extends StatelessWidget {
  final String?               selectedArea;
  final ValueChanged<String?> onAreaChanged;

  const _NurseAreaSection({
    required this.selectedArea,
    required this.onAreaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header bar
        Row(children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              gradient:     AppColors.adminGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.location_on_outlined,
              size: 15, color: AppColors.adminColor),
          const SizedBox(width: 6),
          Text('Location',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 10),

        // Tappable area selector
        GestureDetector(
          onTap: () => _showAreaSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color:        AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedArea != null
                    ? AppColors.adminColor
                    : AppColors.divider,
                width: selectedArea != null ? 1.5 : 1.0,
              ),
            ),
            child: Row(children: [
              Icon(
                Icons.location_on_outlined,
                size:  18,
                color: selectedArea != null
                    ? AppColors.adminColor
                    : AppColors.textHint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedArea ?? 'Select area / locality',
                  style: GoogleFonts.poppins(
                    fontSize:   13,
                    fontWeight: selectedArea != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color:      selectedArea != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.adminColor, size: 18),
            ]),
          ),
        ),

        // Group label under selected area
        if (selectedArea != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _groupOf(selectedArea!),
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  String _groupOf(String area) =>
      belgaumAreas.where((a) => a.name == area).firstOrNull?.group ?? '';

  void _showAreaSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _NurseAreaPickerSheet(
        selected:   selectedArea,
        onSelected: onAreaChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Searchable area picker bottom-sheet (case-sensitive match)
// ─────────────────────────────────────────────────────────────────────────────
class _NurseAreaPickerSheet extends StatefulWidget {
  final String?              selected;
  final ValueChanged<String> onSelected;

  const _NurseAreaPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_NurseAreaPickerSheet> createState() => _NurseAreaPickerSheetState();
}

class _NurseAreaPickerSheetState extends State<_NurseAreaPickerSheet> {
  String _search = '';
  final  _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BelgaumArea> get _filtered {
    if (_search.isEmpty) return belgaumAreas;
    // Case-sensitive contains match
    return belgaumAreas.where((a) => a.name.contains(_search)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped  = <String, List<BelgaumArea>>{};
    for (final a in filtered) {
      grouped.putIfAbsent(a.group, () => []).add(a);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize:     0.95,
      minChildSize:     0.4,
      expand:           false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Icon(Icons.location_city_rounded,
                    color: AppColors.adminColor, size: 20),
                const SizedBox(width: 8),
                Text('Select Area',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),

            // Search box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged:  (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(
                  hintText:   'Search area (case-sensitive)…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          })
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            const Divider(height: 1),

            // Area list grouped
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 40, color: AppColors.textHint),
                          const SizedBox(height: 8),
                          Text('No areas match "$_search"',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Search is case-sensitive',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    )
                  : ListView(
                      controller: ctrl,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final group in belgaumAreaGroups)
                          if (grouped.containsKey(group)) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Text(
                                group,
                                style: GoogleFonts.poppins(
                                  fontSize:     11,
                                  fontWeight:   FontWeight.w700,
                                  color:        AppColors.adminColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Divider(height: 1, indent: 16),
                            for (final area in grouped[group]!)
                              ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.location_on_rounded,
                                  size:  18,
                                  color: widget.selected == area.name
                                      ? AppColors.adminColor
                                      : AppColors.textHint,
                                ),
                                title: Text(
                                  area.name,
                                  style: GoogleFonts.poppins(
                                    fontSize:   13,
                                    fontWeight: widget.selected == area.name
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: widget.selected == area.name
                                        ? AppColors.adminColor
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: widget.selected == area.name
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: AppColors.adminColor, size: 18)
                                    : null,
                                onTap: () {
                                  widget.onSelected(area.name);
                                  Navigator.pop(context);
                                },
                              ),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
