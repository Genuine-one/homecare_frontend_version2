// KLE HOMECARE — New Service Request Screen
// Layout order: Patient Name | Contact + Alt Contact | Service Types (multi-select)
// | Area | Address | Service Dates | Preferred Time | Urgency | Special Notes | Pincode | City | State
// Inline live validation + red asterisks on required fields.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/patient_provider.dart';
import '../providers/catalogue_provider.dart';
import '../providers/patient_profile_provider.dart';
import '../widgets/date_range_picker_dialog.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/belgaum_areas.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/kle_app_bar.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class RequestServiceScreen extends ConsumerStatefulWidget {
  const RequestServiceScreen({super.key});
  @override
  ConsumerState<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends ConsumerState<RequestServiceScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _patientNameCtrl    = TextEditingController();
  final _contactCtrl        = TextEditingController();
  final _altContactCtrl     = TextEditingController();
  final _addressCtrl        = TextEditingController();
  final _pincodeCtrl        = TextEditingController();
  final _notesCtrl          = TextEditingController();

  // Multi-service selection
  final Set<String> _selectedServiceIds = {};

  String    _urgencyLevel  = 'routine';
  String?   _preferredTime;
  DateTime? _startDate;
  DateTime? _endDate;
  bool      _isSubmitting  = false;
  String?   _selectedArea;

  // Track which fields have been touched for live validation
  bool _nameTouched        = false;
  bool _contactTouched     = false;
  bool _altContactTouched  = false;
  bool _addressTouched     = false;
  bool _pincodeTouched     = false;
  bool _servicesTouched    = false;
  bool _areaTouched        = false;
  bool _dateTouched        = false;

  int get _numDays {
    if (_startDate == null || _endDate == null) return 0;
    final d = _endDate!.difference(_startDate!).inDays + 1;
    return d < 1 ? 1 : d;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(catalogueProvider);
      _prefillFromProfile();
    });
  }

  Future<void> _prefillFromProfile() async {
    final authUser = ref.read(authProvider).valueOrNull?.user;
    if (authUser != null && _patientNameCtrl.text.isEmpty) {
      _patientNameCtrl.text = authUser.fullName;
    }
    PatientProfile? profile;
    try {
      profile = await ref.read(patientProfileProvider.future);
    } catch (_) { return; }
    if (!mounted || profile == null) return;
    setState(() {
      if (profile!.fullName.trim().isNotEmpty) _patientNameCtrl.text = profile.fullName.trim();
      if ((profile.phone    ?? '').isNotEmpty) _contactCtrl.text     = profile.phone!.trim();
      if ((profile.address  ?? '').isNotEmpty) _addressCtrl.text     = profile.address!.trim();
      if ((profile.pincode  ?? '').isNotEmpty) _pincodeCtrl.text     = profile.pincode!.trim();
      if ((profile.area     ?? '').isNotEmpty) {
        final raw = profile.area!.trim();
        final match = belgaumAreas
            .where((a) => a.name.toLowerCase() == raw.toLowerCase())
            .firstOrNull;
        _selectedArea = match?.name ?? raw;
      }
    });
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose(); _contactCtrl.dispose(); _altContactCtrl.dispose();
    _addressCtrl.dispose(); _pincodeCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final result = await showDialog<DateTimeRange>(
      context: context, barrierDismissible: true,
      builder: (ctx) => KleDateRangePickerDialog(initialStart: _startDate, initialEnd: _endDate),
    );
    if (result != null) {
      setState(() { _startDate = result.start; _endDate = result.end; _dateTouched = true; });
    }
  }

  Future<void> _submit(List<CatalogueService> allServices) async {
    setState(() { _servicesTouched = true; _areaTouched = true; _dateTouched = true;
      _nameTouched = true; _contactTouched = true; _addressTouched = true; });
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceIds.isEmpty) { _showSnack('Please select at least one service', isError: true); return; }
    if (_startDate == null || _endDate == null) { _showSnack('Please select service dates', isError: true); return; }
    if (_selectedArea == null) { _showSnack('Please select your area', isError: true); return; }

    // Build comma-joined service_type string from selected names
    final selectedNames = allServices
        .where((s) => _selectedServiceIds.contains(s.id))
        .map((s) => s.name)
        .join(', ');

    setState(() => _isSubmitting = true);
    final ok = await ref.read(patientRequestsProvider.notifier).createRequest({
      'patient_name':       _patientNameCtrl.text.trim(),
      'contact_number':     _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      'alternative_contact':_altContactCtrl.text.trim().isEmpty ? null : _altContactCtrl.text.trim(),
      'service_type':       selectedNames,
      'address':            _addressCtrl.text.trim(),
      'city':               'Belgaum',
      'state':              'Karnataka',
      'pincode':            _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      'preferred_date':     DateFormat('yyyy-MM-dd').format(_startDate!),
      'start_date':         DateFormat('yyyy-MM-dd').format(_startDate!),
      'end_date':           DateFormat('yyyy-MM-dd').format(_endDate!),
      'num_days':           _numDays,
      'preferred_time':     _preferredTime,
      'urgency_level':      _urgencyLevel,
      'special_notes':      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      if (_selectedArea != null) 'location': _selectedArea,
    });
    setState(() => _isSubmitting = false);
    if (ok && mounted) { _showSnack('Service request submitted successfully!'); context.go('/patient'); }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  /// Label with red asterisk for required fields
  Widget _label(String text, {bool required = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF616161)),
        children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE53935))),
        ],
      ),
    ),
  );

  InputDecoration _dec(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
    prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.textSecondary) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
    filled: true, fillColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    final catalogueAsync = ref.watch(catalogueProvider);
    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: KleAppBar.back(
          title: 'New Service Request',
          roleColor: AppColors.primary,
          onBack: () => context.go('/patient'),
        ),
        body: catalogueAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('Could not load services.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(catalogueProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
            ),
          ])),
          data: (services) {
            if (services.isEmpty) return Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.medical_services_outlined, size: 56, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No services available yet.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
              ]),
            ));
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // ── Pre-fill notice ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Fields marked with * are required. Details pre-filled from your profile.',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  // ── SECTION: Patient Information ──────────────────────────
                  _SectionHeader('Patient Information'),
                  const SizedBox(height: 12),
                  // Patient Name
                  _label('Patient Name'),
                  TextFormField(
                    controller: _patientNameCtrl,
                    decoration: _dec('Enter full name', icon: Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                    autovalidateMode: _nameTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    onChanged: (_) => setState(() => _nameTouched = true),
                    validator: (v) => Validators.required(v, 'Patient name'),
                  ),
                  const SizedBox(height: 12),
                  // Contact + Alt Contact side by side
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('Contact Number'),
                      TextFormField(
                        controller: _contactCtrl,
                        decoration: _dec('10-digit mobile', icon: Icons.phone_outlined),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        autovalidateMode: _contactTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                        onChanged: (_) => setState(() => _contactTouched = true),
                        validator: Validators.phoneRequired,
                      ),
                    ])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('Alt. Contact', required: false),
                      TextFormField(
                        controller: _altContactCtrl,
                        decoration: _dec('Alt. mobile', icon: Icons.phone_callback_outlined),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        autovalidateMode: _altContactTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                        onChanged: (_) => setState(() => _altContactTouched = true),
                        validator: Validators.phone,
                      ),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  // ── SECTION: Service Type ─────────────────────────────────
                  _SectionHeader('Service Type'),
                  const SizedBox(height: 4),
                  RichText(text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                    children: const [
                      TextSpan(text: 'Select one or more services '),
                      TextSpan(text: '*', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                    ],
                  )),
                  const SizedBox(height: 10),
                  _ServiceDropdownField(
                    services: services,
                    selectedIds: _selectedServiceIds,
                    touched: _servicesTouched,
                    onChanged: (ids) => setState(() {
                      _servicesTouched = true;
                      _selectedServiceIds
                        ..clear()
                        ..addAll(ids);
                    }),
                    onTouched: () => setState(() => _servicesTouched = true),
                  ),
                  if (_servicesTouched && _selectedServiceIds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text('Please select at least one service',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFE53935))),
                    ),
                  // ── Service note — shown once below the dropdown ───────────
                  // Picks the description from the first selected service.
                  // Since all services share the same note, it shows only once.
                  if (_selectedServiceIds.isNotEmpty &&
                      services
                          .where((s) => _selectedServiceIds.contains(s.id))
                          .firstOrNull
                          ?.description
                          .isNotEmpty ==
                          true) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(Icons.info_outline_rounded,
                                size: 14, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              services
                                  .where((s) => _selectedServiceIds.contains(s.id))
                                  .first
                                  .description,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1565C0),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // ── SECTION: Location ─────────────────────────────────────
                  _SectionHeader('Location'),
                  const SizedBox(height: 12),
                  // Area dropdown
                  _label('Area / Locality'),
                  _PatientAreaField(
                    selectedArea: _selectedArea,
                    touched: _areaTouched,
                    onAreaChanged: (v) => setState(() { _selectedArea = v; _areaTouched = true; }),
                  ),
                  const SizedBox(height: 12),
                  // Address
                  _label('House / Flat / Street Address'),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: _dec('Street, building, landmark', icon: Icons.home_outlined),
                    maxLines: 2,
                    autovalidateMode: _addressTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    onChanged: (_) => setState(() => _addressTouched = true),
                    validator: (v) => Validators.required(v, 'Address'),
                  ),
                  const SizedBox(height: 12),
                  // Pincode + City + State row
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('Pincode', required: false),
                      TextFormField(
                        controller: _pincodeCtrl,
                        decoration: _dec('6-digit', icon: Icons.pin_outlined),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        autovalidateMode: _pincodeTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                        onChanged: (_) => setState(() => _pincodeTouched = true),
                        validator: Validators.pincode,
                      ),
                    ])),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('City', required: false),
                      _LockedField(label: 'City', value: 'Belgaum', icon: Icons.location_city_outlined),
                    ])),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('State', required: false),
                      _LockedField(label: 'State', value: 'Karnataka', icon: Icons.map_outlined),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  // ── SECTION: Schedule ─────────────────────────────────────
                  _SectionHeader('Schedule'),
                  const SizedBox(height: 12),
                  _label('Service Dates'),
                  _DateRangeField(startDate: _startDate, endDate: _endDate, onTap: _pickDateRange),
                  if (_dateTouched && (_startDate == null || _endDate == null))
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text('Please select service dates',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFE53935))),
                    ),
                  if (_startDate != null && _endDate != null) ...[
                    const SizedBox(height: 10),
                    _DaysSummaryBadge(numDays: _numDays),
                  ],
                  const SizedBox(height: 12),
                  // Price summary
                  if (_startDate != null && _endDate != null && _selectedServiceIds.isNotEmpty) ...[
                    _MultiPriceSummary(
                      services: services.where((s) => _selectedServiceIds.contains(s.id)).toList(),
                      numDays: _numDays,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Preferred time — 7 static time slots
                  _label('Preferred Time', required: false),
                  _StaticTimeDropdown(
                    selectedTime: _preferredTime,
                    onChanged: (v) => setState(() => _preferredTime = v),
                  ),
                  const SizedBox(height: 20),
                  // ── SECTION: Urgency & Notes ──────────────────────────────
                  _SectionHeader('Urgency & Notes'),
                  const SizedBox(height: 12),
                  _label('Urgency Level'),
                  _UrgencySelector(selected: _urgencyLevel, onChanged: (v) => setState(() => _urgencyLevel = v)),
                  const SizedBox(height: 12),
                  _label('Special Notes', required: false),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: _dec('Any special instructions or requirements…', icon: Icons.note_outlined),
                    maxLines: 3,
                    maxLength: 500,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        isFocused ? Text('$currentLength/$maxLength',
                            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)) : null,
                  ),
                  const SizedBox(height: 28),
                  CustomButton(label: AppStrings.submitRequest, onPressed: _isSubmitting ? null : () => _submit(services)),
                  const SizedBox(height: 32),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service dropdown field — tappable field that shows selected services as chips
// and opens a searchable multi-select bottom sheet on tap.
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceDropdownField extends StatelessWidget {
  final List<CatalogueService>      services;
  final Set<String>                 selectedIds;
  final bool                        touched;
  final void Function(Set<String>)  onChanged;
  final VoidCallback                onTouched;

  const _ServiceDropdownField({
    required this.services,
    required this.selectedIds,
    required this.touched,
    required this.onChanged,
    required this.onTouched,
  });

  List<CatalogueService> get _selected =>
      services.where((s) => selectedIds.contains(s.id)).toList();

  @override
  Widget build(BuildContext context) {
    final selected  = _selected;
    final hasError  = touched && selected.isEmpty;
    final hasSelect = selected.isNotEmpty;

    return GestureDetector(
      onTap: () {
        onTouched();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ServicePickerSheet(
            services:    services,
            selectedIds: Set<String>.from(selectedIds),
            onConfirm:   onChanged,
          ),
        );
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Tappable field container ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFE53935)
                  : hasSelect ? AppColors.primary : AppColors.divider,
              width: (hasError || hasSelect) ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Icon(Icons.medical_services_outlined, size: 18,
                color: hasError
                    ? const Color(0xFFE53935)
                    : hasSelect ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: hasSelect
                  // Selected chips preview
                  ? Wrap(spacing: 6, runSpacing: 6, children: selected.map((svc) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_rounded, size: 11, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(svc.name, style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ]),
                      ),
                    ).toList())
                  // Placeholder
                  : Text('Tap to search and select services…',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18,
                color: hasSelect ? AppColors.primary : AppColors.textHint),
          ]),
        ),
        // Count badge
        if (hasSelect)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text('${selected.length} service${selected.length == 1 ? '' : 's'} selected  •  tap to change',
                style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Searchable multi-select bottom sheet for services
// ─────────────────────────────────────────────────────────────────────────────
class _ServicePickerSheet extends StatefulWidget {
  final List<CatalogueService>     services;
  final Set<String>                selectedIds;   // mutable working copy
  final void Function(Set<String>) onConfirm;

  const _ServicePickerSheet({
    required this.services,
    required this.selectedIds,
    required this.onConfirm,
  });

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  late final Set<String> _working;
  final _searchCtrl = TextEditingController();
  String _query     = '';

  @override
  void initState() {
    super.initState();
    _working = Set<String>.from(widget.selectedIds);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<CatalogueService> get _filtered {
    if (_query.isEmpty) return widget.services;
    final q = _query.toLowerCase();
    return widget.services.where((s) =>
        s.name.toLowerCase().contains(q) ||
        s.category.toLowerCase().contains(q) ||
        s.description.toLowerCase().contains(q)).toList();
  }

  void _toggle(String id) => setState(() =>
      _working.contains(id) ? _working.remove(id) : _working.add(id));

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final Map<String, List<CatalogueService>> grouped = {};
    for (final s in filtered) grouped.putIfAbsent(s.category, () => []).add(s);
    final cats = grouped.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize:     0.50,
      maxChildSize:     0.95,
      expand:           false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // ── Handle ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 0),
            child: Row(children: [
              const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Select Services', style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Search and pick one or more', style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
              ])),
              if (_working.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_working.length} selected',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
            ]),
          ),

          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller:  _searchCtrl,
              autofocus:   true,
              onChanged:   (v) => setState(() => _query = v.trim()),
              decoration:  InputDecoration(
                hintText:  'Search by name or category…',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
                filled:     true,
                fillColor:  AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── Result count ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(children: [
              Text('${filtered.length} service${filtered.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              const Spacer(),
              if (_working.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _working.clear()),
                  child: Text('Clear all',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          const Divider(height: 1),

          // ── Service list ─────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textHint),
                    const SizedBox(height: 10),
                    Text('No services match "$_query"',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  ]))
                : ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      for (final cat in cats) ...[
                        // Category header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                          child: Row(children: [
                            Container(width: 3, height: 14,
                                decoration: BoxDecoration(color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            Text(cat.toUpperCase(), style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary, letterSpacing: 0.8)),
                            const SizedBox(width: 6),
                            Text('(${grouped[cat]!.length})', style: GoogleFonts.poppins(
                                fontSize: 10, color: AppColors.textHint)),
                          ]),
                        ),
                        // Service tiles
                        for (final svc in grouped[cat]!)
                          _ServicePickerTile(
                            service:  svc,
                            selected: _working.contains(svc.id),
                            onTap:    () => _toggle(svc.id),
                          ),
                      ],
                    ],
                  ),
          ),

          // ── Confirm bar ──────────────────────────────────────────────────
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    side: BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: _working.isEmpty ? null : () {
                    widget.onConfirm(Set<String>.from(_working));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _working.isEmpty
                        ? 'Select a service'
                        : 'Confirm ${_working.length} service${_working.length == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual service tile in the picker sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ServicePickerTile extends StatelessWidget {
  final CatalogueService service;
  final bool             selected;
  final VoidCallback     onTap;
  const _ServicePickerTile({required this.service, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: AppColors.primary.withValues(alpha: 0.30)) : null,
        ),
        child: Row(children: [
          // Checkbox indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 0 : 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),

          // Name + description + price
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(service.name, style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textPrimary)),
            if (service.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(service.description, style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ])),

          // Price badge
          if (service.price != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.30)
                      : AppColors.success.withValues(alpha: 0.30),
                ),
              ),
              child: Text('₹${service.price!.toStringAsFixed(0)}/day',
                  style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.success,
                  )),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static Preferred Time dropdown — 7 fixed time slots
// ─────────────────────────────────────────────────────────────────────────────
class _StaticTimeDropdown extends StatelessWidget {
  final String?                selectedTime;
  final void Function(String?) onChanged;

  const _StaticTimeDropdown({
    required this.selectedTime,
    required this.onChanged,
  });

  // 7 static time slots — label : display text
  static const _slots = <({String value, String label, String sub, Color dot})>[
    (value: 'Morning 8-10 AM',    label: 'Morning',   sub: '8:00 AM – 10:00 AM',  dot: Color(0xFFFFA726)),
    (value: 'Morning 10-12 PM',   label: 'Late Morning', sub: '10:00 AM – 12:00 PM', dot: Color(0xFFFF7043)),
    (value: 'Afternoon 12-2 PM',  label: 'Afternoon', sub: '12:00 PM – 2:00 PM',  dot: Color(0xFF42A5F5)),
    (value: 'Afternoon 2-4 PM',   label: 'Late Afternoon', sub: '2:00 PM – 4:00 PM', dot: Color(0xFF26C6DA)),
    (value: 'Evening 4-6 PM',     label: 'Evening',   sub: '4:00 PM – 6:00 PM',   dot: Color(0xFF7E57C2)),
    (value: 'Evening 6-8 PM',     label: 'Late Evening', sub: '6:00 PM – 8:00 PM', dot: Color(0xFF5C6BC0)),
    (value: 'Night 8-10 PM',      label: 'Night',     sub: '8:00 PM – 10:00 PM',  dot: Color(0xFF455A64)),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = selectedTime;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected != null ? AppColors.primary : AppColors.divider,
          width: selected != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String?>(
            value: selected,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: selected != null ? AppColors.primary : AppColors.textHint,
              size: 20,
            ),
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
            hint: Row(children: [
              const Icon(Icons.access_time_outlined, size: 18, color: AppColors.textHint),
              const SizedBox(width: 10),
              Text('No preference',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
            ]),
            items: [
              // No preference — always first
              DropdownMenuItem<String?>(
                value: null,
                child: Row(children: [
                  const Icon(Icons.remove_circle_outline_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text('No preference',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                ]),
              ),
              // 7 static slots
              ..._slots.map((s) => DropdownMenuItem<String?>(
                value: s.value,
                child: Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: s.dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.label,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(s.sub,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ]),
              )),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Multi-service price summary
// ─────────────────────────────────────────────────────────────────────────────
class _MultiPriceSummary extends StatelessWidget {
  final List<CatalogueService> services;
  final int numDays;
  const _MultiPriceSummary({required this.services, required this.numDays});

  @override
  Widget build(BuildContext context) {
    final priced = services.where((s) => s.price != null).toList();
    if (priced.isEmpty) return const SizedBox.shrink();
    final total = priced.fold<double>(0, (sum, s) => sum + s.price! * numDays);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 15),
          const SizedBox(width: 8),
          Text('Price Summary', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
            child: Text('$numDays day${numDays == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        ...priced.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.circle, size: 5, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(child: Text(s.name, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))),
            Text('₹${s.price!.toStringAsFixed(0)} × $numDays = ₹${(s.price! * numDays).toStringAsFixed(2)}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        )),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.20), margin: const EdgeInsets.symmetric(vertical: 8)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total Payable', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          Text('₹${total.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Days summary badge
// ─────────────────────────────────────────────────────────────────────────────
class _DaysSummaryBadge extends StatelessWidget {
  final int numDays;
  const _DaysSummaryBadge({required this.numDays});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
    ),
    child: Row(children: [
      const Icon(Icons.timelapse_outlined, color: AppColors.primary, size: 16),
      const SizedBox(width: 10),
      Text('Duration: ', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
      Text('$numDays day${numDays == 1 ? '' : 's'}',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
      Text('  (auto-calculated)', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Date range field
// ─────────────────────────────────────────────────────────────────────────────
class _DateRangeField extends StatelessWidget {
  final DateTime?    startDate;
  final DateTime?    endDate;
  final VoidCallback onTap;
  const _DateRangeField({required this.startDate, required this.endDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasRange = startDate != null && endDate != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: hasRange ? AppColors.primary : AppColors.divider,
              width: hasRange ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.date_range_outlined, size: 18,
              color: hasRange ? AppColors.primary : AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Start', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.textHint, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(startDate != null ? DateFormat('dd MMM yyyy').format(startDate!) : 'Select dates',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
                      color: startDate != null ? AppColors.textPrimary : AppColors.textHint)),
            ])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded, size: 14,
                  color: hasRange ? AppColors.primary : AppColors.textHint),
            ),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('End', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.textHint, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(endDate != null ? DateFormat('dd MMM yyyy').format(endDate!) : '—',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
                      color: endDate != null ? AppColors.textPrimary : AppColors.textHint)),
            ])),
          ])),
          if (hasRange)
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16)
          else
            const Icon(Icons.edit_calendar_outlined, color: AppColors.textHint, size: 16),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Urgency selector
// ─────────────────────────────────────────────────────────────────────────────
class _UrgencySelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _UrgencySelector({required this.selected, required this.onChanged});

  static const _options = [
    ('routine',   'Routine',   AppColors.success, Icons.check_circle_outline),
    ('urgent',    'Urgent',    AppColors.warning, Icons.warning_amber_outlined),
    ('emergency', 'Emergency', AppColors.error,   Icons.emergency_outlined),
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: _options.map((opt) {
      final (value, label, color, icon) = opt;
      final sel = selected == value;
      return Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? color.withValues(alpha: 0.10) : Colors.white,
              border: Border.all(color: sel ? color : AppColors.divider, width: sel ? 1.5 : 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Icon(icon, color: sel ? color : AppColors.textHint, size: 18),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.poppins(fontSize: 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  color: sel ? color : AppColors.textHint)),
            ]),
          ),
        ),
      ));
    }).toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Locked field (city / state)
// ─────────────────────────────────────────────────────────────────────────────
class _LockedField extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _LockedField({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis)),
      const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.textHint),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Area picker field + searchable bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _PatientAreaField extends StatelessWidget {
  final String?               selectedArea;
  final bool                  touched;
  final ValueChanged<String?> onAreaChanged;
  const _PatientAreaField({required this.selectedArea, required this.touched, required this.onAreaChanged});

  @override
  Widget build(BuildContext context) {
    final hasError = touched && selectedArea == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => _showAreaSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? const Color(0xFFE53935) : (selectedArea != null ? AppColors.primary : AppColors.divider),
              width: (hasError || selectedArea != null) ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Icon(Icons.location_on_outlined, size: 18,
                color: hasError ? const Color(0xFFE53935) : (selectedArea != null ? AppColors.primary : AppColors.textHint)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              selectedArea ?? 'Select area / locality',
              style: GoogleFonts.poppins(fontSize: 13,
                  fontWeight: selectedArea != null ? FontWeight.w600 : FontWeight.normal,
                  color: hasError
                      ? const Color(0xFFE53935)
                      : (selectedArea != null ? AppColors.textPrimary : AppColors.textHint)),
            )),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18,
                color: selectedArea != null ? AppColors.primary : AppColors.textHint),
          ]),
        ),
      ),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text('Please select your area',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFE53935))),
        ),
      if (selectedArea != null) ...[
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(_groupOf(selectedArea!),
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
        ),
      ],
    ]);
  }

  String _groupOf(String area) =>
      belgaumAreas.where((a) => a.name == area).firstOrNull?.group ?? '';

  void _showAreaSheet(BuildContext context) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _PatientAreaPickerSheet(
      selected: selectedArea,
      onSelected: (area) { onAreaChanged(area); },
    ),
  );
}

class _PatientAreaPickerSheet extends StatefulWidget {
  final String?              selected;
  final ValueChanged<String> onSelected;
  const _PatientAreaPickerSheet({required this.selected, required this.onSelected});
  @override
  State<_PatientAreaPickerSheet> createState() => _PatientAreaPickerSheetState();
}

class _PatientAreaPickerSheetState extends State<_PatientAreaPickerSheet> {
  String _search = '';
  final  _ctrl   = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<BelgaumArea> get _filtered {
    if (_search.isEmpty) return belgaumAreas;
    final q = _search.toLowerCase();
    return belgaumAreas.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped  = <String, List<BelgaumArea>>{};
    for (final a in filtered) grouped.putIfAbsent(a.group, () => []).add(a);

    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 10, bottom: 8), width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Select Area', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _ctrl, autofocus: true,
              onChanged: (v) => setState(() => _search = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search area…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _ctrl.clear(); setState(() => _search = ''); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: filtered.isEmpty
            ? Center(child: Text('No areas match "$_search"',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)))
            : ListView(controller: ctrl, padding: const EdgeInsets.only(bottom: 24), children: [
                for (final group in belgaumAreaGroups)
                  if (grouped.containsKey(group)) ...[
                    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Text(group, style: GoogleFonts.poppins(fontSize: 11,
                            fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5))),
                    const Divider(height: 1, indent: 16),
                    for (final area in grouped[group]!)
                      ListTile(
                        dense: true,
                        leading: Icon(Icons.location_on_rounded, size: 16,
                            color: widget.selected == area.name ? AppColors.primary : AppColors.textHint),
                        title: Text(area.name, style: GoogleFonts.poppins(fontSize: 13,
                            fontWeight: widget.selected == area.name ? FontWeight.w700 : FontWeight.normal,
                            color: widget.selected == area.name ? AppColors.primary : AppColors.textPrimary)),
                        trailing: widget.selected == area.name
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16) : null,
                        onTap: () { widget.onSelected(area.name); Navigator.pop(context); },
                      ),
                  ],
              ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 18,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
  ]);
}
