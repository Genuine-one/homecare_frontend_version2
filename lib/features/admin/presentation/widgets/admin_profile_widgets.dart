import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

// ── Profile hero banner ───────────────────────────────────────────────────────
class AdminProfileHero extends StatelessWidget {
  final dynamic user;
  final bool    isDesktop;

  const AdminProfileHero({
    super.key,
    required this.user,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final name = (user?.fullName as String?) ?? 'Administrator';

    return Container(
      width:      double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.adminGradient),
      child: Stack(
        children: [
          Positioned(top: -30,    right: -30, child: _BgCircle(100, 0.07)),
          Positioned(bottom: -20, left:  -20, child: _BgCircle(80,  0.05)),
          Positioned(top: 20,     left:   80, child: _BgCircle(50,  0.04)),
          Padding(
            padding: EdgeInsets.fromLTRB(
                isDesktop ? 40 : 20, 32,
                isDesktop ? 40 : 20, 28),
            child: isDesktop
                ? Row(children: [
                    AdminAvatarWidget(name: name, size: 72),
                    const SizedBox(width: 24),
                    AdminNameBlock(name: name, email: user?.email ?? ''),
                  ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AdminAvatarWidget(name: name, size: 64),
                      const SizedBox(height: 14),
                      AdminNameBlock(
                          name:   name,
                          email:  user?.email ?? '',
                          center: true),
                    ],
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class AdminAvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  const AdminAvatarWidget({
    super.key,
    required this.name,
    required this.size,
  });

  String _initials(String n) {
    final p = n.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : n.isNotEmpty
            ? n[0].toUpperCase()
            : 'A';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        color:  Colors.white.withValues(alpha: 0.20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.50), width: 2.5),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.20),
            blurRadius: 16,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: GoogleFonts.poppins(
            fontSize:   size * 0.32,
            fontWeight: FontWeight.w800,
            color:      Colors.white,
          ),
        ),
      ),
    );
  }
}

class AdminNameBlock extends StatelessWidget {
  final String name;
  final String email;
  final bool   center;
  const AdminNameBlock({
    super.key,
    required this.name,
    required this.email,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final align =
        center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(name,
            style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   22,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 3),
        Text(email,
            style: GoogleFonts.poppins(
              color:    Colors.white.withValues(alpha: 0.70),
              fontSize: 12,
            )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.admin_panel_settings_rounded,
                size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text('Administrator',
                style: GoogleFonts.poppins(
                  color:      Colors.white,
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                )),
          ]),
        ),
      ],
    );
  }
}

class _BgCircle extends StatelessWidget {
  final double size;
  final double alpha;
  const _BgCircle(this.size, this.alpha);

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

// ── Section card ──────────────────────────────────────────────────────────────
class AdminProfileSectionCard extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final Color        color;
  final List<Widget> children;

  const AdminProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textPrimary,
                  )),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class AdminProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     isLast;

  const AdminProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.textSecondary)),
                  Text(value,
                      style: GoogleFonts.poppins(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.textPrimary,
                      )),
                ],
              ),
            ),
          ]),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 60, color: AppColors.divider),
      ],
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────
class AdminProfileActionRow extends StatefulWidget {
  final IconData     icon;
  final String       label;
  final String       sub;
  final Color        color;
  final VoidCallback onTap;
  final bool         isLast;

  const AdminProfileActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  State<AdminProfileActionRow> createState() =>
      _AdminProfileActionRowState();
}

class _AdminProfileActionRowState extends State<AdminProfileActionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          cursor:  SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color:    _hovered
                  ? widget.color.withValues(alpha: 0.04)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                        alpha: _hovered ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon,
                      size: 16, color: widget.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label,
                          style: GoogleFonts.poppins(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      widget.color,
                          )),
                      Text(widget.sub,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color:    AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  offset: _hovered
                      ? const Offset(0.15, 0)
                      : Offset.zero,
                  child: Icon(Icons.chevron_right_rounded,
                      size: 18,
                      color: widget.color.withValues(alpha: 0.5)),
                ),
              ]),
            ),
          ),
        ),
        if (!widget.isLast)
          const Divider(height: 1, indent: 64, color: AppColors.divider),
      ],
    );
  }
}

// ── Feedback banner ───────────────────────────────────────────────────────────
class AdminProfileBanner extends StatelessWidget {
  final String message;
  final Color  color;
  const AdminProfileBanner(this.message, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(
          color == AppColors.success
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          color: color, size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: GoogleFonts.poppins(color: color, fontSize: 12)),
        ),
      ]),
    );
  }
}
