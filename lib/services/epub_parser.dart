import 'dart:io';
import 'package:epubx/epubx.dart';
import '../models/book.dart';
import 'rsvp_service.dart';

class EpubParser {
  static Future<({List<String> words, String title, String author, List<BookChapter> chapters})> parse(
      String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final book = await EpubReader.readBook(bytes);

    final title = book.Title ?? 'Unknown Title';
    final author = book.Author ?? 'Unknown Author';

    final buffer = StringBuffer();
    final seen = <String>{};
    final chapters = <BookChapter>[];
    final wordOffsetRef = [0]; // mutable word count via single-element list

    for (final chapter in book.Chapters ?? <EpubChapter>[]) {
      _extractChapterText(chapter, buffer, seen, chapters, wordOffsetRef);
    }

    final words = RsvpService.splitIntoWords(buffer.toString());
    return (words: words, title: title, author: author, chapters: chapters);
  }

  static void _extractChapterText(
    EpubChapter chapter,
    StringBuffer buf,
    Set<String> seen,
    List<BookChapter> chapters,
    List<int> wordOffsetRef,
  ) {
    final fileName = chapter.ContentFileName ?? '';
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
        final chapterName = (chapter.Title ?? '').trim();
        if (chapterName.isNotEmpty) {
          chapters.add(BookChapter(name: chapterName, wordIndex: wordOffsetRef[0]));
        }
        wordOffsetRef[0] += RsvpService.splitIntoWords(stripped).length;
        buf.write(stripped);
        buf.write(' ');
      }
    }
    for (final sub in chapter.SubChapters ?? <EpubChapter>[]) {
      _extractChapterText(sub, buf, seen, chapters, wordOffsetRef);
    }
  }
}
