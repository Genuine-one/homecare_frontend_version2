import 'dart:async';
import 'dart:typed_data';

/// Result of a file pick operation.
class PickedFile {
  final Uint8List bytes;
  final String    name;
  final int       sizeBytes;
  PickedFile({required this.bytes, required this.name, required this.sizeBytes});
}

/// Not supported on non-web platforms — always returns null.
Future<PickedFile?> pickFileFromWeb({String accept = ''}) async {
  return null;
}
