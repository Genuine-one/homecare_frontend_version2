import 'package:flutter/material.dart';

/// A decorative semi-transparent circle used as background decoration
/// on login/register screens. Named `LoginBackgroundBubble` to distinguish
/// it from app-level notification bubbles.
class LoginBackgroundBubble extends StatelessWidget {
  final double  size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double  alpha;

  const LoginBackgroundBubble({
    super.key,
    required this.size,
    required this.alpha,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:    top,
      bottom: bottom,
      left:   left,
      right:  right,
      child: Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    );
  }
}
