import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageResizer {
  static const int profileQuality = 75;
  static const int profileMaxDimension = 400;
  static const int galleryQuality = 70;
  static const int galleryMaxDimension = 1280;

  static Future<Uint8List> resizeProfile(Uint8List bytes) async {
    return _resize(bytes, maxDimension: profileMaxDimension, quality: profileQuality);
  }

  static Future<Uint8List> resizeGallery(Uint8List bytes) async {
    return _resize(bytes, maxDimension: galleryMaxDimension, quality: galleryQuality);
  }

  static String resizeGalleryToBase64(Uint8List bytes) {
    final resized = _resize(bytes, maxDimension: 600, quality: 45);
    return base64Encode(resized);
  }

  static Uint8List _resize(Uint8List bytes, {required int maxDimension, required int quality}) {
    try {
      final original = img.decodeImage(bytes);
      if (original == null) return bytes;

      final w = original.width;
      final h = original.height;
      int newW = w;
      int newH = h;

      if (w > h && w > maxDimension) {
        newW = maxDimension;
        newH = (h * maxDimension / w).round();
      } else if (h > maxDimension) {
        newH = maxDimension;
        newW = (w * maxDimension / h).round();
      }

      final resized = img.copyResize(original, width: newW, height: newH);
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      debugPrint('ImageResizer._resize error: $e');
      return bytes;
    }
  }
}
