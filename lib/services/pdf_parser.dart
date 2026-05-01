import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'rsvp_service.dart';

class PdfParser {
  static Future<List<String>> parse(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();
    for (int i = 0; i < document.pages.count; i++) {
      final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      if (text.isNotEmpty) {
        buffer.write(text);
        buffer.write(' ');
      }
    }
    document.dispose();
    return RsvpService.splitIntoWords(buffer.toString());
  }
}
