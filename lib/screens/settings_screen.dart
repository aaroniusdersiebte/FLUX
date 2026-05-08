import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/rsvp_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/amber_slider.dart';
import '../widgets/rsvp_display.dart';
import '../nav_key.dart';

// ─── Localization ─────────────────────────────────────────────────────────────

class _L10n {
  static const Map<String, Map<String, String>> _s = {
    'de': {
      'SETTINGS': 'EINSTELLUNGEN',
      'SPEED': 'GESCHWINDIGKEIT',
      'WPM': 'WPM',
      'ADAPTIVE_PAUSE': 'ADAPTIVE PAUSE',
      'ADAPTIVE_PAUSE_SUB': 'Längere Pausen bei langen Wörtern & Satzzeichen',
      'SLOW_START': 'LANGSAMER START',
      'SLOW_START_SUB': 'Beginnt langsam, steigert sich über 20 Wörter auf Ziel-WPM',
      'DISPLAY': 'ANZEIGE',
      'FONT_SIZE': 'SCHRIFTGRÖSSE',
      'CONTEXT_WORDS': 'KONTEXTWÖRTER',
      'CONTEXT_WORDS_SUB': 'Vorheriges / nächstes Wort bei 30% Deckkraft',
      'LIGHT_MODE': 'HELLMODUS',
      'LIGHT_MODE_SUB': 'Helles Erscheinungsbild (Standard: dunkel)',
      'ACCENT_COLOR': 'AKZENTFARBE',
      'ORP_HIGHLIGHT': 'ORP-BUCHSTABE HERVORHEBEN',
      'ORP_HIGHLIGHT_SUB': 'Betonter Buchstabe in Akzentfarbe',
      'FONT': 'SCHRIFT',
      'PREVIEW': 'VORSCHAU',
      'GOALS': 'ZIELE',
      'STREAK_MODE': 'STREAK-MODUS',
      'STREAK_MODE_SUB': 'Tägliche Wortziele: 500 → 1000 → 1500 → 2000 → 3000',
      'VIBRATION': 'VIBRATION',
      'VIBRATION_SUB': 'Vibriert beim Pausieren / Start und bei Tageszielen',
      'STREAK_REMINDER': 'STREAK-ERINNERUNG',
      'STREAK_REMINDER_SUB': 'Tägliche Benachrichtigung abends',
      'REMINDER_TIME': 'UHRZEIT',
      'LANGUAGE': 'SPRACHE',
      'LANGUAGE_SUB': 'Einstellungen auf Englisch anzeigen',
      'ABOUT': 'INFO',
      'TUTORIAL': 'TUTORIAL',
      'TUTORIAL_SUB': 'Steuerung erneut anzeigen',
      'CUSTOM_COLOR_TITLE': 'FARBE WÄHLEN',
      'APPLY': 'ÜBERNEHMEN',
      'CANCEL': 'ABBRECHEN',
    },
    'en': {
      'SETTINGS': 'SETTINGS',
      'SPEED': 'SPEED',
      'WPM': 'WPM',
      'ADAPTIVE_PAUSE': 'ADAPTIVE PAUSE',
      'ADAPTIVE_PAUSE_SUB': 'Extra delay: long words & punctuation',
      'SLOW_START': 'SLOW START',
      'SLOW_START_SUB': 'Ramps up from slow to target WPM over 20 words',
      'DISPLAY': 'DISPLAY',
      'FONT_SIZE': 'FONT SIZE',
      'CONTEXT_WORDS': 'CONTEXT WORDS',
      'CONTEXT_WORDS_SUB': 'Show prev / next word at 30% opacity',
      'LIGHT_MODE': 'LIGHT MODE',
      'LIGHT_MODE_SUB': 'Light appearance (default: dark)',
      'ACCENT_COLOR': 'ACCENT COLOR',
      'ORP_HIGHLIGHT': 'HIGHLIGHT ORP CHAR',
      'ORP_HIGHLIGHT_SUB': 'Emphasized letter in accent color',
      'FONT': 'FONT',
      'PREVIEW': 'PREVIEW',
      'GOALS': 'GOALS',
      'STREAK_MODE': 'STREAK MODE',
      'STREAK_MODE_SUB': 'Daily word goals: 500 → 1000 → 1500 → 2000 → 3000',
      'VIBRATION': 'VIBRATION',
      'VIBRATION_SUB': 'Vibrates on pause / start and at daily goals',
      'STREAK_REMINDER': 'STREAK REMINDER',
      'STREAK_REMINDER_SUB': 'Daily evening notification',
      'REMINDER_TIME': 'TIME',
      'LANGUAGE': 'LANGUAGE',
      'LANGUAGE_SUB': 'Show settings in German',
      'ABOUT': 'ABOUT',
      'TUTORIAL': 'TUTORIAL',
      'TUTORIAL_SUB': 'Show controls guide again',
      'CUSTOM_COLOR_TITLE': 'PICK COLOR',
      'APPLY': 'APPLY',
      'CANCEL': 'CANCEL',
    },
  };

  static String t(String lang, String key) => _s[lang]?[key] ?? key;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) => Scaffold(
        appBar: AppBar(
            title: Text(_L10n.t(state.appLanguage, 'SETTINGS'))),
        body: SettingsBody(lang: state.appLanguage),
      ),
    );
  }
}

class SettingsBody extends StatelessWidget {
  final String lang;
  const SettingsBody({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final l = lang;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // ── Geschwindigkeit ────────────────────────────────────────────
            _SectionLabel(_L10n.t(l, 'SPEED'), colors),
            const SizedBox(height: 12),
            AmberSlider(
              label: _L10n.t(l, 'WPM'),
              value: state.wpm.toDouble(),
              min: 100,
              max: 1000,
              divisions: 90,
              valueLabel: (v) => '${v.round()} wpm',
              onChanged: (v) => state.setWpm(v.round()),
            ),
            const SizedBox(height: 16),
            _Toggle(
              label: _L10n.t(l, 'ADAPTIVE_PAUSE'),
              subtitle: _L10n.t(l, 'ADAPTIVE_PAUSE_SUB'),
              value: state.adaptivePause,
              onChanged: state.setAdaptivePause,
              colors: colors,
            ),
            const SizedBox(height: 16),
            _Toggle(
              label: _L10n.t(l, 'SLOW_START'),
              subtitle: _L10n.t(l, 'SLOW_START_SUB'),
              value: state.slowStart,
              onChanged: state.setSlowStart,
              colors: colors,
            ),
            _divider(colors),

            // ── Anzeige ────────────────────────────────────────────────────
            _SectionLabel(_L10n.t(l, 'DISPLAY'), colors),
            const SizedBox(height: 12),
            AmberSlider(
              label: _L10n.t(l, 'FONT_SIZE'),
              value: state.fontSize,
              min: 18,
              max: 56,
              divisions: 38,
              valueLabel: (v) => '${v.round()} px',
              onChanged: state.setFontSize,
            ),
            const SizedBox(height: 16),
            _Toggle(
              label: _L10n.t(l, 'CONTEXT_WORDS'),
              subtitle: _L10n.t(l, 'CONTEXT_WORDS_SUB'),
              value: state.showContext,
              onChanged: state.setShowContext,
              colors: colors,
            ),
            const SizedBox(height: 16),
            _Toggle(
              label: _L10n.t(l, 'LIGHT_MODE'),
              subtitle: _L10n.t(l, 'LIGHT_MODE_SUB'),
              value: !state.isDarkMode,
              onChanged: (v) => state.setDarkMode(!v),
              colors: colors,
            ),
            _divider(colors),

            // ── Akzentfarbe ────────────────────────────────────────────────
            _SectionLabel(_L10n.t(l, 'ACCENT_COLOR'), colors),
            const SizedBox(height: 14),
            _ColorPicker(
              current: state.accentColor,
              onChanged: state.setAccentColor,
              colors: colors,
              lang: l,
            ),
            const SizedBox(height: 16),
            _Toggle(
              label: _L10n.t(l, 'ORP_HIGHLIGHT'),
              subtitle: _L10n.t(l, 'ORP_HIGHLIGHT_SUB'),
              value: state.highlightOrp,
              onChanged: state.setHighlightOrp,
              colors: colors,
            ),
            _divider(colors),

            // ── Schrift ────────────────────────────────────────────────────
            _SectionLabel(_L10n.t(l, 'FONT'), colors),
            const SizedBox(height: 14),
            _FontPicker(
              current: state.fontFamily,
              onChanged: state.setFontFamily,
              colors: colors,
            ),
            _divider(colors),

            // ── Vorschau ───────────────────────────────────────────────────
            _SectionLabel(_L10n.t(l, 'PREVIEW'), colors),
            const SizedBox(height: 16),
            _RsvpPreview(state: state, colors: colors),
            _divider(colors),

            // ── Ziele ──────────────────────────────────────────────────────
            _SectionLabel(_L10n.t(l, 'GOALS'), colors),
            const SizedBox(height: 12),
            _Toggle(
              label: _L10n.t(l, 'STREAK_MODE'),
              subtitle: _L10n.t(l, 'STREAK_MODE_SUB'),
              value: state.streakModeEnabled,
              onChanged: state.setStreakModeEnabled,
              colors: colors,
            ),
            const SizedBox(height: 16),
            _Toggle(
              label: _L10n.t(l, 'VIBRATION'),
              subtitle: _L10n.t(l, 'VIBRATION_SUB'),
              value: state.vibrationEnabled,
              onChanged: state.setVibrationEnabled,
              colors: colors,
            ),
            const SizedBox(height: 16),
            _Toggle(
              label: _L10n.t(l, 'STREAK_REMINDER'),
              subtitle: _L10n.t(l, 'STREAK_REMINDER_SUB'),
              value: state.streakNotificationEnabled,
              onChanged: state.setStreakNotificationEnabled,
              colors: colors,
            ),
            if (state.streakNotificationEnabled) ...[
              const SizedBox(height: 12),
              _TimeRow(
                label: _L10n.t(l, 'REMINDER_TIME'),
                hour: state.streakNotificationHour,
                onDecrement: () => state.setStreakNotificationHour(state.streakNotificationHour - 1),
                onIncrement: () => state.setStreakNotificationHour(state.streakNotificationHour + 1),
                colors: colors,
              ),
            ],
            _divider(colors),

            // ── Sprache ────────────────────────────────────────────────────
            _Toggle(
              label: _L10n.t(l, 'LANGUAGE'),
              subtitle: _L10n.t(l, 'LANGUAGE_SUB'),
              value: l == 'en',
              onChanged: (v) => state.setAppLanguage(v ? 'en' : 'de'),
              colors: colors,
            ),
            _divider(colors),

            // ── Tutorial ───────────────────────────────────────────────────
            _divider(colors),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                appNavigatorKey.currentState
                    ?.popUntil((route) => route.isFirst);
                context.read<AppState>().startTutorial();
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _L10n.t(l, 'TUTORIAL'),
                          style: AppFont.get(colors.fontFamily,
                              color: colors.textPrimary,
                              fontSize: 13,
                              letterSpacing: 1.0,
                              weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _L10n.t(l, 'TUTORIAL_SUB'),
                          style: AppFont.get(colors.fontFamily,
                              color: colors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text('→',
                      style: AppFont.get(colors.fontFamily,
                          color: colors.amber, fontSize: 16)),
                ],
              ),
            ),
            _divider(colors),

            // ── Info ───────────────────────────────────────────────────────
            _SectionLabel(_L10n.t(l, 'ABOUT'), colors),
            const SizedBox(height: 8),
            Text(
              'FLUX  v1.0\nRSVP Speed Reading\nTerminal Edition',
              style: AppFont.get(colors.fontFamily,
                  color: colors.textMuted,
                  fontSize: 11,
                  height: 2.0,
                  letterSpacing: 0.5),
            ),
          ],
        );
      },
    );
  }

  Widget _divider(AppColors colors) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Divider(color: colors.border, height: 1, thickness: 1),
      );
}

// ─── Time Row ─────────────────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final String label;
  final int hour;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final AppColors colors;

  const _TimeRow({
    required this.label,
    required this.hour,
    required this.onDecrement,
    required this.onIncrement,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final clampedHour = hour.clamp(0, 23);
    return Row(
      children: [
        Text(
          label,
          style: AppFont.get(colors.fontFamily,
              color: colors.textMuted, fontSize: 11, letterSpacing: 1.0),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onDecrement,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('−',
                style: AppFont.get(colors.fontFamily,
                    color: colors.amber, fontSize: 18, weight: FontWeight.w700)),
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${clampedHour.toString().padLeft(2, '0')}:00',
            textAlign: TextAlign.center,
            style: AppFont.get(colors.fontFamily,
                color: colors.textPrimary, fontSize: 14, letterSpacing: 1.5),
          ),
        ),
        GestureDetector(
          onTap: onIncrement,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('+',
                style: AppFont.get(colors.fontFamily,
                    color: colors.amber, fontSize: 18, weight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ─── Color Picker ─────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onChanged;
  final AppColors colors;
  final String lang;

  static const _swatches = [
    (label: 'AMBER', color: Color(0xFFFFBF00)),
    (label: 'CYAN', color: Color(0xFF00FFCC)),
    (label: 'GREEN', color: Color(0xFF39FF14)),
    (label: 'RED', color: Color(0xFFFF3131)),
    (label: 'WHITE', color: Color(0xFFFFFFFF)),
    (label: 'PURPLE', color: Color(0xFF9B59B6)),
    (label: 'BLUE', color: Color(0xFF4FC3F7)),
  ];

  const _ColorPicker({
    required this.current,
    required this.onChanged,
    required this.colors,
    required this.lang,
  });

  bool get _isCustom => !_swatches.any((s) => s.color.toARGB32() == current.toARGB32());

  void _openWheelPicker(BuildContext context) {
    Color picked = current;
    final textController = TextEditingController(
      text: current.toARGB32().toRadixString(16).substring(2).toUpperCase(),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: colors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _L10n.t(lang, 'CUSTOM_COLOR_TITLE'),
                    style: AppFont.get(colors.fontFamily,
                        color: colors.amber,
                        fontSize: 10,
                        letterSpacing: 3.5,
                        weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ColorPicker(
                    pickerColor: picked,
                    onColorChanged: (c) {
                      setDialogState(() {
                        picked = c;
                        textController.text =
                            c.toARGB32().toRadixString(16).substring(2).toUpperCase();
                      });
                    },
                    enableAlpha: false,
                    labelTypes: const [],
                    pickerAreaHeightPercent: 0.6,
                    displayThumbColor: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '#',
                        style: AppFont.get(colors.fontFamily,
                            color: colors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: textController,
                          style: AppFont.get(colors.fontFamily,
                              color: colors.textPrimary,
                              fontSize: 13,
                              letterSpacing: 1.5),
                          maxLength: 6,
                          decoration: InputDecoration(
                            counterText: '',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: colors.border),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: colors.amber),
                            ),
                          ),
                          onChanged: (hex) {
                            if (hex.length == 6) {
                              final val = int.tryParse('FF$hex', radix: 16);
                              if (val != null) {
                                setDialogState(() => picked = Color(val));
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 24, height: 24, color: picked),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            _L10n.t(lang, 'CANCEL'),
                            style: AppFont.get(colors.fontFamily,
                                color: colors.textMuted,
                                fontSize: 11,
                                letterSpacing: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          onChanged(picked);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.amber),
                          ),
                          child: Text(
                            _L10n.t(lang, 'APPLY'),
                            style: AppFont.get(colors.fontFamily,
                                color: colors.amber,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ..._swatches.map((s) {
          final isSelected = !_isCustom && current.toARGB32() == s.color.toARGB32();
          return GestureDetector(
            onTap: () => onChanged(s.color),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.color,
                border: Border.all(
                  color: isSelected ? colors.textPrimary : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () => _openWheelPicker(context),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isCustom ? current : Colors.transparent,
              border: Border.all(
                color: _isCustom ? colors.textPrimary : colors.border,
                width: _isCustom ? 2.5 : 1.5,
              ),
            ),
            child: _isCustom
                ? null
                : Center(
                    child: Text('+',
                        style: AppFont.get(colors.fontFamily,
                            color: colors.amber,
                            fontSize: 16,
                            weight: FontWeight.w700)),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Font Picker ──────────────────────────────────────────────────────────────

class _FontPicker extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  final AppColors colors;

  static const _fonts = [
    ('jetbrains_mono', 'JetBrains'),
    ('roboto_mono', 'Roboto'),
    ('source_code_pro', 'Source'),
    ('space_mono', 'Space'),
    ('fira_code', 'Fira'),
    ('ibm_plex_mono', 'IBM Plex'),
    ('inconsolata', 'Inconsolata'),
    ('anonymous_pro', 'Anonymous'),
    ('share_tech_mono', 'Share Tech'),
    ('overpass_mono', 'Overpass'),
  ];

  const _FontPicker({
    required this.current,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fonts.map(((entry) {
        final key = entry.$1;
        final label = entry.$2;
        final isSelected = current == key;
        return GestureDetector(
          onTap: () => onChanged(key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? colors.amber : colors.border,
              ),
            ),
            child: Text(
              label,
              style: AppFont.get(key,
                  color: isSelected ? colors.amber : colors.textMuted,
                  fontSize: 11,
                  letterSpacing: 0.5),
            ),
          ),
        );
      })).toList(),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppColors colors;
  const _SectionLabel(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFont.get(colors.fontFamily,
          color: colors.amber,
          fontSize: 10,
          letterSpacing: 3.5,
          weight: FontWeight.w700),
    );
  }
}

// ─── Toggle ───────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors colors;

  const _Toggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFont.get(colors.fontFamily,
                    color: colors.textPrimary,
                    fontSize: 13,
                    letterSpacing: 1.0,
                    weight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppFont.get(colors.fontFamily,
                    color: colors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ─── RSVP Preview ─────────────────────────────────────────────────────────────

class _RsvpPreview extends StatefulWidget {
  final AppState state;
  final AppColors colors;
  const _RsvpPreview({required this.state, required this.colors});

  @override
  State<_RsvpPreview> createState() => _RsvpPreviewState();
}

class _RsvpPreviewState extends State<_RsvpPreview> {
  static const _sentence = ['The', 'quick', 'brown', 'fox', 'jumps', 'over'];
  final int _idx = 2;

  @override
  Widget build(BuildContext context) {
    final token = RsvpService.tokenize(_sentence[_idx]);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 0),
      decoration: BoxDecoration(
        border: Border.all(color: widget.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RsvpDisplay(
            words: _sentence,
            currentIndex: _idx,
            showContext: widget.state.showContext,
            fontSize: widget.state.fontSize,
            highlightOrp: widget.state.highlightOrp,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '← tap to cycle →   ${token.word.toUpperCase()}',
                style: AppFont.get(widget.colors.fontFamily,
                    color: widget.colors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(_RsvpPreview old) {
    super.didUpdateWidget(old);
  }
}
