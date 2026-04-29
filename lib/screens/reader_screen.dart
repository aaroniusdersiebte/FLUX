import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/terminal_theme.dart';
import 'rsvp_screen.dart';

// Top-level route observer — registered in main.dart so didPopNext fires
// when the user navigates back from RsvpScreen to ReaderScreen.
final readerRouteObserver = RouteObserver<ModalRoute<void>>();

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  static RouteObserver<ModalRoute<void>> get routeObserver =>
      readerRouteObserver;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with RouteAware {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 600;
  static const int _tapRadius = 200;

  int _windowStart = 0;
  int _windowEnd = 0;
  int _lastKnownWordIdx = -1;
  bool _pendingScroll = false;

  final GlobalKey _highlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _lastKnownWordIdx = state.wordIndex;
    _setupWindow(state.wordIndex, state.words.length);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToHighlight(jump: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer so didPopNext fires when returning from RSVP
    final route = ModalRoute.of(context);
    if (route != null) readerRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    readerRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  /// Called when RSVP screen is popped and this screen comes back into focus.
  @override
  void didPopNext() {
    final state = context.read<AppState>();
    final wordIdx = state.wordIndex;
    if (wordIdx != _lastKnownWordIdx) {
      _lastKnownWordIdx = wordIdx;
      setState(() => _setupWindow(wordIdx, state.words.length));
      _pendingScroll = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToHighlight(jump: false));
    }
  }

  void _setupWindow(int wordIdx, int totalWords) {
    _windowStart = (wordIdx - 80).clamp(0, totalWords);
    _windowEnd = (wordIdx + _pageSize).clamp(0, totalWords);
  }

  void _scrollToHighlight({required bool jump}) {
    if (!mounted) return;
    _pendingScroll = false;
    final ctx = _highlightKey.currentContext;
    if (ctx == null) return;
    if (jump) {
      Scrollable.ensureVisible(ctx,
          duration: Duration.zero, alignment: 0.28);
    } else {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          alignment: 0.28);
    }
  }

  void _onWordTap(AppState state, int wordIndex) {
    state.seekToWord(wordIndex);
    _lastKnownWordIdx = wordIndex;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const RsvpScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final words = state.words;
        final wordIdx = state.wordIndex;
        final book = state.activeBook;
        final pct = words.isNotEmpty
            ? (wordIdx / words.length * 100).toStringAsFixed(0)
            : '0';

        // If word changed while not playing (e.g., after seeking via RSVP)
        // and a scroll is pending, trigger it after render.
        if (_pendingScroll) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToHighlight(jump: false));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(book?.title.toUpperCase() ?? ''),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '$pct%',
                    style: GoogleFonts.jetBrainsMono(
                        color: TerminalColors.textMuted, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: (notif) {
              if (notif is ScrollEndNotification &&
                  _scrollController.hasClients &&
                  _scrollController.position.extentAfter < 300) {
                setState(() {
                  _windowEnd =
                      (_windowEnd + _pageSize).clamp(0, words.length);
                });
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: _buildText(words, wordIdx),
            ),
          ),
          bottomSheet: _RsvpButton(
            onTap: () => _onWordTap(state, wordIdx),
          ),
        );
      },
    );
  }

  Widget _buildText(List<String> words, int wordIdx) {
    if (words.isEmpty) return const SizedBox.shrink();

    final start = _windowStart;
    final end = _windowEnd.clamp(0, words.length);
    final tapStart = (wordIdx - _tapRadius).clamp(start, end);
    final tapEnd = (wordIdx + _tapRadius).clamp(start, end);

    final base = GoogleFonts.jetBrainsMono(
        color: TerminalColors.textPrimary, fontSize: 14, height: 1.75);

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          if (start > 0)
            TextSpan(
                text: '… ',
                style: base.copyWith(color: TerminalColors.textMuted)),

          // Plain text before tappable zone
          if (tapStart > start)
            TextSpan(
                text: '${words.sublist(start, tapStart).join(' ')} '),

          // Tappable zone (±tapRadius around current word)
          for (int i = tapStart; i < tapEnd; i++)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _TappableWord(
                word: words[i],
                isHighlight: i == wordIdx,
                highlightKey: i == wordIdx ? _highlightKey : null,
                onTap: () => _onWordTap(context.read<AppState>(), i),
              ),
            ),

          // Plain text after tappable zone
          if (tapEnd < end)
            TextSpan(text: ' ${words.sublist(tapEnd, end).join(' ')}'),

          if (end < words.length)
            TextSpan(
                text: '\n\n···',
                style: base.copyWith(color: TerminalColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TappableWord extends StatelessWidget {
  final String word;
  final bool isHighlight;
  final GlobalKey? highlightKey;
  final VoidCallback onTap;

  const _TappableWord({
    required this.word,
    required this.isHighlight,
    required this.onTap,
    this.highlightKey,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(
      color: isHighlight ? TerminalColors.amber : TerminalColors.textPrimary,
      fontSize: 14,
      height: 1.75,
      fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w400,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: highlightKey,
        color: isHighlight ? TerminalColors.amberDim : Colors.transparent,
        padding: isHighlight
            ? const EdgeInsets.symmetric(horizontal: 1)
            : EdgeInsets.zero,
        child: Text('$word ', style: style),
      ),
    );
  }
}

class _RsvpButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RsvpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TerminalColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: TerminalColors.amber, width: 1),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              '▶  RSVP MODE',
              style: GoogleFonts.jetBrainsMono(
                  color: TerminalColors.amber,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
