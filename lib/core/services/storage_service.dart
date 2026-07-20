import 'dart:convert';
import 'dart:typed_data';

class StorageService {
  String encodeImage(Uint8List bytes) => base64Encode(bytes);

  Uint8List decodeImage(String base64String) => base64Decode(base64String);
}
