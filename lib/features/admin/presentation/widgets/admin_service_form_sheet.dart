import 'package:flutter/material.dart';
import '../../data/models/service_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sheet_handle.dart';

/// Create / Edit bottom sheet for a service.
class AdminServiceFormSheet extends StatefulWidget {
  final ServiceModel? existing;
  final Future<bool> Function(
    String name,
    String description,
    String category,
    String? icon,
    double? price,
  ) onSave;

  const AdminServiceFormSheet({
    super.key,
    this.existing,
    required this.onSave,
  });

  @override
  State<AdminServiceFormSheet> createState() => _AdminServiceFormSheetState();
}

class _AdminServiceFormSheetState extends State<AdminServiceFormSheet> {
  final _formKey   = GlobalKey<FormState>();
  late final _nameCtrl  = TextEditingController(text: widget.existing?.name ?? '');
  late final _descCtrl  = TextEditingController(text: widget.existing?.description ?? '');
  late final _catCtrl   = TextEditingController(text: widget.existing?.category ?? '');
  late final _iconCtrl  = TextEditingController(text: widget.existing?.icon ?? '');
  late final _priceCtrl = TextEditingController(
      text: widget.existing?.price != null
          ? widget.existing!.price!.toStringAsFixed(2)
          : '');

  bool _isLoading = false;

  static const _presetCategories = [
    'Nursing', 'Therapy', 'Medical', 'Care', 'Diagnostic', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    _iconCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final priceText = _priceCtrl.text.trim();
    final price = priceText.isEmpty ? null : double.tryParse(priceText);
    final ok = await widget.onSave(
      _nameCtrl.text.trim(),
      _descCtrl.text.trim(),
      _catCtrl.text.trim(),
      _iconCtrl.text.trim().isEmpty ? null : _iconCtrl.text.trim(),
      price,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),

                // Header
                Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppColors.adminColor.withValues(alpha: 0.12),
                    child: const Icon(Icons.medical_services_outlined,
                        color: AppColors.adminColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Service' : 'Add New Service',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ]),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller:         _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText:  'Service Name *',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'At least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines:   3,
                  decoration: const InputDecoration(
                    labelText:          'Description *',
                    prefixIcon:         Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Description is required';
                    if (v.trim().length < 5) return 'At least 5 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Category + quick-pick chips
                TextFormField(
                  controller:         _catCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText:  'Category *',
                    prefixIcon: Icon(Icons.category_outlined),
                    hintText:   'e.g. Nursing, Therapy…',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Category is required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _presetCategories.map((cat) {
                    final selected = _catCtrl.text.trim() == cat;
                    return ChoiceChip(
                      label: Text(cat,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white : AppColors.textPrimary,
                          )),
                      selected:      selected,
                      selectedColor: AppColors.adminColor,
                      onSelected:    (_) =>
                          setState(() => _catCtrl.text = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Icon (optional)
                TextFormField(
                  controller: _iconCtrl,
                  decoration: const InputDecoration(
                    labelText:  'Icon name / URL (optional)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // Price (optional)
                TextFormField(
                  controller:  _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText:  'Price per day (₹) — optional',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                    hintText:   'e.g. 500.00',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final val = double.tryParse(v.trim());
                    if (val == null) return 'Enter a valid number';
                    if (val < 0) return 'Price cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          isEdit ? 'Save Changes' : 'Create Service',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
