import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation: triggers browser download using Blob and Object URLs.
Future<void> downloadFile(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = filename;
  // Add to DOM and trigger
  html.document.body?.append(anchor);
  anchor.click();
  // Clean up
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
