// lib/utils/helpers/image_to_datauri.dart
import 'dart:convert';
import 'dart:io';

class ImageToDataUri {
  static Future<String> fileToDataUri(File f) async {
    final bytes = await f.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = _mimeFromPath(f.path);
    return 'data:image/$mime;base64,$b64';
  }

  static String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'png') return 'png';
    if (ext == 'jpg' || ext == 'jpeg') return 'jpeg';
    if (ext == 'webp') return 'webp';
    return 'jpeg';
  }
}
