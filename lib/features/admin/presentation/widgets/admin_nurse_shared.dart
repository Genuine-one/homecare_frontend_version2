/// Shared micro-widgets used across multiple admin nurse screens.
/// All are file-private in the original but extracted here because they
/// appear in 3+ different sheets/cards.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

// ── Nurse avatar with initials ────────────────────────────────────────────────
class NurseAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final double fontSize;
  final double borderRadius;

  const NurseAvatar({
    super.key,
    required this.initials,
    this.size         = 50,
    this.fontSize     = 17,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        gradient:     AppColors.adminGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   fontSize,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}

// ── Status / role badge pill ──────────────────────────────────────────────────
class NurseBadge extends StatelessWidget {
  final String label;
  final Color  color;

  const NurseBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
            fontSize:   10,
            fontWeight: FontWeight.w700,
            color:      color,
          )),
    );
  }
}

// ── Filter pill (active/inactive/all) ────────────────────────────────────────
class NurseFilterPill extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const NurseFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
              color: selected ? color : AppColors.divider),
          boxShadow: selected
              ? [BoxShadow(
                  color:      color.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                )]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}

// ── Section title with left accent bar ───────────────────────────────────────
class NurseSectionTitle extends StatelessWidget {
  final String       title;
  final List<Widget> rows;

  const NurseSectionTitle(this.title, this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              gradient:     AppColors.adminGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding:    const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

// ── Info row in detail sheet ──────────────────────────────────────────────────
class NurseInfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const NurseInfoRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.adminColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Action button (Edit / Toggle / Remove row in detail sheet) ────────────────
class NurseActionBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;

  const NurseActionBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(label,
                style: GoogleFonts.poppins(
                  color:      color,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Styled text form field for nurse forms ────────────────────────────────────
class NurseFormField extends StatelessWidget {
  final String                      label;
  final TextEditingController       ctrl;
  final IconData                    icon;
  final String? Function(String?)?  validator;
  final bool                        obscureText;
  final Widget?                     suffixIcon;
  final TextInputType               keyboardType;

  const NurseFormField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.icon,
    this.validator,
    this.obscureText  = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   ctrl,
      validator:    validator,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
          fontSize: 13, color: AppColors.textPrimary,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: GoogleFonts.poppins(
            fontSize: 12, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.adminColor, size: 18),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.adminColor, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Category dropdown (used in create + edit sheets) ─────────────────────────
class NurseCategoryDropdown extends StatelessWidget {
  final List<String>  categoryNames;
  final String?       selectedCategory;
  final bool          disabled;
  final void Function(String?) onChanged;

  const NurseCategoryDropdown({
    super.key,
    required this.categoryNames,
    required this.selectedCategory,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:      selectedCategory,
          isExpanded: true,
          hint: Text(
            disabled ? 'No categories available' : 'Select category (optional)',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textHint),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.adminColor),
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textPrimary,
              fontWeight: FontWeight.w500),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('— None —',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            ...categoryNames.map((name) => DropdownMenuItem<String>(
              value: name,
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color:        AppColors.adminColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.category_outlined,
                      size: 13, color: AppColors.adminColor),
                ),
                const SizedBox(width: 10),
                Text(name,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
              ]),
            )),
          ],
          onChanged: disabled ? null : onChanged,
        ),
      ),
    );
  }
}

// ── Sheet submit button (gradient) ───────────────────────────────────────────
class NurseSheetSubmitButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         isLoading;
  final VoidCallback? onTap;

  const NurseSheetSubmitButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          gradient:     (isLoading || onTap == null) ? null : AppColors.adminGradient,
          color:        (isLoading || onTap == null) ? AppColors.textHint : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: (isLoading || onTap == null)
              ? []
              : [BoxShadow(
                  color:      AppColors.adminColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset:     const Offset(0, 5),
                )],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                      )),
                ]),
        ),
      ),
    );
  }
}

// ── Inline error banner for sheets ───────────────────────────────────────────
class NurseSheetErrorBanner extends StatelessWidget {
  final String message;
  const NurseSheetErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: GoogleFonts.poppins(
                  color: AppColors.error, fontSize: 12)),
        ),
      ]),
    );
  }
}

// ── Sheet header row (icon + title + subtitle + close button) ─────────────────
class NurseSheetHeader extends StatelessWidget {
  final IconData  icon;
  final String    title;
  final String?   subtitle;

  const NurseSheetHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
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
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              if (subtitle != null)
                Text(subtitle!,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ]),
    );
  }
}
