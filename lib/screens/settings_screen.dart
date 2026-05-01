import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/rsvp_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/amber_slider.dart';
import '../widgets/rsvp_display.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              _SectionLabel('SPEED', colors),
              const SizedBox(height: 12),
              AmberSlider(
                label: 'WPM',
                value: state.wpm.toDouble(),
                min: 100,
                max: 1000,
                divisions: 90,
                valueLabel: (v) => '${v.round()} wpm',
                onChanged: (v) => state.setWpm(v.round()),
              ),
              const SizedBox(height: 16),
              _Toggle(
                label: 'ADAPTIVE PAUSE',
                subtitle: 'Extra delay: long words & punctuation',
                value: state.adaptivePause,
                onChanged: state.setAdaptivePause,
                colors: colors,
              ),
              _divider(colors),
              _SectionLabel('DISPLAY', colors),
              const SizedBox(height: 12),
              AmberSlider(
                label: 'FONT SIZE',
                value: state.fontSize,
                min: 18,
                max: 56,
                divisions: 38,
                valueLabel: (v) => '${v.round()} px',
                onChanged: state.setFontSize,
              ),
              const SizedBox(height: 16),
              _Toggle(
                label: 'CONTEXT WORDS',
                subtitle: 'Show prev / next word at 30% opacity',
                value: state.showContext,
                onChanged: state.setShowContext,
                colors: colors,
              ),
              const SizedBox(height: 16),
              _Toggle(
                label: 'LIGHT MODE',
                subtitle: 'Helles Erscheinungsbild (Standard: dunkel)',
                value: !state.isDarkMode,
                onChanged: (v) => state.setDarkMode(!v),
                colors: colors,
              ),
              _divider(colors),
              _SectionLabel('PREVIEW', colors),
              const SizedBox(height: 16),
              _RsvpPreview(state: state, colors: colors),
              _divider(colors),
              _SectionLabel('GOALS', colors),
              const SizedBox(height: 12),
              _Toggle(
                label: 'STREAK MODE',
                subtitle: 'Tägliche Wortziele: 500 → 1000 → 1500 → 2000 → 3000',
                value: state.streakModeEnabled,
                onChanged: state.setStreakModeEnabled,
                colors: colors,
              ),
              const SizedBox(height: 16),
              _Toggle(
                label: 'VIBRATION',
                subtitle: 'Vibriert beim Pausieren / Start und bei Tageszielen',
                value: state.vibrationEnabled,
                onChanged: state.setVibrationEnabled,
                colors: colors,
              ),
              _divider(colors),
              _SectionLabel('ABOUT', colors),
              const SizedBox(height: 8),
              Text(
                'FLUX  v1.0\n'
                'RSVP Speed Reading\n'
                'Terminal Edition',
                style: GoogleFonts.jetBrainsMono(
                  color: colors.textMuted,
                  fontSize: 11,
                  height: 2.0,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _divider(AppColors colors) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Divider(
          color: colors.border,
          height: 1,
          thickness: 1,
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppColors colors;
  const _SectionLabel(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        color: colors.amber,
        fontSize: 10,
        letterSpacing: 3.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

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
                style: GoogleFonts.jetBrainsMono(
                  color: colors.textPrimary,
                  fontSize: 13,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.jetBrainsMono(
                  color: colors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

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
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '← tap to cycle →   ${token.word.toUpperCase()}',
                style: GoogleFonts.jetBrainsMono(
                  color: widget.colors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
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
