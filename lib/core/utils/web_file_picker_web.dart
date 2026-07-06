// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Result of a web file pick operation.
class PickedFile {
  final Uint8List bytes;
  final String    name;
  final int       sizeBytes;
  PickedFile({required this.bytes, required this.name, required this.sizeBytes});
}

/// Opens the browser's native file chooser.
/// Returns null if the user cancels or no file is selected.
Future<PickedFile?> pickFileFromWeb({String accept = ''}) {
  final completer = Completer<PickedFile?>();

  final input = html.FileUploadInputElement()..accept = accept;

  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file   = files.first;
    final reader = html.FileReader();

    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(PickedFile(
          bytes:     result,
          name:      file.name,
          sizeBytes: file.size,
        ));
      } else {
        completer.complete(null);
      }
    });

    reader.onError.listen((_) => completer.complete(null));
    reader.readAsArrayBuffer(file);
  });

  html.window.onFocus.first.then((_) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!completer.isCompleted) completer.complete(null);
    });
  });

  input.click();
  return completer.future;
}
