/// KLE HOMECARE — MIS Report tab bar (Resources / Services).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MisTabBar extends StatelessWidget {
  final TabController controller;
  const MisTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1976D2), Color(0xFF0D47A1)]),
          borderRadius: BorderRadius.circular(12)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: const [
          _Tab(Icons.person_outline_rounded,         'Resources'),
          _Tab(Icons.medical_services_outlined,       'Services'),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tab(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 42,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
