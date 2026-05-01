import 'dart:io';
import 'package:epubx/epubx.dart';
import 'rsvp_service.dart';

class EpubParser {
  static Future<({List<String> words, String title, String author})> parse(
      String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final book = await EpubReader.readBook(bytes);

    final title = book.Title ?? 'Unknown Title';
    final author = book.Author ?? 'Unknown Author';

    final buffer = StringBuffer();
    final seen = <String>{};
    for (final chapter in book.Chapters ?? <EpubChapter>[]) {
      _extractChapterText(chapter, buffer, seen);
    }

    final words = RsvpService.splitIntoWords(buffer.toString());
    return (words: words, title: title, author: author);
  }

  static void _extractChapterText(
      EpubChapter chapter, StringBuffer buf, Set<String> seen) {
    final fileName = chapter.ContentFileName ?? '';
    // Only extract content from each HTML file once — sub-chapters often point
    // to anchors within the same file, causing the content to be duplicated.
    final alreadySeen = fileName.isNotEmpty && !seen.add(fileName);
    if (!alreadySeen) {
      final content = chapter.HtmlContent ?? '';
      final stripped = content
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'&nbsp;'), ' ')
          .replaceAll(RegExp(r'&amp;'), '&')
          .replaceAll(RegExp(r'&lt;'), '<')
          .replaceAll(RegExp(r'&gt;'), '>')
          .replaceAll(RegExp(r'&quot;'), '"')
          .replaceAll(RegExp(r'&#39;'), "'")
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (stripped.isNotEmpty) {
        buf.write(stripped);
        buf.write(' ');
      }
    }
    for (final sub in chapter.SubChapters ?? <EpubChapter>[]) {
      _extractChapterText(sub, buf, seen);
    }
  }
}
