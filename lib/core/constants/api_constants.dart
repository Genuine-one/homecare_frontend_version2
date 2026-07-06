import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KLE HOMECARE — API Constants
///
/// BASE URL STRATEGY:
/// ─────────────────
/// The base URL is stored in SharedPreferences so it can be changed at
/// runtime without rebuilding the APK. This is critical when using ngrok
/// (which gives a new URL every session) or when switching between
/// local dev / staging / production.
///
/// Priority order:
///   1. Value saved in SharedPreferences (set via the debug settings screen)
///   2. Platform default (see _platformDefault below)
///
/// To update the URL at runtime call:
///   await ApiConstants.setBaseUrl('https://your-new-url.ngrok-free.app/api/v1');
///   DioClient.instance.updateBaseUrl(ApiConstants.baseUrl);
class ApiConstants {
  ApiConstants._();

  // ── Shared-prefs key ──────────────────────────────────────────────────────
  static const String _baseUrlKey = 'https://homecare-backend-version2.vercel.app';

  // ── In-memory cache (set during app init) ─────────────────────────────────
  static String _cachedBaseUrl = _platformDefault;

  /// The active base URL — used by DioClient.
  static String get baseUrl => _cachedBaseUrl;

  // ── Platform defaults ─────────────────────────────────────────────────────
  /// Fallback for Android / iOS / ngrok tunnels.
  /// Replace with your current ngrok URL when testing on a real device.
  static const String _ngrokUrl =
      'https://homecare-backend-version2.vercel.app/api/v1';

  static String get _platformDefault {
    // Web: use localhost (Chrome allows localhost even with http://).
    // 127.0.0.1 and localhost are technically the same but Chrome treats
    // them differently for CORS / mixed-content purposes.
    if (kIsWeb) return 'https://homecare-backend-version2.vercel.app/api/v1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8001/api/v1';
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return _ngrokUrl;
      default:
        return _ngrokUrl;
    }
  }

  // ── Init — call once in main() before runApp ──────────────────────────────
  /// Loads the saved URL from SharedPreferences (if any) into the in-memory
  /// cache. Must be awaited before DioClient.init() is called.
  ///
  /// On web, if a 127.0.0.1 URL was previously saved, it is automatically
  /// replaced with the localhost equivalent to avoid Chrome CORS issues.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString(_baseUrlKey);

    // Auto-migrate stale 127.0.0.1 web cache → localhost
    if (kIsWeb && saved != null && saved.contains('127.0.0.1')) {
      saved = saved.replaceFirst('127.0.0.1', 'localhost');
      await prefs.setString(_baseUrlKey, saved);
    }

    _cachedBaseUrl = (saved != null && saved.isNotEmpty) ? saved : _platformDefault;
  }

  /// Persist a new base URL and update the in-memory cache.
  /// Call DioClient.instance.updateBaseUrl(ApiConstants.baseUrl) afterwards.
  static Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), ''); // strip trailing /
    final prefs   = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, trimmed);
    _cachedBaseUrl = trimmed;
  }

  /// Clear the saved URL and revert to the platform default.
  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    _cachedBaseUrl = _platformDefault;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String register       = '/auth/register';
  static const String login          = '/auth/login';
  static const String refresh        = '/auth/refresh';
  static const String logout         = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp      = '/auth/verify-otp';
  static const String resetPassword  = '/auth/reset-password';

  // ── Patient ───────────────────────────────────────────────────────────────
  static const String patientProfile       = '/patient/profile';
  static const String patientShifts        = '/patient/shifts/available';
  static const String patientRequests      = '/patient/requests';
  static const String patientNotifications = '/patient/notifications';

  static String patientRequest(String id)       => '/patient/requests/$id';
  static String patientRequestVitals(String id) => '/patient/requests/$id/vitals';
  static String patientRequestFeedback(String id) => '/patient/requests/$id/feedback';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminRequests    = '/admin/requests';
  static const String adminNurses      = '/admin/nurses';
  static const String adminAssignments = '/admin/assignments';
  static const String adminStats       = '/admin/dashboard/stats';
  static const String adminAnalytics   = '/admin/analytics';
  static const String adminMisReport   = '/admin/mis-report';

  static String adminRequest(String id)        => '/admin/requests/$id';
  static String adminAssign(String id)         => '/admin/requests/$id/assign';
  static String adminAssignBulk(String id)     => '/admin/requests/$id/assign-bulk';
  static String adminRequestPayment(String id) => '/admin/requests/$id/payment';
  static String adminRequestVitals(String id)  => '/admin/requests/$id/vitals';
  static String adminRequestFeedback(String id) => '/admin/requests/$id/feedback';
  static const String adminFeedbackSummary     = '/admin/feedback/summary';
  static const String adminUploadPaymentAttachment = '/admin/upload/payment-attachment';
  static String adminAssignment(String id)  => '/admin/assignments/$id';
  static String adminNurse(String id)       => '/admin/nurses/$id';
  static String adminNurseToggle(String id) => '/admin/nurses/$id/toggle';
  static const String adminCreateNurse     = '/admin/nurses';
  static String adminNursesByCategory(String category) => '/admin/nurses?is_active=true&category=${Uri.encodeComponent(category)}';

  // ── Nurse ─────────────────────────────────────────────────────────────────
  static const String nurseAlerts        = '/nurse/alerts';
  static const String nurseNotifications = '/nurse/notifications';

  static String nurseJob(String id)        => '/nurse/jobs/$id';
  static String nurseJobStatus(String id)  => '/nurse/jobs/$id/status';
  static String nurseJobVitals(String id)  => '/nurse/jobs/$id/vitals';
  static const String nurseAvailability   = '/nurse/availability';

  // ── Services (catalogue) ──────────────────────────────────────────────────
  static const String services          = '/services';
  static const String serviceCategories = '/services/categories';

  static String service(String id)       => '/services/$id';
  static String serviceToggle(String id) => '/services/$id/toggle';

  // ── Resource Categories ───────────────────────────────────────────────────
  static const String resourceCategories      = '/resource-categories';
  static const String adminResourceCategories = '/admin/resource-categories';

  static String adminResourceCategory(String id) => '/admin/resource-categories/$id';

  // ── Shift Roster (admin) ──────────────────────────────────────────────────
  static const String adminShiftMaster = '/admin/shift-master';
  static String adminShiftMasterItem(String id) => '/admin/shift-master/$id';

  static const String adminShifts       = '/admin/shifts';
  static const String adminShiftsManual = '/admin/shifts/manual';
  static const String adminShiftsBulk   = '/admin/shifts/bulk';
  static const String adminShiftsToday  = '/admin/shifts/today';
  static const String adminShiftsCalendar = '/admin/shifts/calendar';
  static String adminShiftAssignment(String id) => '/admin/shifts/$id';
  static String adminShiftsForResource(String id) => '/admin/shifts/resource/$id';

  static const String adminShiftSchedules = '/admin/shifts/schedules';
  static String adminShiftSchedule(String id) => '/admin/shifts/schedules/$id';
  static const String adminShiftPublish   = '/admin/shifts/publish';
  static const String adminShiftUnpublish = '/admin/shifts/unpublish';
  static const String adminShiftCopyPreviousWeek = '/admin/shifts/copy-previous-week';

  static const String adminShiftsUpload          = '/admin/shifts/upload';
  static const String adminShiftsTemplate        = '/admin/shifts/template';
  static const String adminShiftsExportExcel     = '/admin/shifts/export/excel';
  static const String adminShiftsExportRosterGrid = '/admin/shifts/export/roster-grid';
  static const String adminShiftsExportPdf       = '/admin/shifts/export/pdf';

  static const String adminShiftSwapRequests = '/admin/shifts/swap-requests';
  static String adminShiftSwapDecision(String id) => '/admin/shifts/swap-requests/$id';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
