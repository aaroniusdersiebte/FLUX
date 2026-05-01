import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../theme/terminal_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ANALYTICS')),
      body: const AnalyticsBody(),
    );
  }
}

class AnalyticsBody extends StatefulWidget {
  const AnalyticsBody({super.key});

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        _TotalStat(total: total, streak: _streak, colors: colors),
        const SizedBox(height: 36),
        Text('LETZTE 7 TAGE',
            style: GoogleFonts.jetBrainsMono(
                color: colors.amber, fontSize: 10, letterSpacing: 3.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _BarChart(days: days, colors: colors),
        ),
        const SizedBox(height: 32),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 24),
        Text('TAGESVERLAUF',
            style: GoogleFonts.jetBrainsMono(
                color: colors.amber, fontSize: 10, letterSpacing: 3.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...days.reversed.where((d) => d.count > 0).map((d) => _DayRow(stat: d, maxCount: maxCount, colors: colors)),
        if (days.every((d) => d.count == 0))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('noch keine Lesedaten',
                style: GoogleFonts.jetBrainsMono(color: colors.textMuted, fontSize: 11)),
          ),
      ],
    );
  }
}

class _TotalStat extends StatelessWidget {
  final int total;
  final int streak;
  final AppColors colors;
  const _TotalStat({required this.total, required this.streak, required this.colors});

  @override
  Widget build(BuildContext context) {
    final formatted = _fmt(total);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(border: Border.all(color: colors.amber.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GESAMT GELESEN',
              style: GoogleFonts.jetBrainsMono(
                  color: colors.textMuted, fontSize: 9, letterSpacing: 3)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatted,
                  style: GoogleFonts.jetBrainsMono(
                      color: colors.amber, fontSize: 36, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('WÖRTER',
                  style: GoogleFonts.jetBrainsMono(
                      color: colors.textMuted, fontSize: 12, letterSpacing: 2)),
            ],
          ),
          if (streak > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('$streak TAG${streak == 1 ? '' : 'E'} STREAK',
                    style: GoogleFonts.jetBrainsMono(
                        color: colors.amber,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600)),
              ],
            ),
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

const _weekdayShort = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];

class _BarChart extends StatelessWidget {
  final List<_DayStat> days;
  final AppColors colors;
  const _BarChart({required this.days, required this.colors});

  @override
  Widget build(BuildContext context) {
    final maxCount = days.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);
    final todayKey = DateTime.now().weekday;
    return CustomPaint(
      painter: _BarChartPainter(days: days, maxCount: maxCount, todayWeekday: todayKey, colors: colors),
      child: const SizedBox.expand(),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_DayStat> days;
  final int maxCount;
  final int todayWeekday;
  final AppColors colors;

  const _BarChartPainter({
    required this.days,
    required this.maxCount,
    required this.todayWeekday,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = colors.amber.withValues(alpha: 0.7);
    final todayPaint = Paint()..color = colors.amber;
    final gridPaint = Paint()
      ..color = colors.border
      ..strokeWidth = 0.5;
    final labelStyle = GoogleFonts.jetBrainsMono(
        color: colors.textMuted, fontSize: 9, letterSpacing: 1);
    final countStyle = GoogleFonts.jetBrainsMono(
        color: colors.amber, fontSize: 8);

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

      final label = _weekdayShort[(d.date.weekday - 1) % 7];
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: isToday
                ? labelStyle.copyWith(color: colors.amber)
                : labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - bottomPad + 6));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.maxCount != maxCount || old.days != days || old.colors != colors;
}

class _DayRow extends StatelessWidget {
  final _DayStat stat;
  final int maxCount;
  final AppColors colors;
  const _DayRow({required this.stat, required this.maxCount, required this.colors});

  @override
  Widget build(BuildContext context) {
    final label = _weekdayShort[(stat.date.weekday - 1) % 7];
    final dateStr =
        '${stat.date.day.toString().padLeft(2, '0')}.${stat.date.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label  $dateStr',
              style: GoogleFonts.jetBrainsMono(
                  color: colors.textMuted, fontSize: 11)),
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
              style: GoogleFonts.jetBrainsMono(
                  color: colors.textPrimary, fontSize: 11)),
        ],
      ),
    );
  }
}
