import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

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

Future<PdfDownloadResult> downloadFile(Uint8List bytes, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);

  try {
    final openResult = await OpenFilex.open(file.path, type: 'application/pdf');

    return PdfDownloadResult(
      path: file.path,
      opened: openResult.type == ResultType.done,
      openError: openResult.type == ResultType.done ? null : openResult.message,
    );
  } catch (error) {
    return PdfDownloadResult(
      path: file.path,
      opened: false,
      openError: error.toString(),
    );
  }
}
