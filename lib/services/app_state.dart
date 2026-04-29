import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import 'epub_parser.dart';
import 'rsvp_service.dart';
import 'storage_service.dart';
import 'txt_parser.dart';

class AppState extends ChangeNotifier {
  final _uuid = const Uuid();

  // ─── Library ───────────────────────────────────────────────────────────────
  List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  // ─── Active reading session ────────────────────────────────────────────────
  Book? _activeBook;
  List<String> _words = [];
  int _wordIndex = 0;
  bool _isPlaying = false;
  Timer? _timer;

  Book? get activeBook => _activeBook;
  List<String> get words => _words;
  int get wordIndex => _wordIndex;
  bool get isPlaying => _isPlaying;

  // ─── Settings ──────────────────────────────────────────────────────────────
  int _wpm = 250;
  bool _adaptivePause = true;
  bool _showContext = false;
  double _fontSize = 32.0;
  bool _isFirstLaunch = false;
  int _sessionWordsRead = 0;
  int _totalWordsRead = 0;
  int _streak = 0;

  int get wpm => _wpm;
  bool get adaptivePause => _adaptivePause;
  bool get showContext => _showContext;
  double get fontSize => _fontSize;
  bool get isFirstLaunch => _isFirstLaunch;
  int get totalWordsRead => _totalWordsRead;
  int get streak => _streak;

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _books = await StorageService.loadBooks();
    _wpm = await StorageService.loadWpm();
    _adaptivePause = await StorageService.loadAdaptivePause();
    _showContext = await StorageService.loadShowContext();
    _fontSize = await StorageService.loadFontSize();
    _isFirstLaunch = await StorageService.isFirstLaunch();
    _totalWordsRead = await StorageService.loadTotalWordsRead();
    _streak = await StorageService.loadStreak();
    notifyListeners();
  }

  // ─── Import ────────────────────────────────────────────────────────────────

  Future<void> importBook(String sourcePath) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final destPath = await StorageService.importBookFile(sourcePath);
      final ext = sourcePath.split('.').last.toLowerCase();

      List<String> words;
      String title;
      String author;

      if (ext == 'epub') {
        final result = await EpubParser.parse(destPath);
        words = result.words;
        title = result.title;
        author = result.author;
      } else {
        words = await TxtParser.parse(destPath);
        title = sourcePath.split('/').last.replaceAll('.txt', '');
        author = 'Unknown';
      }

      final book = Book(
        id: _uuid.v4(),
        title: title,
        author: author,
        filePath: destPath,
        format: ext,
        totalWords: words.length,
        wordIndex: 0,
        importedAt: DateTime.now(),
      );

      _books.add(book);
      await StorageService.saveBooks(_books);
    } catch (e) {
      _error = 'Import fehlgeschlagen: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBook(Book book) async {
    _books.removeWhere((b) => b.id == book.id);
    await StorageService.saveBooks(_books);
    await StorageService.deleteBookFile(book.filePath);
    notifyListeners();
  }

  // ─── Open book ─────────────────────────────────────────────────────────────

  Future<List<String>> openBook(Book book) async {
    _loading = true;
    notifyListeners();

    try {
      final ext = book.format;
      List<String> words;
      if (ext == 'epub') {
        final result = await EpubParser.parse(book.filePath);
        words = result.words;
      } else {
        words = await TxtParser.parse(book.filePath);
      }

      final savedIndex = await StorageService.loadProgress(book.id);
      _activeBook = book.copyWith(wordIndex: savedIndex);
      _words = words;
      _wordIndex = savedIndex.clamp(0, words.length - 1);
      return words;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── RSVP Playback ────────────────────────────────────────────────────────

  void play() {
    if (_words.isEmpty) return;
    _isPlaying = true;
    _scheduleNext();
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    _timer?.cancel();
    _saveProgress();
    _flushSessionWords();
    notifyListeners();
  }

  Future<void> _flushSessionWords() async {
    if (_sessionWordsRead <= 0) return;
    final count = _sessionWordsRead;
    _sessionWordsRead = 0;
    await StorageService.addWordsReadToday(count);
    _totalWordsRead += count;
    _streak = await StorageService.loadStreak();
    notifyListeners();
  }

  void togglePlay() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_isPlaying || _wordIndex >= _words.length) {
      _isPlaying = false;
      notifyListeners();
      return;
    }
    final word = _words[_wordIndex];
    final base = RsvpService.wpmToMs(_wpm);
    final duration = RsvpService.getWordDuration(word, base, _adaptivePause);

    _timer = Timer(Duration(milliseconds: duration), () {
      if (!_isPlaying) return;
      _wordIndex++;
      _sessionWordsRead++;
      if (_wordIndex >= _words.length) {
        _isPlaying = false;
        _wordIndex = _words.length - 1;
        _saveProgress();
        notifyListeners();
        return;
      }
      notifyListeners();
      _scheduleNext();
    });
  }

  void seekToWord(int index) {
    _timer?.cancel();
    _wordIndex = index.clamp(0, _words.isNotEmpty ? _words.length - 1 : 0);
    if (_isPlaying) _scheduleNext();
    _saveProgress();
    notifyListeners();
  }

  void prevSentence() {
    final idx = RsvpService.sentenceStart(_words, _wordIndex);
    seekToWord(idx == _wordIndex ? RsvpService.sentenceStart(_words, _wordIndex - 1) : idx);
  }

  void nextSentence() => seekToWord(RsvpService.nextSentenceStart(_words, _wordIndex));

  void prevParagraph() => seekToWord(RsvpService.paragraphStart(_words, _wordIndex));

  void nextParagraph() => seekToWord(RsvpService.nextParagraphStart(_words, _wordIndex));

  Future<void> _saveProgress() async {
    if (_activeBook == null) return;
    _activeBook = _activeBook!.copyWith(wordIndex: _wordIndex);
    final idx = _books.indexWhere((b) => b.id == _activeBook!.id);
    if (idx >= 0) {
      _books[idx] = _activeBook!;
      await StorageService.saveBooks(_books);
    }
    await StorageService.saveProgress(_activeBook!.id, _wordIndex);
  }

  // ─── Settings setters ──────────────────────────────────────────────────────

  void setWpm(int v) {
    _wpm = v;
    StorageService.saveWpm(v);
    notifyListeners();
  }

  void setAdaptivePause(bool v) {
    _adaptivePause = v;
    StorageService.saveAdaptivePause(v);
    notifyListeners();
  }

  void setShowContext(bool v) {
    _showContext = v;
    StorageService.saveShowContext(v);
    notifyListeners();
  }

  void setFontSize(double v) {
    _fontSize = v;
    StorageService.saveFontSize(v);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
