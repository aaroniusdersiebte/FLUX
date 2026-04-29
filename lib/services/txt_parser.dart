import 'dart:io';
import 'rsvp_service.dart';

class TxtParser {
  static Future<List<String>> parse(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    return RsvpService.splitIntoWords(content);
  }
}
