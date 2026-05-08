import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/terminal_theme.dart';

// ─── Localization ─────────────────────────────────────────────────────────────

class _TL {
  static const _s = {
    'de': {
      'step': 'SCHRITT',
      'of': 'VON',
      // Step 1
      'lang_title': 'SPRACHE / LANGUAGE',
      'lang_body': 'Wähle deine Sprache.\nChoose your language.',
      'lang_de': 'DEUTSCH',
      'lang_en': 'ENGLISH',
      // Step 2
      'rsvp_title': 'WAS IST RSVP?',
      'rsvp_body':
          'RSVP (Rapid Serial Visual Presentation) zeigt Wörter einzeln an einer fixen Position.\nDein Auge muss nicht scannen — du liest schneller.\n\nWörter pro Minute (WPM) steuert das Tempo.',
      // Step 3
      'gestures_title': 'LESEN — GESTEN',
      'gestures_body':
          'Im Lese-Modus:\n\n  TIPPEN        Pause / Fortsetzen\n  WISCHEN ←     voriger Satz\n  WISCHEN →     nächster Satz\n  WISCHEN ↑     WPM erhöhen\n  WISCHEN ↓     WPM verringern',
      // Step 4
      'reader_title': 'VOLLTEXT-ANSICHT',
      'reader_body':
          'Tippe auf ein beliebiges Wort im Text,\num dort weiterzulesen.\n\n[ RSVP STARTEN ] am unteren Rand\nstartet den Speed-Reader.',
      // Step 5
      'library_title': 'BIBLIOTHEK',
      'library_body':
          'Wische links/rechts zwischen den drei\nBereichen:\n\n  ←  ANALYTIK\n  ■  BIBLIOTHEK\n  →  EINSTELLUNGEN',
      'next': 'WEITER →',
      'start': 'LOSLEGEN',
    },
    'en': {
      'step': 'STEP',
      'of': 'OF',
      'lang_title': 'SPRACHE / LANGUAGE',
      'lang_body': 'Wähle deine Sprache.\nChoose your language.',
      'lang_de': 'DEUTSCH',
      'lang_en': 'ENGLISH',
      'rsvp_title': 'WHAT IS RSVP?',
      'rsvp_body':
          'RSVP (Rapid Serial Visual Presentation) shows words one at a time at a fixed point.\nYour eyes don\'t scan — you read faster.\n\nWords Per Minute (WPM) controls the pace.',
      'gestures_title': 'READING — GESTURES',
      'gestures_body':
          'While reading:\n\n  TAP           Pause / Resume\n  SWIPE ←       previous sentence\n  SWIPE →       next sentence\n  SWIPE ↑       increase WPM\n  SWIPE ↓       decrease WPM',
      'reader_title': 'FULL-TEXT VIEW',
      'reader_body':
          'Tap any word in the text to jump\nto that position.\n\n[ START RSVP ] at the bottom\nlaunches the speed reader.',
      'library_title': 'LIBRARY',
      'library_body':
          'Swipe left/right between the three\nsections:\n\n  ←  ANALYTICS\n  ■  LIBRARY\n  →  SETTINGS',
      'next': 'NEXT →',
      'start': 'GET STARTED',
    },
  };

  static String t(String lang, String key) => _s[lang]?[key] ?? key;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;
  static const int _totalSteps = 5;

  void _next(AppState state) {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      state.setTutorialDone();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final colors = Theme.of(context).extension<AppColors>()!;
        final lang = state.appLanguage;
        final isLast = _step == _totalSteps - 1;

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(
                    current: _step,
                    total: _totalSteps,
                    lang: lang,
                    colors: colors),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    child: _buildStep(state, colors, lang),
                  ),
                ),
                if (_step > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                    child: GestureDetector(
                      onTap: () => _next(state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.amber),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isLast
                              ? _TL.t(lang, 'start')
                              : _TL.t(lang, 'next'),
                          style: AppFont.get(
                            colors.fontFamily,
                            color: colors.amber,
                            fontSize: 13,
                            letterSpacing: 2.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(AppState state, AppColors colors, String lang) {
    switch (_step) {
      case 0:
        return _LangStep(colors: colors, onSelect: (l) {
          state.setAppLanguage(l);
          setState(() => _step = 1);
        });
      case 1:
        return _ContentStep(
          title: _TL.t(lang, 'rsvp_title'),
          body: _TL.t(lang, 'rsvp_body'),
          colors: colors,
        );
      case 2:
        return _ContentStep(
          title: _TL.t(lang, 'gestures_title'),
          body: _TL.t(lang, 'gestures_body'),
          colors: colors,
          monospaceBody: true,
        );
      case 3:
        return _ContentStep(
          title: _TL.t(lang, 'reader_title'),
          body: _TL.t(lang, 'reader_body'),
          colors: colors,
        );
      case 4:
        return _ContentStep(
          title: _TL.t(lang, 'library_title'),
          body: _TL.t(lang, 'library_body'),
          colors: colors,
          monospaceBody: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  final String lang;
  final AppColors colors;

  const _StepIndicator({
    required this.current,
    required this.total,
    required this.lang,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Row(
        children: [
          Text(
            current == 0
                ? 'FLUX'
                : '${_TL.t(lang, 'step')} $current ${_TL.t(lang, 'of')} ${total - 1}',
            style: AppFont.get(
              colors.fontFamily,
              color: colors.amber,
              fontSize: 10,
              letterSpacing: 3,
              weight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(total - 1, (i) {
              final active = i < current;
              return Container(
                width: 20,
                height: 2,
                margin: const EdgeInsets.only(left: 4),
                color: active ? colors.amber : colors.border,
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Language Selection Step ──────────────────────────────────────────────────

class _LangStep extends StatelessWidget {
  final AppColors colors;
  final ValueChanged<String> onSelect;

  const _LangStep({required this.colors, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SPRACHE / LANGUAGE',
          style: AppFont.get(
            colors.fontFamily,
            color: colors.amber,
            fontSize: 14,
            letterSpacing: 3,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Wähle deine Sprache.\nChoose your language.',
          style: AppFont.get(
            colors.fontFamily,
            color: colors.textMuted,
            fontSize: 13,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 48),
        _LangButton(label: 'DEUTSCH', colors: colors, onTap: () => onSelect('de')),
        const SizedBox(height: 16),
        _LangButton(label: 'ENGLISH', colors: colors, onTap: () => onSelect('en')),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: colors.border)),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppFont.get(
            colors.fontFamily,
            color: colors.textPrimary,
            fontSize: 14,
            letterSpacing: 3,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Content Step ─────────────────────────────────────────────────────────────

class _ContentStep extends StatelessWidget {
  final String title;
  final String body;
  final AppColors colors;
  final bool monospaceBody;

  const _ContentStep({
    required this.title,
    required this.body,
    required this.colors,
    this.monospaceBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppFont.get(
            colors.fontFamily,
            color: colors.amber,
            fontSize: 14,
            letterSpacing: 3,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(border: Border.all(color: colors.border)),
          child: Text(
            body,
            style: AppFont.get(
              colors.fontFamily,
              color: monospaceBody ? colors.textPrimary : colors.textMuted,
              fontSize: monospaceBody ? 13 : 14,
              height: 1.9,
            ),
          ),
        ),
      ],
    );
  }
}
