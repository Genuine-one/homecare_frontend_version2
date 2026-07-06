import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/resource_categories_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'admin_category_list_tile.dart';
import 'admin_nurse_shared.dart';

// ── Shared decoration factory for category text fields ───────────────────────
InputDecoration _catFieldDec(String label, IconData icon) => InputDecoration(
  labelText:  label,
  labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
  prefixIcon: Icon(icon, color: AppColors.adminColor, size: 18),
  filled:    true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider)),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider)),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.adminColor, width: 1.8)),
  errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error)),
);

/// Full CRUD bottom sheet for resource categories.
class AdminCategoriesSheet extends ConsumerStatefulWidget {
  const AdminCategoriesSheet({super.key});

  @override
  ConsumerState<AdminCategoriesSheet> createState() =>
      _AdminCategoriesSheetState();
}

class _AdminCategoriesSheetState extends ConsumerState<AdminCategoriesSheet> {
  final _addKey    = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool    _addLoading  = false;
  String? _addError;
  bool    _showAddForm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_addKey.currentState!.validate()) return;
    setState(() { _addLoading = true; _addError = null; });
    final ok = await ref
        .read(resourceCategoriesProvider.notifier)
        .createCategory(
          _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _addLoading = false);
    if (ok) {
      _nameCtrl.clear();
      _descCtrl.clear();
      setState(() => _showAddForm = false);
    } else {
      setState(() =>
          _addError =
              ref.read(resourceCategoriesProvider).valueOrNull?.error ??
                  'Failed to create category.');
    }
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _confirmDeleteDialog(context, name);
    if (ok == true && mounted) {
      await ref.read(resourceCategoriesProvider.notifier)
          .deleteCategory(id, name);
    }
  }

  Future<void> _toggleActive(String id, String name, bool active) async {
    await ref.read(resourceCategoriesProvider.notifier)
        .updateCategory(id, isActive: !active);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(resourceCategoriesProvider);
    final categories = asyncState.valueOrNull?.categories ?? [];

    asyncState.whenData((s) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || s.successMessage == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(s.successMessage!,
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
      });
    });

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize:     0.40,
        maxChildSize:     0.92,
        expand:           false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              _CategoriesSheetHeader(
                count:       categories.length,
                showingForm: _showAddForm,
                onToggleForm: () => setState(() {
                  _showAddForm = !_showAddForm;
                  if (!_showAddForm) {
                    _addError = null;
                    _nameCtrl.clear();
                    _descCtrl.clear();
                  }
                }),
              ),
              const Divider(height: 1),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve:    Curves.easeInOut,
                child: _showAddForm
                    ? _AddCategoryForm(
                        formKey:   _addKey,
                        nameCtrl:  _nameCtrl,
                        descCtrl:  _descCtrl,
                        isLoading: _addLoading,
                        error:     _addError,
                        onSubmit:  _create,
                        onCancel:  () => setState(() {
                          _showAddForm = false;
                          _addError    = null;
                          _nameCtrl.clear();
                          _descCtrl.clear();
                        }),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: asyncState.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.adminColor)),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(e.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(resourceCategoriesProvider.notifier)
                                .refresh(),
                            icon:  const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.adminColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (_) => categories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.category_outlined,
                                    size: 56, color: AppColors.textHint),
                                const SizedBox(height: 14),
                                Text('No categories yet.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    )),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "Add New" above to create your first category.',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: AppColors.textHint),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller:      ctrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount:       categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => AdminCategoryListTile(
                            cat:      categories[i],
                            onToggle: _toggleActive,
                            onDelete: _delete,
                          ),
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
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesSheetHeader extends StatelessWidget {
  final int          count;
  final bool         showingForm;
  final VoidCallback onToggleForm;

  const _CategoriesSheetHeader({
    required this.count,
    required this.showingForm,
    required this.onToggleForm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient:     AppColors.adminGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.category_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resource Categories',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text('$count categor${count == 1 ? 'y' : 'ies'}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: showingForm
              ? IconButton(
                  key: const ValueKey('close'),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: onToggleForm,
                )
              : TextButton.icon(
                  key: const ValueKey('add'),
                  onPressed: onToggleForm,
                  icon: const Icon(Icons.add_rounded,
                      size: 16, color: AppColors.adminColor),
                  label: Text('Add New',
                      style: GoogleFonts.poppins(
                        color:      AppColors.adminColor,
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                      )),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        AppColors.adminColor.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ]),
    );
  }
}

class _AddCategoryForm extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final bool                  isLoading;
  final String?               error;
  final VoidCallback          onSubmit;
  final VoidCallback          onCancel;

  const _AddCategoryForm({
    required this.formKey,
    required this.nameCtrl,
    required this.descCtrl,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Category',
                style: GoogleFonts.poppins(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      AppColors.textPrimary,
                )),
            const SizedBox(height: 10),
            if (error != null) ...[
              NurseSheetErrorBanner(message: error!),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller:         nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textPrimary),
              decoration:
                  _catFieldDec('Category Name *', Icons.category_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'At least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: descCtrl,
              maxLines:   2,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textPrimary),
              decoration: _catFieldDec(
                'Description (optional)', Icons.description_outlined,
              ).copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                        color:      AppColors.textSecondary,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: NurseSheetSubmitButton(
                  label:     'Create Category',
                  icon:      Icons.add_rounded,
                  isLoading: isLoading,
                  onTap:     onSubmit,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Confirm-delete dialog (file-scoped helper) ────────────────────────────────
Future<bool?> _confirmDeleteDialog(BuildContext context, String name) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete Category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      content: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
              color: AppColors.textPrimary, fontSize: 13),
          children: [
            const TextSpan(text: 'Delete category '),
            TextSpan(text: '"$name"',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(
                text: '? Resources in this category will not be deleted.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40)),
          child: Text('Delete', style: GoogleFonts.poppins()),
        ),
      ],
    ),
  );
}
