import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/rsvp_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/rsvp_display.dart';

class RsvpScreen extends StatefulWidget {
  const RsvpScreen({super.key});

  @override
  State<RsvpScreen> createState() => _RsvpScreenState();
}

class _RsvpScreenState extends State<RsvpScreen> with TickerProviderStateMixin {
  bool _showPauseOverlay = false;
  late AppState _appState;
  late AnimationController _startAnim;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _startAnim = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..addListener(() => setState(() {}));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startPlayWithAnimation();
    });
  }

  @override
  void deactivate() {
    _appState.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _startAnim.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _startPlayWithAnimation() async {
    try {
      await _startAnim.forward().orCancel;
      await _startAnim.reverse().orCancel;
    } catch (_) {
      return;
    }
    if (mounted) _appState.play();
  }

  void _handleTap(AppState state) {
    if (state.isPlaying) {
      state.pause();
      setState(() => _showPauseOverlay = true);
    } else {
      setState(() => _showPauseOverlay = false);
      _startPlayWithAnimation();
    }
  }

  void _handleSwipe(AppState state, DragEndDetails details) {
    final dx = details.velocity.pixelsPerSecond.dx;
    if (dx < 0) {
      state.nextSentence();
    } else {
      state.prevSentence();
    }
    if (!state.isPlaying) setState(() => _showPauseOverlay = true);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<AppState>(
      builder: (context, state, _) {
        final words = state.words;
        final idx = state.wordIndex;
        final progress = words.isNotEmpty ? idx / words.length : 0.0;
        final focalScale = lerpDouble(1.0, 2.5, _startAnim.value)!;

        return Scaffold(
          backgroundColor: TerminalColors.background,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleTap(state),
            onHorizontalDragEnd: (d) => _handleSwipe(state, d),
            child: SafeArea(
              child: Stack(
                children: [
                  isLandscape
                      ? _buildLandscape(state, words, idx, progress, focalScale)
                      : _buildPortrait(state, words, idx, focalScale),
                  if (_showPauseOverlay) _PauseOverlay(state: state),
                  if (!isLandscape)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: TerminalColors.background,
                        child: _BottomBar(
                          progress: progress,
                          idx: idx,
                          total: words.length,
                          wpm: state.wpm,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortrait(
      AppState state, List<String> words, int idx, double focalScale) {
    return Column(
      children: [
        _TopBar(state: state),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RsvpDisplay(
                words: words,
                currentIndex: idx,
                showContext: state.showContext,
                fontSize: state.fontSize,
                focalScale: focalScale,
              ),
            ),
          ),
        ),
        const SizedBox(height: 68),
      ],
    );
  }

  Widget _buildLandscape(AppState state, List<String> words, int idx,
      double progress, double focalScale) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('←',
                    style: GoogleFonts.jetBrainsMono(
                        color: TerminalColors.amber, fontSize: 16)),
              ),
              const Spacer(),
              RotatedBox(
                quarterTurns: 3,
                child: Text('${state.wpm} WPM',
                    style: GoogleFonts.jetBrainsMono(
                        color: TerminalColors.textMuted,
                        fontSize: 9,
                        letterSpacing: 1.5)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: RsvpDisplay(
              words: words,
              currentIndex: idx,
              showContext: state.showContext,
              fontSize: (state.fontSize * 0.82).clamp(16.0, 48.0),
              focalScale: focalScale,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 8),
              Text(
                state.isPlaying ? '▶' : '■',
                style: GoogleFonts.jetBrainsMono(
                    color: TerminalColors.amber, fontSize: 11),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: TerminalColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          TerminalColors.amber),
                      minHeight: 1,
                    ),
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.jetBrainsMono(
                    color: TerminalColors.textMuted, fontSize: 9),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: Text('←',
                  style: GoogleFonts.jetBrainsMono(
                      color: TerminalColors.amber, fontSize: 18)),
            ),
          ),
          Expanded(
            child: Text(
              state.activeBook?.title.toUpperCase() ?? '',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                  color: TerminalColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double progress;
  final int idx;
  final int total;
  final int wpm;
  const _BottomBar(
      {required this.progress,
      required this.idx,
      required this.total,
      required this.wpm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: TerminalColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      TerminalColors.amber),
                  minHeight: 1,
                ),
              ),
              const SizedBox(width: 10),
              Text('$idx / $total',
                  style: GoogleFonts.jetBrainsMono(
                      color: TerminalColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$wpm WPM',
              style: GoogleFonts.jetBrainsMono(
                  color: TerminalColors.textMuted,
                  fontSize: 11,
                  letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final AppState state;
  const _PauseOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final words = state.words;
    final wordIdx = state.wordIndex;
    final currentWord = wordIdx < words.length ? words[wordIdx] : '';
    final sentence = words.isNotEmpty
        ? RsvpService.currentSentenceText(words, wordIdx)
        : '';

    return Stack(
      children: [
        Container(
          color: TerminalColors.background.withValues(alpha: 0.94),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('— PAUSED —',
                    style: GoogleFonts.jetBrainsMono(
                        color: TerminalColors.amber,
                        fontSize: 10,
                        letterSpacing: 4)),
                const SizedBox(height: 24),
                _SentenceWithHighlight(
                    sentence: sentence, highlight: currentWord),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => state.prevSentence(),
                      child: _Chip('← sentence'),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => state.nextSentence(),
                      child: _Chip('sentence →'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('tap to resume',
                    style: GoogleFonts.jetBrainsMono(
                        color: TerminalColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 2)),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 24, 18),
              child: Text('←',
                  style: GoogleFonts.jetBrainsMono(
                      color: TerminalColors.amber, fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SentenceWithHighlight extends StatelessWidget {
  final String sentence;
  final String highlight;

  const _SentenceWithHighlight(
      {required this.sentence, required this.highlight});

  @override
  Widget build(BuildContext context) {
    if (sentence.isEmpty) return const SizedBox.shrink();

    final base = GoogleFonts.jetBrainsMono(
        color: TerminalColors.textPrimary, fontSize: 14, height: 1.8);

    final lowerSentence = sentence.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    final hitIdx = lowerSentence.indexOf(lowerHighlight);

    if (hitIdx < 0 || highlight.isEmpty) {
      return Text(sentence, textAlign: TextAlign.center, style: base);
    }

    final before = sentence.substring(0, hitIdx);
    final match = sentence.substring(hitIdx, hitIdx + highlight.length);
    final after = sentence.substring(hitIdx + highlight.length);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(style: base, children: [
        TextSpan(text: before),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            color: TerminalColors.amberDim,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(match,
                style: base.copyWith(
                    color: TerminalColors.amber,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        TextSpan(text: after),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: TerminalColors.border)),
      child: Text(text,
          style: GoogleFonts.jetBrainsMono(
              color: TerminalColors.textMuted, fontSize: 9, letterSpacing: 1)),
    );
  }
}
