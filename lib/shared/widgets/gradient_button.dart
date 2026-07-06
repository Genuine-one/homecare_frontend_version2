import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A full-width gradient button with an optional leading icon and loading state.
/// Supports hover animation on desktop/web.
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool          isLoading;
  final String        label;
  final IconData?     icon;
  final Gradient      gradient;

  /// Shadow colour derived from the gradient start colour.
  final Color shadowColor;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
    required this.gradient,
    required this.shadowColor,
    this.icon,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      cursor:  enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        decoration: BoxDecoration(
          gradient:     enabled ? widget.gradient : null,
          color:        enabled ? null : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color:      widget.shadowColor.withValues(
                        alpha: _hovered ? 0.55 : 0.30),
                    blurRadius: _hovered ? 20 : 12,
                    offset:     const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap:        widget.onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width:  22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: GoogleFonts.poppins(
                            color:         Colors.white,
                            fontSize:      14,
                            fontWeight:    FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
