import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/app_state.dart';
import '../services/rsvp_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/rsvp_display.dart';
import '../widgets/scramble_text.dart';

class RsvpScreen extends StatefulWidget {
  const RsvpScreen({super.key});

  @override
  State<RsvpScreen> createState() => _RsvpScreenState();
}

class _RsvpScreenState extends State<RsvpScreen> with TickerProviderStateMixin {
  bool _showPauseOverlay = false;
  bool _isDecrypting = false;
  bool _showMilestone = false;
  int _milestoneTarget = 0;
  int _milestoneTierStart = 0;
  late AppState _appState;
  late AnimationController _milestoneAnim;
  Offset? _panStartLocal;
  double _screenH = 0;
  int? _wpmFeedback;
  Timer? _wpmFeedbackTimer;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _milestoneAnim = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _appState.addListener(_checkMilestone);
    WakelockPlus.enable();
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
    _appState.removeListener(_checkMilestone);
    _milestoneAnim.dispose();
    _wpmFeedbackTimer?.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _checkMilestone() {
    final m = _appState.pendingMilestone;
    if (m != null && !_showMilestone && mounted) {
      _appState.vibrateMilestone();
      setState(() {
        _showMilestone = true;
        _milestoneTarget = m;
        _milestoneTierStart = m > 0 ? AppState.goalTierStart(m) : 0;
      });
      _milestoneAnim.forward().then((_) {
        if (!mounted) return;
        _appState.clearMilestone();
        _appState.play();
        setState(() => _showMilestone = false);
        _milestoneAnim.reset();
      });
    }
  }

  void _startPlayWithAnimation() {
    if (!mounted) return;
    final words = _appState.words;
    final idx = _appState.wordIndex;
    final currentWord = (words.isNotEmpty && idx < words.length) ? words[idx] : '';
    if (currentWord.isEmpty) {
      _appState.play();
      return;
    }
    setState(() => _isDecrypting = true);
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

  void _handlePanEnd(AppState state, DragEndDetails details) {
    final start = _panStartLocal;
    _panStartLocal = null;
    final v = details.velocity.pixelsPerSecond;

    if (v.dx.abs() > v.dy.abs()) {
      // Horizontal — sentence navigation (works during pause too)
      if (v.dx < 0) {
        state.nextSentence();
      } else {
        state.prevSentence();
      }
      if (!state.isPlaying) setState(() => _showPauseOverlay = true);
    } else {
      // Vertical — WPM adjustment (blocked during pause, edge zones ignored)
      if (_showPauseOverlay || start == null) return;
      final rel = start.dy / _screenH;
      if (rel < 0.20 || rel > 0.80) return;
      if (v.dy.abs() < 300) return;
      final newWpm = v.dy < 0
          ? (state.wpm + 5).clamp(100, 1000)
          : (state.wpm - 5).clamp(100, 1000);
      state.setWpm(newWpm);
      _wpmFeedbackTimer?.cancel();
      setState(() => _wpmFeedback = newWpm);
      _wpmFeedbackTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _wpmFeedback = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<AppState>(
      builder: (context, state, _) {
        final colors = Theme.of(context).extension<AppColors>()!;
        _screenH = MediaQuery.of(context).size.height;
        final words = state.words;
        final idx = state.wordIndex;
        final progress = words.isNotEmpty ? idx / words.length : 0.0;
        final streakProgress = state.streakModeEnabled ? state.goalProgress : null;
        final eta = _formatEta(words.length - idx, state.wpm);

        return Scaffold(
          backgroundColor: colors.background,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleTap(state),
            onPanStart: (d) => _panStartLocal = d.localPosition,
            onPanEnd: (d) => _handlePanEnd(state, d),
            child: SafeArea(
              child: Stack(
                children: [
                  isLandscape
                      ? _buildLandscape(colors, state, words, idx, progress, streakProgress)
                      : _buildPortrait(colors, state, words, idx, streakProgress),
                  if (_showPauseOverlay) _PauseOverlay(state: state, colors: colors),
                  if (!isLandscape)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: colors.background,
                        child: _BottomBar(
                          colors: colors,
                          progress: progress,
                          idx: idx,
                          total: words.length,
                          wpm: state.wpm,
                          eta: eta,
                          milestoneAnim: _showMilestone ? _milestoneAnim : null,
                          milestoneTarget: _milestoneTarget,
                          milestoneTierStart: _milestoneTierStart,
                          wpmFeedback: _wpmFeedback,
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

  String _formatEta(int remaining, int wpm) {
    if (wpm <= 0 || remaining <= 0) return '';
    final minutes = (remaining / wpm).ceil();
    if (minutes >= 60) return '${minutes ~/ 60}h ${minutes % 60}m';
    return '$minutes min';
  }

  void _onDecryptComplete() {
    if (mounted) {
      setState(() => _isDecrypting = false);
      _appState.play();
    }
  }

  Widget _buildPortrait(
      AppColors colors, AppState state, List<String> words, int idx, double? streakProgress) {
    return Column(
      children: [
        _TopBar(state: state, colors: colors),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RsvpDisplay(
                words: words,
                currentIndex: idx,
                showContext: state.showContext,
                fontSize: state.fontSize,
                streakProgress: streakProgress,
                isDecrypting: _isDecrypting,
                onDecryptComplete: _onDecryptComplete,
              ),
            ),
          ),
        ),
        const SizedBox(height: 68),
      ],
    );
  }

  Widget _buildLandscape(AppColors colors, AppState state, List<String> words,
      int idx, double progress, double? streakProgress) {
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
                        color: colors.amber, fontSize: 16)),
              ),
              const Spacer(),
              RotatedBox(
                quarterTurns: 3,
                child: Text('${state.wpm} WPM',
                    style: GoogleFonts.jetBrainsMono(
                        color: colors.textMuted,
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
              streakProgress: streakProgress,
              isDecrypting: _isDecrypting,
              onDecryptComplete: _onDecryptComplete,
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
                    color: colors.amber, fontSize: 11),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.amber),
                      minHeight: 1,
                    ),
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.jetBrainsMono(
                    color: colors.textMuted, fontSize: 9),
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
  final AppColors colors;
  const _TopBar({required this.state, required this.colors});

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
                      color: colors.amber, fontSize: 18)),
            ),
          ),
          Expanded(
            child: Text(
              state.activeBook?.title.toUpperCase() ?? '',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                  color: colors.textMuted,
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
  final String eta;
  final AnimationController? milestoneAnim;
  final int milestoneTarget;
  final int milestoneTierStart;
  final int? wpmFeedback;
  final AppColors colors;

  const _BottomBar({
    required this.progress,
    required this.idx,
    required this.total,
    required this.wpm,
    required this.eta,
    required this.colors,
    this.milestoneAnim,
    this.milestoneTarget = 0,
    this.milestoneTierStart = 0,
    this.wpmFeedback,
  });

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
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.amber),
                  minHeight: 1,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: milestoneAnim != null
                    ? _GoalBadge(
                        anim: milestoneAnim!,
                        target: milestoneTarget,
                        tierStart: milestoneTierStart,
                        colors: colors,
                      )
                    : wpmFeedback != null
                        ? ScrambleText(
                            key: ValueKey(wpmFeedback),
                            text: '$wpmFeedback WPM',
                            duration: const Duration(milliseconds: 280),
                            style: GoogleFonts.jetBrainsMono(
                              color: colors.amber,
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : Text('$idx / $total',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                                color: colors.textMuted, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              eta.isEmpty ? '$wpm WPM' : '$wpm WPM  ·  $eta',
              style: GoogleFonts.jetBrainsMono(
                  color: colors.textMuted,
                  fontSize: 11,
                  letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final AppState state;
  final AppColors colors;
  const _PauseOverlay({required this.state, required this.colors});

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
          color: colors.background.withValues(alpha: 0.94),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('— PAUSED —',
                    style: GoogleFonts.jetBrainsMono(
                        color: colors.amber,
                        fontSize: 10,
                        letterSpacing: 4)),
                const SizedBox(height: 24),
                _SentenceWithHighlight(
                    sentence: sentence, highlight: currentWord, colors: colors),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => state.prevSentence(),
                      child: _Chip('← sentence', colors),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => state.nextSentence(),
                      child: _Chip('sentence →', colors),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('tap to resume',
                    style: GoogleFonts.jetBrainsMono(
                        color: colors.textMuted,
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
                      color: colors.amber, fontSize: 18)),
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
  final AppColors colors;

  const _SentenceWithHighlight(
      {required this.sentence, required this.highlight, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (sentence.isEmpty) return const SizedBox.shrink();

    final base = GoogleFonts.jetBrainsMono(
        color: colors.textPrimary, fontSize: 14, height: 1.8);

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
            color: colors.amberDim,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(match,
                style: base.copyWith(
                    color: colors.amber,
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
  final AppColors colors;
  const _Chip(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: colors.border)),
      child: Text(text,
          style: GoogleFonts.jetBrainsMono(
              color: colors.textMuted, fontSize: 9, letterSpacing: 1)),
    );
  }
}

class _GoalBadge extends StatefulWidget {
  final AnimationController anim;
  final int target;
  final int tierStart;
  final AppColors colors;

  const _GoalBadge({
    required this.anim,
    required this.target,
    required this.tierStart,
    required this.colors,
  });

  @override
  State<_GoalBadge> createState() => _GoalBadgeState();
}

class _GoalBadgeState extends State<_GoalBadge> {
  bool _showGoal = false;
  bool _fadingOut = false;
  late Animation<int> _countAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _countAnim = IntTween(begin: widget.tierStart, end: widget.target).animate(
      CurvedAnimation(
          parent: widget.anim,
          curve: const Interval(0.0, 0.43, curve: Curves.easeOut)),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: widget.anim,
          curve: const Interval(0.71, 1.0, curve: Curves.easeIn)),
    );
    widget.anim.addListener(_onAnim);
  }

  void _onAnim() {
    if (!mounted) return;
    if (widget.anim.value >= 0.43 && !_showGoal) {
      setState(() => _showGoal = true);
    }
    if (widget.anim.value >= 0.71 && !_fadingOut) {
      setState(() => _fadingOut = true);
    }
  }

  @override
  void dispose() {
    widget.anim.removeListener(_onAnim);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(
      color: widget.colors.amber,
      fontSize: 10,
      letterSpacing: 1.5,
    );

    if (_showGoal) {
      return FadeTransition(
        opacity: _fadeAnim,
        child: ScrambleText(
          key: ValueKey(_fadingOut ? 'badge_out' : 'badge_in'),
          text: '★ GOAL',
          reverse: _fadingOut,
          duration: const Duration(milliseconds: 350),
          style: style,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _countAnim,
      builder: (context, child) => Text('${_countAnim.value}', style: style),
    );
  }
}
