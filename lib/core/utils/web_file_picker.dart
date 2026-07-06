/// Platform-adaptive file picker.
///
/// On web  → uses dart:html FileUploadInputElement (real browser picker).
/// On other platforms (Windows, Android, iOS, …) → returns null.
///
/// Consumers already guard with:
///   final picked = await pickFileFromWeb(...);
///   if (picked == null) return;
/// so the stub is safe on all non-web targets.
export 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart';
