import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../nav_key.dart';
import '../screens/reader_screen.dart';
import '../screens/rsvp_screen.dart';
import '../services/app_state.dart';
import '../theme/terminal_theme.dart';

// ─── Localization ─────────────────────────────────────────────────────────────

class _L {
  static const _s = {
    'de': {
      'lib_title': 'BIBLIOTHEK',
      'lib_body':
          'Das ist deine Büchersammlung.\n\nWische ←  für ANALYTIK\nWische →  für EINSTELLUNGEN',
      'reader_title': 'VOLLTEXT-ANSICHT',
      'reader_body':
          'Tippe ein Wort um an diese Stelle zu springen.\n\nREAD [>] unten startet den Speed-Reader.',
      'rsvp_title': 'LESE-GESTEN',
      'rsvp_body':
          'TIPPEN        Pause / Fortsetzen\nWISCHEN ←→    Satz springen\nWISCHEN ↑↓    WPM ändern',
      'next': 'WEITER →',
      'done': 'VERSTANDEN',
      'lang_title': 'SPRACHE / LANGUAGE',
      'lang_hint': 'Wähle deine Sprache.\nChoose your language.',
      'lang_de': 'DEUTSCH',
      'lang_en': 'ENGLISH',
    },
    'en': {
      'lib_title': 'LIBRARY',
      'lib_body':
          'This is your book collection.\n\nSwipe ←  for ANALYTICS\nSwipe →  for SETTINGS',
      'reader_title': 'FULL-TEXT VIEW',
      'reader_body':
          'Tap any word to jump to that position.\n\nREAD [>] at the bottom launches the speed reader.',
      'rsvp_title': 'READING GESTURES',
      'rsvp_body':
          'TAP           Pause / Resume\nSWIPE ←→      jump sentence\nSWIPE ↑↓      adjust WPM',
      'next': 'NEXT →',
      'done': 'GOT IT',
      'lang_title': 'SPRACHE / LANGUAGE',
      'lang_hint': 'Wähle deine Sprache.\nChoose your language.',
      'lang_de': 'DEUTSCH',
      'lang_en': 'ENGLISH',
    },
  };

  static String t(String lang, String key) => _s[lang]?[key] ?? _s['en']![key]!;
}

// ─── Main overlay widget ──────────────────────────────────────────────────────

class TutorialOverlay extends StatelessWidget {
  final AppColors colors;
  const TutorialOverlay({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        if (!state.isTutorialActive) return const SizedBox.shrink();

        final step = state.tutorialStep;
        final lang = state.appLanguage;

        if (step == 0) {
          return _LanguagePicker(colors: colors, state: state);
        }

        return _StepCallout(step: step, lang: lang, colors: colors, state: state);
      },
    );
  }
}

// ─── Language picker (step 0, full-screen opaque) ─────────────────────────────

class _LanguagePicker extends StatelessWidget {
  final AppColors colors;
  final AppState state;
  const _LanguagePicker({required this.colors, required this.state});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'FLUX',
                style: AppFont.get(colors.fontFamily,
                    color: colors.amber,
                    fontSize: 24,
                    letterSpacing: 6,
                    weight: FontWeight.w700),
              ),
              const SizedBox(height: 32),
              Text(
                _L.t('de', 'lang_title'),
                style: AppFont.get(colors.fontFamily,
                    color: colors.textPrimary,
                    fontSize: 13,
                    letterSpacing: 2,
                    weight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                _L.t('de', 'lang_hint'),
                style: AppFont.get(colors.fontFamily,
                    color: colors.textMuted, fontSize: 13, height: 1.8),
              ),
              const SizedBox(height: 48),
              _LangBtn(
                label: 'DEUTSCH',
                colors: colors,
                onTap: () {
                  state.setAppLanguage('de');
                  state.advanceTutorial();
                },
              ),
              const SizedBox(height: 16),
              _LangBtn(
                label: 'ENGLISH',
                colors: colors,
                onTap: () {
                  state.setAppLanguage('en');
                  state.advanceTutorial();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onTap;
  const _LangBtn({required this.label, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: colors.border)),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppFont.get(colors.fontFamily,
              color: colors.textPrimary,
              fontSize: 14,
              letterSpacing: 3,
              weight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── In-context step callout (steps 1–3) ─────────────────────────────────────

class _StepCallout extends StatelessWidget {
  final int step;
  final String lang;
  final AppColors colors;
  final AppState state;

  const _StepCallout({
    required this.step,
    required this.lang,
    required this.colors,
    required this.state,
  });

  void _onNext() {
    switch (step) {
      case 1: // library → reader: load demo book, navigate
        state.openDemoBook();
        state.advanceTutorial();
        appNavigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => const ReaderScreen(),
        ));
      case 2: // reader → rsvp: navigate (demo book already loaded)
        state.advanceTutorial();
        appNavigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => const RsvpScreen(),
        ));
      case 3: // done: pop all routes, end tutorial
        appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        state.endTutorial();
    }
  }

  (String, String) _content() {
    switch (step) {
      case 1:
        return (_L.t(lang, 'lib_title'), _L.t(lang, 'lib_body'));
      case 2:
        return (_L.t(lang, 'reader_title'), _L.t(lang, 'reader_body'));
      case 3:
        return (_L.t(lang, 'rsvp_title'), _L.t(lang, 'rsvp_body'));
      default:
        return ('', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, body) = _content();
    final isLast = step == 3;
    final btnLabel = isLast ? _L.t(lang, 'done') : _L.t(lang, 'next');

    return Material(
      color: Colors.transparent,
      child: Stack(
      children: [
        // Gradient fade — passthrough to underlying screen
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 320,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background.withValues(alpha: 0),
                    colors.background.withValues(alpha: 0.97),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Callout box
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppFont.get(colors.fontFamily,
                            color: colors.amber,
                            fontSize: 10,
                            letterSpacing: 3,
                            weight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '$step / 3',
                        style: AppFont.get(colors.fontFamily,
                            color: colors.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    body,
                    style: AppFont.get(colors.fontFamily,
                        color: colors.textPrimary, fontSize: 13, height: 1.85),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          border: Border.all(color: colors.amber)),
                      alignment: Alignment.center,
                      child: Text(
                        btnLabel,
                        style: AppFont.get(colors.fontFamily,
                            color: colors.amber,
                            fontSize: 12,
                            letterSpacing: 2.5,
                            weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}
