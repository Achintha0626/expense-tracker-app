import 'dart:typed_data';

/// Non-web stub implementation. Does nothing but keep API consistent.
Future<void> downloadFile(Uint8List bytes, String filename) async {
  // No-op on non-web platforms. Implement platform-specific file saving later.
  return;
}
