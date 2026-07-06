import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Styled text form field used on all login and register screens.
/// The prefix icon colour is set via [accentColor] (defaults to primary).
class AuthInputField extends StatelessWidget {
  final String                    label;
  final TextEditingController     controller;
  final String? Function(String?)? validator;
  final IconData                  icon;
  final bool                      obscureText;
  final Widget?                   suffixIcon;
  final TextInputType             keyboardType;
  final ValueChanged<String>?     onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  /// Tint colour for the prefix icon and focused border.
  final Color? accentColor;

  /// When true, appends a red asterisk to the label to mark this field
  /// as mandatory.
  final bool required;

  /// When true, the field is locked (e.g. after its value has already been
  /// verified server-side) — still visible, but no longer editable.
  final bool readOnly;

  const AuthInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.validator,
    this.obscureText       = false,
    this.suffixIcon,
    this.keyboardType      = TextInputType.text,
    this.onFieldSubmitted,
    this.accentColor,
    this.inputFormatters,
    this.required          = false,
    this.readOnly          = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return TextFormField(
      controller:       controller,
      validator:        validator,
      obscureText:      obscureText,
      keyboardType:     keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters:  inputFormatters,
      readOnly:         readOnly,
      style: GoogleFonts.poppins(
        fontSize:   14,
        color:      AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.error,
                          fontWeight: FontWeight.w700),
                    ),
                  ]
                : null,
          ),
        ),
        prefixIcon: Icon(icon, color: color, size: 20),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}
