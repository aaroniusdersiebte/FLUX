import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class StorageService {
  static const String _booksKey = 'books_list';
  static const String _wpmKey = 'wpm';
  static const String _adaptivePauseKey = 'adaptive_pause';
  static const String _showContextKey = 'show_context';
  static const String _fontSizeKey = 'font_size';
  static const String _firstLaunchKey = 'first_launch';
  static const String _dailyStatsKey = 'daily_stats';

  // ─── Books ─────────────────────────────────────────────────────────────────

  static Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_booksKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Book.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _booksKey,
      jsonEncode(books.map((b) => b.toJson()).toList()),
    );
  }

  static Future<void> saveProgress(String bookId, int wordIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_$bookId', wordIndex);
  }

  static Future<int> loadProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('progress_$bookId') ?? 0;
  }

  /// Copy the picked file into app documents dir and return the new path.
  static Future<String> importBookFile(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${dir.path}/books');
    if (!booksDir.existsSync()) booksDir.createSync(recursive: true);

    final fileName = sourcePath.split('/').last;
    final dest = '${booksDir.path}/$fileName';
    await File(sourcePath).copy(dest);
    return dest;
  }

  static Future<void> deleteBookFile(String filePath) async {
    final f = File(filePath);
    if (f.existsSync()) await f.delete();
  }

  // ─── Word Cache ────────────────────────────────────────────────────────────

  static Future<void> saveWordCache(String bookId, List<String> words) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cache/$bookId.words');
    await file.parent.create(recursive: true);
    await file.writeAsString(words.join('\n'));
  }

  static Future<List<String>?> loadWordCache(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cache/$bookId.words');
    if (!await file.exists()) return null;
    final text = await file.readAsString();
    if (text.isEmpty) return null;
    return text.split('\n');
  }

  static Future<void> deleteWordCache(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cache/$bookId.words');
    if (await file.exists()) await file.delete();
  }

  // ─── Settings ──────────────────────────────────────────────────────────────

  static Future<int> loadWpm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_wpmKey) ?? 250;
  }

  static Future<void> saveWpm(int wpm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wpmKey, wpm);
  }

  static Future<bool> loadAdaptivePause() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adaptivePauseKey) ?? true;
  }

  static Future<void> saveAdaptivePause(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adaptivePauseKey, v);
  }

  static Future<bool> loadShowContext() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showContextKey) ?? false;
  }

  static Future<void> saveShowContext(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showContextKey, v);
  }

  static Future<double> loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 32.0;
  }

  static Future<void> saveFontSize(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, v);
  }

  // ─── Analytics ─────────────────────────────────────────────────────────────

  static Future<Map<String, int>> loadDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyStatsKey);
    if (raw == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> addWordsReadToday(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyStatsKey);
    final Map<String, dynamic> stats =
        raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
    final today = _dateKey(DateTime.now());
    stats[today] = (stats[today] as int? ?? 0) + count;
    await prefs.setString(_dailyStatsKey, jsonEncode(stats));
  }

  static Future<int> loadTotalWordsRead() async {
    final stats = await loadDailyStats();
    return stats.values.fold<int>(0, (sum, v) => sum + v);
  }

  static Future<int> loadStreak() async {
    final stats = await loadDailyStats();
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final key = _dateKey(now.subtract(Duration(days: i)));
      if ((stats[key] ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getBool(_firstLaunchKey) ?? true;
    if (first) await prefs.setBool(_firstLaunchKey, false);
    return first;
  }

  // ─── Streak Mode ───────────────────────────────────────────────────────────

  static Future<bool> loadStreakModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('streak_mode_enabled') ?? true;
  }

  static Future<void> saveStreakModeEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_mode_enabled', v);
  }

  static Future<int> loadTodayWords() async {
    final stats = await loadDailyStats();
    return stats[_dateKey(DateTime.now())] ?? 0;
  }

  static Future<int> loadGoalTierForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('streak_goal_date') ?? '';
    final today = _dateKey(DateTime.now());
    if (savedDate != today) {
      await prefs.setInt('streak_goal_tier', 0);
      await prefs.setString('streak_goal_date', today);
      return 0;
    }
    return prefs.getInt('streak_goal_tier') ?? 0;
  }

  static Future<void> saveGoalTier(int tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak_goal_tier', tier);
    await prefs.setString('streak_goal_date', _dateKey(DateTime.now()));
  }

  // ─── Theme ─────────────────────────────────────────────────────────────────

  static Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_dark_mode') ?? true;
  }

  static Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  // ─── Vibration ─────────────────────────────────────────────────────────────

  static Future<bool> loadVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('vibration_enabled') ?? false;
  }

  static Future<void> saveVibrationEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', v);
  }

  // ─── Accent Color ──────────────────────────────────────────────────────────

  static Future<int> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('accent_color') ?? 0xFFFFBF00;
  }

  static Future<void> saveAccentColor(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', v);
  }

  // ─── ORP Highlight ─────────────────────────────────────────────────────────

  static Future<bool> loadHighlightOrp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('highlight_orp') ?? true;
  }

  static Future<void> saveHighlightOrp(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highlight_orp', v);
  }

  // ─── Font Family ───────────────────────────────────────────────────────────

  static Future<String> loadFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('font_family') ?? 'jetbrains_mono';
  }

  static Future<void> saveFontFamily(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_family', v);
  }

  // ─── App Language ──────────────────────────────────────────────────────────

  static Future<String> loadAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_language') ?? 'en';
  }

  static Future<void> saveAppLanguage(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', v);
  }

  // ─── Streak Notification ───────────────────────────────────────────────────

  static Future<bool> loadStreakNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('streak_notification_enabled') ?? false;
  }

  static Future<void> saveStreakNotificationEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_notification_enabled', v);
  }

  static Future<int> loadStreakNotificationHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('streak_notification_hour') ?? 20;
  }

  static Future<void> saveStreakNotificationHour(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak_notification_hour', v);
  }
}
