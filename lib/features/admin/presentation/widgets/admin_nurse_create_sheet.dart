import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/resource_categories_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/belgaum_areas.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'admin_nurse_shared.dart';

typedef CreateNurseCallback = Future<bool> Function({
  required String firstName,
  required String lastName,
  required String email,
  required String phone,
  required String address,
  String? area,
  required String city,
  String? nurseState,
  String? pincode,
  String? category,
  required String password,
});

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet for creating a new resource (nurse) account.
// Includes live geolocation auto-fill: Address / Area / City / State / Pincode.
// ─────────────────────────────────────────────────────────────────────────────
class AdminNurseCreateSheet extends ConsumerStatefulWidget {
  final CreateNurseCallback onSubmit;
  const AdminNurseCreateSheet({super.key, required this.onSubmit});

  @override
  ConsumerState<AdminNurseCreateSheet> createState() =>
      _AdminNurseCreateSheetState();
}

class _AdminNurseCreateSheetState
    extends ConsumerState<AdminNurseCreateSheet> {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _cityCtrl      = TextEditingController();
  final _stateCtrl     = TextEditingController();
  final _pincodeCtrl   = TextEditingController();
  final _passCtrl      = TextEditingController();

  bool    _obscure          = true;
  bool    _isLoading        = false;
  String? _error;
  String? _selectedCategory;
  String? _selectedArea;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl, _passCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final ok = await widget.onSubmit(
      firstName:  _firstNameCtrl.text.trim(),
      lastName:   _lastNameCtrl.text.trim(),
      email:      _emailCtrl.text.trim(),
      phone:      _phoneCtrl.text.trim(),
      address:    _addressCtrl.text.trim(),
      area:       _selectedArea,
      city:       _cityCtrl.text.trim(),
      nurseState: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      pincode:    _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      category:   _selectedCategory,
      password:   _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Failed to create resource. Check the details and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(resourceCategoriesProvider);
    final categoryNames   = categoriesAsync.valueOrNull?.activeNames ?? [];

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
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
                icon:     Icons.person_add_rounded,
                title:    'Add Resource Account',
                subtitle: 'Creates a pre-verified resource account',
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
                      _CategorySection(
                        categoriesAsync: categoriesAsync,
                        categoryNames:   categoryNames,
                        selected:        _selectedCategory,
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

                      // ── Email ─────────────────────────────────────────
                      NurseFormField(
                        label: 'Email', ctrl: _emailCtrl,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
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

                      // ── Location header + geo button ──────────────────
                      _NurseAreaSection(
                        label:        'Location',
                        selectedArea: _selectedArea,
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
                      const SizedBox(height: 16),

                      // ── Password ──────────────────────────────────────
                      NurseFormField(
                        label: 'Password', ctrl: _passCtrl,
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 8) return 'Min 8 characters';
                          if (!v.contains(RegExp(r'[A-Z]')))
                            return 'Add an uppercase letter';
                          if (!v.contains(RegExp(r'\d')))
                            return 'Add a digit';
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary, size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Min 8 chars · 1 uppercase · 1 digit',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: AppColors.textHint),
                        ),
                      ),
                      const SizedBox(height: 24),

                      NurseSheetSubmitButton(
                        label:     'Create Resource Account',
                        icon:      Icons.person_add_rounded,
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
  final String          label;
  final String?         selectedArea;
  final ValueChanged<String?> onAreaChanged;

  const _NurseAreaSection({
    required this.label,
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
          Text(label,
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
        selected:     selectedArea,
        onSelected:   (area) => onAreaChanged(area),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Searchable area picker bottom-sheet (case-sensitive match)
// ─────────────────────────────────────────────────────────────────────────────
class _NurseAreaPickerSheet extends StatefulWidget {
  final String?         selected;
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
    return belgaumAreas
        .where((a) => a.name.contains(_search))
        .toList();
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

            // Area list
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

// ─────────────────────────────────────────────────────────────────────────────
// Category section (loading / dropdown + no-categories warning)
// ─────────────────────────────────────────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  final AsyncValue<dynamic> categoriesAsync;
  final List<String>        categoryNames;
  final String?             selected;
  final void Function(String?) onChanged;

  const _CategorySection({
    required this.categoriesAsync,
    required this.categoryNames,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resource Category',
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        categoriesAsync.when(
          loading: () => Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.adminColor),
              ),
            ),
          ),
          error: (_, __) => NurseCategoryDropdown(
            categoryNames: categoryNames, selectedCategory: selected,
            disabled: true, onChanged: onChanged,
          ),
          data: (_) => NurseCategoryDropdown(
            categoryNames: categoryNames, selectedCategory: selected,
            onChanged: onChanged,
          ),
        ),
        if (categoryNames.isEmpty && categoriesAsync.hasValue) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:        AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No categories yet. Go to Resources tab to create one first.',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.warning),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
