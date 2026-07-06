import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// A single selectable entry inside a [SearchableDropdown].
class SearchableDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;

  const SearchableDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

/// A compact filter field that looks like a normal dropdown but opens a
/// searchable picker sheet — for lists too long to scan (e.g. every
/// resource/service in the system).
///
/// Used across admin report screens wherever a "type to filter" dropdown
/// is needed instead of a plain [DropdownButton].
class SearchableDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final String allLabel;
  final List<SearchableDropdownItem<T>> items;
  final void Function(T?) onChanged;
  final Color activeColor;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.allLabel,
    required this.items,
    required this.onChanged,
    required this.activeColor,
  });

  SearchableDropdownItem<T>? get _selected {
    for (final item in items) {
      if (item.value == value) return item;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<_PickerResult<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchPickerSheet<T>(
        title: label,
        allLabel: allLabel,
        items: items,
        selected: value,
        activeColor: activeColor,
      ),
    );
    if (result != null) onChanged(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final active = selected != null;
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.07)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.45)
                : AppColors.divider,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 14,
              color: active ? activeColor : AppColors.textSecondary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              selected?.label ?? label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? activeColor : AppColors.textHint,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.search_rounded, size: 15,
              color: active ? activeColor : AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _PickerResult<T> {
  final T? value;
  const _PickerResult(this.value);
}

class _SearchPickerSheet<T> extends StatefulWidget {
  final String title;
  final String allLabel;
  final List<SearchableDropdownItem<T>> items;
  final T? selected;
  final Color activeColor;

  const _SearchPickerSheet({
    required this.title,
    required this.allLabel,
    required this.items,
    required this.selected,
    required this.activeColor,
  });

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  String _query = '';

  List<SearchableDropdownItem<T>> get _filtered {
    if (_query.trim().isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((i) =>
        i.label.toLowerCase().contains(q) ||
        (i.subtitle?.toLowerCase().contains(q) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: SizedBox(
              width: 40, height: 4,
              child: DecoratedBox(decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.all(Radius.circular(2)))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Text(widget.title, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search…',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textHint),
                filled: true, fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                if (_query.trim().isEmpty)
                  _PickerRow<T>(
                    label: widget.allLabel,
                    subtitle: null,
                    selected: widget.selected == null,
                    activeColor: widget.activeColor,
                    onTap: () => Navigator.pop(
                        context, const _PickerResult(null)),
                  ),
                ...filtered.map((item) => _PickerRow<T>(
                      label: item.label,
                      subtitle: item.subtitle,
                      selected: item.value == widget.selected,
                      activeColor: widget.activeColor,
                      onTap: () => Navigator.pop(
                          context, _PickerResult(item.value)),
                    )),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('No matches',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textHint)))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _PickerRow<T> extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _PickerRow({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      color: selected ? activeColor.withValues(alpha: 0.06) : null,
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : AppColors.textPrimary)),
              if (subtitle != null)
                Text(subtitle!, style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        if (selected)
          Icon(Icons.check_circle_rounded, size: 16, color: activeColor),
      ]),
    ),
  );
}
