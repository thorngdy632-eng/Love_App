import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

final _CachedImageDecoder _decoder = _CachedImageDecoder();

Uint8List cachedBase64Decode(String input) => _decoder.decode(input);

MemoryImage cachedMemoryImage(String base64String) {
  return MemoryImage(cachedBase64Decode(base64String));
}

class _CacheEntry {
  final Uint8List bytes;
  final DateTime timestamp;
  _CacheEntry(this.bytes) : timestamp = DateTime.now();
  bool get isExpired => DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

class _CachedImageDecoder {
  final Map<String, _CacheEntry> _cache = {};

  Uint8List decode(String input) {
    final cached = _cache[input];
    if (cached != null && !cached.isExpired) return cached.bytes;
    final decoded = base64Decode(input);
    _evictIfNeeded();
    _cache[input] = _CacheEntry(decoded);
    return decoded;
  }

  void _evictIfNeeded() {
    if (_cache.length < 50) return;
    _cache.removeWhere((_, entry) => entry.isExpired);
    if (_cache.length >= 50) {
      _cache.remove(_cache.keys.first);
    }
  }
}
