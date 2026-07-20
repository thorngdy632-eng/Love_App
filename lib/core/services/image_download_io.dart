import 'dart:io';
import 'package:flutter/services.dart';

Future<String?> downloadImageBytes(Uint8List bytes, String fileName) async {
  const channel = MethodChannel('love_app/image_saver');
  try {
    await channel.invokeMethod('saveImageToGallery', {
      'bytes': bytes,
      'fileName': fileName,
    });
    return null;
  } on MissingPluginException {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (_) {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
