import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import '../models/book.dart';
import 'epub_parser.dart';
import 'notification_service.dart';
import 'pdf_parser.dart';
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
  bool _isDarkMode = true;
  bool _vibrationEnabled = true;
  Color _accentColor = const Color(0xFFFFBF00);
  bool _highlightOrp = true;
  String _fontFamily = 'jetbrains_mono';
  String _appLanguage = 'en';
  bool _streakNotificationEnabled = false;
  int _streakNotificationHour = 20;
  bool _slowStart = true;
  bool _tutorialDone = false;
  int _tutorialStep = -1; // -1 = not active
  int _sessionWordCount = 0;
  DateTime? _sessionStartTime;

  // ─── Streak Mode ───────────────────────────────────────────────────────────
  static const List<int> _goals = [500, 1000, 1500, 2000, 3000, 5000];
  bool _streakModeEnabled = true;
  int _dailyWordsRead = 0;
  int _dailyGoalTier = 0;
  int? _pendingMilestone;

  int get wpm => _wpm;
  bool get adaptivePause => _adaptivePause;
  bool get showContext => _showContext;
  double get fontSize => _fontSize;
  bool get isFirstLaunch => _isFirstLaunch;
  int get totalWordsRead => _totalWordsRead;
  int get streak => _streak;
  bool get streakModeEnabled => _streakModeEnabled;
  int get dailyWordsRead => _dailyWordsRead;
  int get dailyGoalTier => _dailyGoalTier;
  int? get pendingMilestone => _pendingMilestone;
  bool get isDarkMode => _isDarkMode;
  bool get vibrationEnabled => _vibrationEnabled;
  Color get accentColor => _accentColor;
  bool get highlightOrp => _highlightOrp;
  String get fontFamily => _fontFamily;
  String get appLanguage => _appLanguage;
  bool get streakNotificationEnabled => _streakNotificationEnabled;
  int get streakNotificationHour => _streakNotificationHour;
  bool get slowStart => _slowStart;
  bool get tutorialDone => _tutorialDone;
  bool get isTutorialActive => _tutorialStep >= 0;
  int get tutorialStep => _tutorialStep;

  static int _tierEnd(int tier) {
    if (tier < _goals.length) return _goals[tier];
    return 5000 * (tier - _goals.length + 2);
  }

  double get goalProgress {
    final tierStart = _dailyGoalTier == 0 ? 0 : _tierEnd(_dailyGoalTier - 1);
    final tierEnd = _tierEnd(_dailyGoalTier);
    return ((_dailyWordsRead - tierStart) / (tierEnd - tierStart)).clamp(0.0, 1.0);
  }

  static int goalTierStart(int milestoneTarget) {
    final idx = _goals.indexOf(milestoneTarget);
    if (idx > 0) return _goals[idx - 1];
    if (idx == 0) return 0;
    return milestoneTarget - 5000;
  }

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
    _streakModeEnabled = await StorageService.loadStreakModeEnabled();
    _dailyWordsRead = await StorageService.loadTodayWords();
    _dailyGoalTier = await StorageService.loadGoalTierForToday();
    _isDarkMode = await StorageService.loadThemeMode();
    _vibrationEnabled = await StorageService.loadVibrationEnabled();
    _accentColor = Color(await StorageService.loadAccentColor());
    _highlightOrp = await StorageService.loadHighlightOrp();
    _fontFamily = await StorageService.loadFontFamily();
    _appLanguage = await StorageService.loadAppLanguage();
    _streakNotificationEnabled = await StorageService.loadStreakNotificationEnabled();
    _streakNotificationHour = await StorageService.loadStreakNotificationHour();
    _slowStart = await StorageService.loadSlowStart();
    _tutorialDone = await StorageService.loadTutorialDone();
    while (_dailyWordsRead >= _tierEnd(_dailyGoalTier)) {
      _dailyGoalTier++;
    }
    notifyListeners();
  }

  // ─── Import ────────────────────────────────────────────────────────────────

  Future<List<String>> _parseBook(Book book) async {
    if (book.format == 'epub') {
      final result = await EpubParser.parse(book.filePath);
      return result.words;
    } else if (book.format == 'pdf') {
      return PdfParser.parse(book.filePath);
    } else {
      return TxtParser.parse(book.filePath);
    }
  }

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
      List<BookChapter> chapters = [];

      if (ext == 'epub') {
        final result = await EpubParser.parse(destPath);
        words = result.words;
        title = result.title;
        author = result.author;
        chapters = result.chapters;
      } else if (ext == 'pdf') {
        words = await PdfParser.parse(destPath);
        title = sourcePath.split('/').last.replaceAll('.pdf', '');
        author = 'Unknown';
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
        chapters: chapters,
      );

      _books.add(book);
      await StorageService.saveBooks(_books);
      await StorageService.saveWordCache(book.id, words);
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
    await StorageService.deleteWordCache(book.id);
    notifyListeners();
  }

  // ─── Open book ─────────────────────────────────────────────────────────────

  Future<List<String>> openBook(Book book) async {
    _loading = true;
    notifyListeners();

    try {
      List<String>? cached = await StorageService.loadWordCache(book.id);
      List<String> words;
      if (cached != null) {
        words = cached;
      } else {
        words = await _parseBook(book);
        await StorageService.saveWordCache(book.id, words);
      }

      final savedIndex = await StorageService.loadProgress(book.id);
      _activeBook = book.copyWith(wordIndex: savedIndex);
      _words = words;
      _wordIndex = savedIndex.clamp(0, words.length - 1);

      // Sync _books so the library card shows correct progress immediately
      final idx = _books.indexWhere((b) => b.id == book.id);
      if (idx >= 0) _books[idx] = _books[idx].copyWith(wordIndex: _wordIndex);

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
    _sessionWordCount = 0;
    _sessionStartTime = DateTime.now();
    _scheduleNext();
    _vibrate(duration: 30);
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    _timer?.cancel();
    _saveProgress();
    _flushSessionWords();
    _vibrate(duration: 50);
    notifyListeners();
  }

  void vibrateMilestone() => _vibrate(pattern: [0, 80, 60, 80]);

  void _vibrate({int? duration, List<int>? pattern}) {
    if (!_vibrationEnabled) return;
    Vibration.hasVibrator().then((has) {
      if (has != true) return;
      if (pattern != null) {
        Vibration.vibrate(pattern: pattern);
      } else {
        Vibration.vibrate(duration: duration ?? 40);
      }
    });
  }

  Future<void> _flushSessionWords() async {
    if (_sessionWordsRead <= 0 || _activeBook?.id == '__demo__') return;
    final count = _sessionWordsRead;
    _sessionWordsRead = 0;
    await StorageService.addWordsReadToday(count);
    _totalWordsRead += count;
    _streak = await StorageService.loadStreak();
    if (_sessionStartTime != null && _activeBook != null) {
      final durationMs = DateTime.now().difference(_sessionStartTime!).inMilliseconds;
      if (durationMs > 0) {
        final effectiveWpm = (count / durationMs * 60000).round();
        if (effectiveWpm > 0 && effectiveWpm < 2000) {
          await StorageService.saveWpmSession(
            wpm: effectiveWpm,
            words: count,
            bookId: _activeBook!.id,
          );
        }
      }
      _sessionStartTime = null;
    }
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
    int effectiveBase = base;
    if (_slowStart && _sessionWordCount < 20) {
      final t = _sessionWordCount / 20.0;
      final eased = 1.0 - math.pow(1.0 - t, 3).toDouble();
      final factor = 2.0 - eased;
      effectiveBase = (base * factor).round();
    }
    final duration = RsvpService.getWordDuration(word, effectiveBase, _adaptivePause);

    _timer = Timer(Duration(milliseconds: duration), () {
      if (!_isPlaying) return;
      _wordIndex++;
      _sessionWordsRead++;
      _sessionWordCount++;
      _dailyWordsRead++;
      if (_wordIndex >= _words.length) {
        _isPlaying = false;
        _wordIndex = _words.length - 1;
        _vibrate(pattern: [0, 80, 100, 180]);
        _saveProgress();
        _flushSessionWords();
        notifyListeners();
        return;
      }
      if (_streakModeEnabled && _dailyWordsRead >= _tierEnd(_dailyGoalTier)) {
        _pendingMilestone = _tierEnd(_dailyGoalTier);
        _dailyGoalTier++;
        StorageService.saveGoalTier(_dailyGoalTier);
        _isPlaying = false;
        _timer?.cancel();
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
    if (_activeBook == null || _activeBook!.id == '__demo__') return;
    _activeBook = _activeBook!.copyWith(wordIndex: _wordIndex);
    final idx = _books.indexWhere((b) => b.id == _activeBook!.id);
    if (idx >= 0) {
      _books[idx] = _activeBook!;
      await StorageService.saveBooks(_books);
    }
    await StorageService.saveProgress(_activeBook!.id, _wordIndex);
  }

  // ─── Book management ───────────────────────────────────────────────────────

  Future<void> updateBookMetadata(Book book, String title, String author) async {
    final idx = _books.indexWhere((b) => b.id == book.id);
    if (idx < 0) return;
    _books[idx] = _books[idx].copyWith(title: title.trim(), author: author.trim());
    if (_activeBook?.id == book.id) {
      _activeBook = _activeBook!.copyWith(title: title.trim(), author: author.trim());
    }
    await StorageService.saveBooks(_books);
    notifyListeners();
  }

  Future<void> resetBook(Book book) async {
    final idx = _books.indexWhere((b) => b.id == book.id);
    if (idx < 0) return;
    _books[idx] = _books[idx].copyWith(wordIndex: 0);
    if (_activeBook?.id == book.id) {
      _activeBook = _activeBook!.copyWith(wordIndex: 0);
      _wordIndex = 0;
    }
    await StorageService.saveBooks(_books);
    await StorageService.saveProgress(book.id, 0);
    notifyListeners();
  }

  // ─── Settings setters ──────────────────────────────────────────────────────

  void setWpm(int v) {
    _wpm = v;
    StorageService.saveWpm(v);
    _vibrate(duration: 15);
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

  void setStreakModeEnabled(bool v) {
    _streakModeEnabled = v;
    StorageService.saveStreakModeEnabled(v);
    notifyListeners();
  }

  void setDarkMode(bool v) {
    _isDarkMode = v;
    StorageService.saveThemeMode(v);
    notifyListeners();
  }

  void setVibrationEnabled(bool v) {
    _vibrationEnabled = v;
    StorageService.saveVibrationEnabled(v);
    notifyListeners();
  }

  void setAccentColor(Color v) {
    _accentColor = v;
    StorageService.saveAccentColor(v.toARGB32());
    notifyListeners();
  }

  void setHighlightOrp(bool v) {
    _highlightOrp = v;
    StorageService.saveHighlightOrp(v);
    notifyListeners();
  }

  void setFontFamily(String v) {
    _fontFamily = v;
    StorageService.saveFontFamily(v);
    notifyListeners();
  }

  void setAppLanguage(String v) {
    _appLanguage = v;
    StorageService.saveAppLanguage(v);
    notifyListeners();
  }

  void setStreakNotificationEnabled(bool v) {
    _streakNotificationEnabled = v;
    StorageService.saveStreakNotificationEnabled(v);
    if (v) {
      NotificationService.scheduleStreakReminder(_streakNotificationHour, _appLanguage);
    } else {
      NotificationService.cancelStreakReminder();
    }
    notifyListeners();
  }

  void setSlowStart(bool v) {
    _slowStart = v;
    StorageService.saveSlowStart(v);
    notifyListeners();
  }

  void vibrateBack() => _vibrate(duration: 25);

  // ─── Tutorial ──────────────────────────────────────────────────────────────

  static const String _demoText =
      'FLUX Speed Reading. Welcome. RSVP stands for Rapid Serial Visual '
      'Presentation. Words appear one at a time at a fixed focal point. '
      'Your eyes stay still. Your brain reads faster. Scientists found that '
      'most reading time is wasted on eye movement. You scan across a page '
      'left to right again and again. FLUX removes that wasted motion. '
      'You focus on a single spot. Words flow to you instead. Start at two '
      'hundred words per minute. That feels comfortable. Three hundred feels '
      'fast. Four hundred feels intense. Five hundred once felt impossible. '
      'It no longer does. Your brain adapts. Every session makes you sharper. '
      'Swipe left to jump back one sentence. Swipe right to jump one sentence '
      'forward. Swipe up to read faster. Swipe down to slow down. Tap once to '
      'pause. Tap again to continue. The more you practice the more natural it '
      'becomes. Speed reading is a skill. Skills can be trained. You are '
      'already reading faster than before. Welcome to FLUX.';

  void openDemoBook() {
    final words = _demoText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    _activeBook = Book(
      id: '__demo__',
      title: 'FLUX DEMO',
      author: 'FLUX',
      filePath: '',
      format: 'txt',
      totalWords: words.length,
      wordIndex: 0,
      importedAt: DateTime.now(),
    );
    _words = words;
    _wordIndex = 0;
    notifyListeners();
  }

  void startTutorial() {
    _tutorialStep = 0;
    notifyListeners();
  }

  void advanceTutorial() {
    _tutorialStep++;
    notifyListeners();
  }

  void endTutorial() {
    _tutorialDone = true;
    _tutorialStep = -1;
    StorageService.saveTutorialDone();
    notifyListeners();
  }

  void setTutorialDone() {
    _tutorialDone = true;
    StorageService.saveTutorialDone();
    notifyListeners();
  }

  void setStreakNotificationHour(int v) {
    _streakNotificationHour = v.clamp(0, 23);
    StorageService.saveStreakNotificationHour(_streakNotificationHour);
    if (_streakNotificationEnabled) {
      NotificationService.scheduleStreakReminder(_streakNotificationHour, _appLanguage);
    }
    notifyListeners();
  }

  void clearMilestone() {
    _pendingMilestone = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
