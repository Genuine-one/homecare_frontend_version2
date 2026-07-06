import 'package:flutter/material.dart';

/// The circular white logo badge shown on login / register screens.
class LoginLogoBadge extends StatelessWidget {
  final double size;

  const LoginLogoBadge({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: ClipOval(
        child: Image.asset(
          'assets/images/kle_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
