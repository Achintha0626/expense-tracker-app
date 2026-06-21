// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

class PdfDownloadResult {
  const PdfDownloadResult({
    required this.path,
    required this.opened,
    this.openError,
  });

  final String? path;
  final bool opened;
  final String? openError;
}

/// Web implementation: triggers browser download using Blob and Object URLs.
Future<PdfDownloadResult> downloadFile(Uint8List bytes, String filename) async {
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

  return const PdfDownloadResult(path: null, opened: true);
}
