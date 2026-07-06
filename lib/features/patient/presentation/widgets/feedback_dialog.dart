// KLE HOMECARE — Patient Feedback Dialog (2-step)
//
// Step 1 — Star ratings: Overall + 4 dimension ratings
// Step 2 — Written feedback: comment, quick tags, would-recommend toggle
//
// Opens as a full-screen modal bottom sheet after a completed service request.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

/// Opens the 2-step feedback form. Returns true if submitted successfully.
Future<bool?> showFeedbackDialog(
  BuildContext context, {
  required String requestId,
  required String serviceName,
  String? resourceName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FeedbackDialog(
      requestId:    requestId,
      serviceName:  serviceName,
      resourceName: resourceName,
    ),
  );
}

class FeedbackDialog extends StatefulWidget {
  final String  requestId;
  final String  serviceName;
  final String? resourceName;

  const FeedbackDialog({
    super.key,
    required this.requestId,
    required this.serviceName,
    this.resourceName,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  // ── Step control ────────────────────────────────────────────────────────────
  int _step = 1; // 1 or 2

  // ── Step 1 — Ratings ────────────────────────────────────────────────────────
  int  _overall          = 0;
  int  _punctuality      = 0;
  int  _professionalism  = 0;
  int  _careQuality      = 0;
  int  _communication    = 0;

  // ── Step 2 — Written ────────────────────────────────────────────────────────
  final _commentCtrl = TextEditingController();
  bool? _wouldRecommend;
  final Set<String> _selectedTags = {};

  static const _availableTags = [
    'Friendly',    'Professional', 'On Time',    'Caring',
    'Experienced', 'Thorough',     'Attentive',  'Clean',
    'Supportive',  'Knowledgeable',
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────
  bool get _step1Valid => _overall > 0;

  // ── Submit ───────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_step1Valid) return;
    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'overall_rating': _overall,
      if (_punctuality     > 0) 'punctuality_rating':     _punctuality,
      if (_professionalism > 0) 'professionalism_rating': _professionalism,
      if (_careQuality     > 0) 'care_quality_rating':    _careQuality,
      if (_communication   > 0) 'communication_rating':   _communication,
      if (_commentCtrl.text.trim().isNotEmpty)
        'comment': _commentCtrl.text.trim(),
      'tags': _selectedTags.toList(),
      if (_wouldRecommend != null) 'would_recommend': _wouldRecommend,
    };

    try {
      await ApiService.instance.post(
        ApiConstants.patientRequestFeedback(widget.requestId),
        data: payload,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppHelpers.friendlyError(e)),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // header
          _buildHeader(),
          // step indicator
          _buildStepIndicator(),
          // body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: _step == 1 ? _buildStep1() : _buildStep2(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.star_rounded,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rate Your Experience',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(widget.serviceName,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ]),
    );
  }

  // ── Step indicator ───────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        _StepDot(number: 1, active: _step == 1, done: _step > 1,
            label: 'Ratings'),
        Expanded(
          child: Container(
            height: 2,
            color: _step > 1
                ? AppColors.primary
                : AppColors.divider,
          ),
        ),
        _StepDot(number: 2, active: _step == 2, done: false,
            label: 'Feedback'),
      ]),
    );
  }

  // ── Step 1: Rating sliders ───────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Big overall star picker
        _OverallStarPicker(
          value:    _overall,
          onChange: (v) => setState(() => _overall = v),
        ),
        const SizedBox(height: 20),
        // Resource name banner
        if (widget.resourceName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.nurseColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.nurseColor.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.person_pin_rounded,
                  size: 15, color: AppColors.nurseColor),
              const SizedBox(width: 8),
              Text('Resource: ',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              Text(widget.resourceName!,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        // Dimension ratings
        _RatingRow(
          label:    'Punctuality',
          icon:     Icons.access_time_rounded,
          color:    const Color(0xFF1976D2),
          value:    _punctuality,
          onChange: (v) => setState(() => _punctuality = v),
        ),
        _RatingRow(
          label:    'Professionalism',
          icon:     Icons.workspace_premium_rounded,
          color:    const Color(0xFF7B1FA2),
          value:    _professionalism,
          onChange: (v) => setState(() => _professionalism = v),
        ),
        _RatingRow(
          label:    'Care Quality',
          icon:     Icons.favorite_rounded,
          color:    const Color(0xFFE53935),
          value:    _careQuality,
          onChange: (v) => setState(() => _careQuality = v),
        ),
        _RatingRow(
          label:    'Communication',
          icon:     Icons.chat_bubble_outline_rounded,
          color:    const Color(0xFF00897B),
          value:    _communication,
          onChange: (v) => setState(() => _communication = v),
        ),
        const SizedBox(height: 24),
        // Next button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _step1Valid
                ? () => setState(() => _step = 2)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
        if (!_step1Valid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Please select an overall rating to continue',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.error)),
          ),
      ],
    );
  }

  // ── Step 2: Written feedback ──────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Comment box
        Text('Share your experience (optional)',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentCtrl,
          maxLines:   4,
          maxLength:  500,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Tell us about your experience with the service…',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textHint),
          ),
        ),
        const SizedBox(height: 18),

        // Quick tags
        Text('What went well? (select all that apply)',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final selected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => setState(() {
                selected
                    ? _selectedTags.remove(tag)
                    : _selectedTags.add(tag);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(tag,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Would recommend
        Text('Would you recommend KLE HomeCare?',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(children: [
          _RecommendTile(
            label: '👍  Yes',
            selected: _wouldRecommend == true,
            color: AppColors.success,
            onTap: () => setState(() => _wouldRecommend =
                _wouldRecommend == true ? null : true),
          ),
          const SizedBox(width: 12),
          _RecommendTile(
            label: '👎  No',
            selected: _wouldRecommend == false,
            color: AppColors.error,
            onTap: () => setState(() => _wouldRecommend =
                _wouldRecommend == false ? null : false),
          ),
        ]),
        const SizedBox(height: 24),

        // Action row: Back + Submit
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _step = 1),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text('Back',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.divider),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSubmitting ? 'Submitting…' : 'Submit Feedback',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

/// Large star row for the overall rating
class _OverallStarPicker extends StatelessWidget {
  final int value;
  final void Function(int) onChange;
  const _OverallStarPicker({required this.value, required this.onChange});

  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];
  static const _colors = [
    Color(0xFF000000),
    Color(0xFFE53935), Color(0xFFF57F17),
    Color(0xFFFDD835), Color(0xFF7CB342),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        Text('Overall Experience',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final idx    = i + 1;
            final filled = idx <= value;
            return GestureDetector(
              onTap: () => onChange(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled
                      ? const Color(0xFFFDD835)
                      : AppColors.textHint,
                  size: 44,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            value == 0 ? 'Tap to rate' : _labels[value],
            key: ValueKey(value),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: value == 0 ? AppColors.textHint : _colors[value],
            ),
          ),
        ),
      ]),
    );
  }
}

/// Compact star row for a single dimension rating
class _RatingRow extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final int      value;
  final void Function(int) onChange;

  const _RatingRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 108,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (i) {
              final idx    = i + 1;
              final filled = idx <= value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChange(idx == value ? 0 : idx),
                  child: Icon(
                    filled
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: filled
                        ? const Color(0xFFFDD835)
                        : AppColors.textHint,
                    size: 26,
                  ),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

/// Yes / No recommendation tile
class _RecommendTile extends StatelessWidget {
  final String   label;
  final bool     selected;
  final Color    color;
  final VoidCallback onTap;
  const _RecommendTile({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppColors.divider,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                )),
          ),
        ),
      ),
    );
  }
}

/// Step indicator dot
class _StepDot extends StatelessWidget {
  final int    number;
  final bool   active;
  final bool   done;
  final String label;
  const _StepDot({
    required this.number,
    required this.active,
    required this.done,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active || done ? AppColors.primary : AppColors.divider;
    final fg = active || done ? Colors.white : AppColors.textHint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: bg, shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, color: fg, size: 14)
                : Text('$number',
                    style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primary : AppColors.textHint,
            )),
      ],
    );
  }
}
