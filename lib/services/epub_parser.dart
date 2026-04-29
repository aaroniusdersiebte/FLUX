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
    for (final chapter in book.Chapters ?? <EpubChapter>[]) {
      _extractChapterText(chapter, buffer);
    }

    final words = RsvpService.splitIntoWords(buffer.toString());
    return (words: words, title: title, author: author);
  }

  static void _extractChapterText(EpubChapter chapter, StringBuffer buf) {
    final content = chapter.HtmlContent ?? '';
    // Strip HTML tags
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
    for (final sub in chapter.SubChapters ?? <EpubChapter>[]) {
      _extractChapterText(sub, buf);
    }
  }
}
