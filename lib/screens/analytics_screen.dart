import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/storage_service.dart';
import '../theme/terminal_theme.dart';

// ─── Localization ─────────────────────────────────────────────────────────────

class _L10n {
  static const Map<String, Map<String, String>> _s = {
    'de': {
      'LAST_7': 'LETZTE 7 TAGE',
      'DAILY': 'TAGESVERLAUF',
      'TOTAL_LABEL': 'GESAMT GELESEN',
      'WORDS': 'WÖRTER',
      'NO_DATA': 'noch keine Lesedaten',
    },
    'en': {
      'LAST_7': 'LAST 7 DAYS',
      'DAILY': 'DAILY BREAKDOWN',
      'TOTAL_LABEL': 'TOTAL READ',
      'WORDS': 'WORDS',
      'NO_DATA': 'no reading data yet',
    },
  };

  static const Map<String, List<String>> _weekdays = {
    'de': ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'],
    'en': ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'],
  };

  static String t(String lang, String key) => _s[lang]?[key] ?? key;
  static List<String> weekdays(String lang) => _weekdays[lang] ?? _weekdays['en']!;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        appBar: AppBar(title: Text(state.appLanguage == 'de' ? 'STATISTIKEN' : 'ANALYTICS')),
        body: AnalyticsBody(lang: state.appLanguage),
      ),
    );
  }
}

class AnalyticsBody extends StatefulWidget {
  final String lang;
  const AnalyticsBody({super.key, required this.lang});

  @override
  State<AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends State<AnalyticsBody> {
  Map<String, int> _dailyStats = {};
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AnalyticsBody old) {
    super.didUpdateWidget(old);
    // Reload if language changes (no data reload needed, just rebuild)
  }

  Future<void> _load() async {
    final stats = await StorageService.loadDailyStats();
    final streak = await StorageService.loadStreak();
    if (mounted) setState(() { _dailyStats = stats; _streak = streak; _loading = false; });
  }

  int get _totalWords => _dailyStats.values.fold(0, (s, v) => s + v);

  List<_DayStat> get _last7 {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return _DayStat(date: day, count: _dailyStats[key] ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.amber, strokeWidth: 1.5));
    }
    return _buildBody(colors);
  }

  Widget _buildBody(AppColors colors) {
    final days = _last7;
    final total = _totalWords;
    final maxCount = days.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);
    final lang = widget.lang;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        _TotalStat(total: total, streak: _streak, colors: colors, lang: lang),
        const SizedBox(height: 36),
        Text(_L10n.t(lang, 'LAST_7'),
            style: AppFont.get(colors.fontFamily,
                color: colors.amber, fontSize: 10, letterSpacing: 3.5, weight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _BarChart(days: days, colors: colors, lang: lang),
        ),
        const SizedBox(height: 32),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 24),
        Text(_L10n.t(lang, 'DAILY'),
            style: AppFont.get(colors.fontFamily,
                color: colors.amber, fontSize: 10, letterSpacing: 3.5, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...days.reversed.where((d) => d.count > 0).map((d) => _DayRow(stat: d, maxCount: maxCount, colors: colors, lang: lang)),
        if (days.every((d) => d.count == 0))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_L10n.t(lang, 'NO_DATA'),
                style: AppFont.get(colors.fontFamily, color: colors.textMuted, fontSize: 11)),
          ),
      ],
    );
  }
}

class _TotalStat extends StatelessWidget {
  final int total;
  final int streak;
  final AppColors colors;
  final String lang;
  const _TotalStat({required this.total, required this.streak, required this.colors, required this.lang});

  @override
  Widget build(BuildContext context) {
    final formatted = _fmt(total);
    final streakLabel = lang == 'de'
        ? '$streak TAG${streak == 1 ? '' : 'E'} STREAK'
        : '$streak DAY${streak == 1 ? '' : 'S'} STREAK';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(border: Border.all(color: colors.amber.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_L10n.t(lang, 'TOTAL_LABEL'),
              style: AppFont.get(colors.fontFamily,
                  color: colors.textMuted, fontSize: 9, letterSpacing: 3)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatted,
                  style: AppFont.get(colors.fontFamily,
                      color: colors.amber, fontSize: 36, weight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(_L10n.t(lang, 'WORDS'),
                  style: AppFont.get(colors.fontFamily,
                      color: colors.textMuted, fontSize: 12, letterSpacing: 2)),
            ],
          ),
          if (streak > 0) ...[
            const SizedBox(height: 12),
            Text(streakLabel,
                style: AppFont.get(colors.fontFamily,
                    color: colors.amber, fontSize: 11, letterSpacing: 2, weight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return n.toString();
  }
}

class _DayStat {
  final DateTime date;
  final int count;
  const _DayStat({required this.date, required this.count});
}

class _BarChart extends StatelessWidget {
  final List<_DayStat> days;
  final AppColors colors;
  final String lang;
  const _BarChart({required this.days, required this.colors, required this.lang});

  @override
  Widget build(BuildContext context) {
    final maxCount = days.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);
    final todayKey = DateTime.now().weekday;
    return CustomPaint(
      painter: _BarChartPainter(days: days, maxCount: maxCount, todayWeekday: todayKey, colors: colors, lang: lang),
      child: const SizedBox.expand(),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_DayStat> days;
  final int maxCount;
  final int todayWeekday;
  final AppColors colors;
  final String lang;

  const _BarChartPainter({
    required this.days,
    required this.maxCount,
    required this.todayWeekday,
    required this.colors,
    required this.lang,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = colors.amber.withValues(alpha: 0.7);
    final todayPaint = Paint()..color = colors.amber;
    final gridPaint = Paint()
      ..color = colors.border
      ..strokeWidth = 0.5;
    final labelStyle = AppFont.get(colors.fontFamily,
        color: colors.textMuted, fontSize: 9, letterSpacing: 1);
    final countStyle = AppFont.get(colors.fontFamily, color: colors.amber, fontSize: 8);
    final weekdays = _L10n.weekdays(lang);

    const bottomPad = 24.0;
    const topPad = 16.0;
    final chartH = size.height - bottomPad - topPad;
    final barW = (size.width / days.length) * 0.45;
    final slotW = size.width / days.length;

    canvas.drawLine(Offset(0, topPad), Offset(size.width, topPad), gridPaint);

    for (int i = 0; i < days.length; i++) {
      final d = days[i];
      final cx = slotW * i + slotW / 2;
      final isToday = d.date.weekday == todayWeekday && d.date.difference(DateTime.now()).inDays.abs() < 1;
      final ratio = maxCount > 0 ? d.count / maxCount : 0.0;
      final barH = (chartH * ratio).clamp(2.0, chartH);
      final top = topPad + chartH - barH;

      final rect = Rect.fromLTWH(cx - barW / 2, top, barW, barH);
      canvas.drawRect(rect, isToday ? todayPaint : barPaint);

      if (d.count > 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${d.count}', style: countStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, top - tp.height - 2));
      }

      final label = weekdays[(d.date.weekday - 1) % 7];
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: isToday ? labelStyle.copyWith(color: colors.amber) : labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - bottomPad + 6));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.maxCount != maxCount || old.days != days || old.colors != colors || old.lang != lang;
}

class _DayRow extends StatelessWidget {
  final _DayStat stat;
  final int maxCount;
  final AppColors colors;
  final String lang;
  const _DayRow({required this.stat, required this.maxCount, required this.colors, required this.lang});

  @override
  Widget build(BuildContext context) {
    final weekdays = _L10n.weekdays(lang);
    final label = weekdays[(stat.date.weekday - 1) % 7];
    final dateStr =
        '${stat.date.day.toString().padLeft(2, '0')}.${stat.date.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label  $dateStr',
              style: AppFont.get(colors.fontFamily, color: colors.textMuted, fontSize: 11)),
          const SizedBox(width: 16),
          Expanded(
            child: LinearProgressIndicator(
              value: maxCount > 0 ? stat.count / maxCount : 0.0,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(colors.amberDim),
              minHeight: 1,
            ),
          ),
          const SizedBox(width: 12),
          Text('${stat.count} W',
              style: AppFont.get(colors.fontFamily, color: colors.textPrimary, fontSize: 11)),
        ],
      ),
    );
  }
}
