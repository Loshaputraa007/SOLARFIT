import 'dart:typed_data';
import 'download_stub.dart' if (dart.library.html) 'download_web.dart';

class FileSaver {
  static void saveBytes(Uint8List bytes, String fileName) {
    downloadPdf(bytes, fileName);
  }
}
