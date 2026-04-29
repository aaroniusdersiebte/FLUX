import '../models/word_token.dart';

class RsvpService {
  /// ORP index: ~35% into the alphabetic characters of the word.
  static int getOrpIndex(String word) {
    final letters = word.replaceAll(RegExp(r'[^a-zA-ZÄÖÜäöü]'), '');
    if (letters.isEmpty) return 0;
    final idx = (letters.length * 0.35).floor();
    // Map back to position in original word (skipping leading non-letters)
    int letterCount = 0;
    for (int i = 0; i < word.length; i++) {
      if (RegExp(r'[a-zA-ZÄÖÜäöü]').hasMatch(word[i])) {
        if (letterCount == idx) return i;
        letterCount++;
      }
    }
    return 0;
  }

  static WordToken tokenize(String word) {
    return WordToken(word: word, orpIndex: getOrpIndex(word));
  }

  /// Base milliseconds per word from WPM setting.
  static int wpmToMs(int wpm) => (60000 / wpm).round();

  /// Duration for a specific word, optionally with adaptive pauses.
  static int getWordDuration(String word, int baseMs, bool adaptive) {
    if (!adaptive) return baseMs;
    int ms = baseMs;
    final clean = word.replaceAll(RegExp(r'[^a-zA-ZÄÖÜäöü]'), '');
    if (clean.length > 8) ms = (ms * 1.4).round();
    if (word.endsWith('.') ||
        word.endsWith('!') ||
        word.endsWith('?') ||
        word.endsWith('…')) {
      ms += 350;
    } else if (word.endsWith(',') ||
        word.endsWith(';') ||
        word.endsWith(':') ||
        word.endsWith('—')) {
      ms += 150;
    }
    return ms;
  }

  /// Split raw text into a flat list of word strings.
  /// Filters empty tokens, preserves punctuation attached to words.
  static List<String> splitIntoWords(String text) {
    return text
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Find the start index of the sentence containing [wordIndex].
  static int sentenceStart(List<String> words, int wordIndex) {
    for (int i = wordIndex - 1; i >= 0; i--) {
      final w = words[i];
      if (w.endsWith('.') || w.endsWith('!') || w.endsWith('?')) {
        return i + 1;
      }
    }
    return 0;
  }

  /// Find the start index of the next sentence after [wordIndex].
  static int nextSentenceStart(List<String> words, int wordIndex) {
    for (int i = wordIndex; i < words.length; i++) {
      final w = words[i];
      if (w.endsWith('.') || w.endsWith('!') || w.endsWith('?')) {
        return (i + 1 < words.length) ? i + 1 : words.length - 1;
      }
    }
    return words.length - 1;
  }

  /// Find the start index of the paragraph containing [wordIndex].
  static int paragraphStart(List<String> words, int wordIndex) {
    // Paragraphs are approximated as ~50-word blocks when no explicit markers.
    final block = (wordIndex ~/ 50) * 50;
    return block < 0 ? 0 : block;
  }

  /// Find the start of the next paragraph after [wordIndex].
  static int nextParagraphStart(List<String> words, int wordIndex) {
    final next = ((wordIndex ~/ 50) + 1) * 50;
    return next >= words.length ? words.length - 1 : next;
  }

  /// Get the current sentence as a string for the pause overlay.
  static String currentSentenceText(List<String> words, int wordIndex) {
    final start = sentenceStart(words, wordIndex);
    int end = wordIndex;
    for (int i = wordIndex; i < words.length && i < wordIndex + 60; i++) {
      end = i;
      final w = words[i];
      if (w.endsWith('.') || w.endsWith('!') || w.endsWith('?')) break;
    }
    return words.sublist(start, end + 1).join(' ');
  }
}
