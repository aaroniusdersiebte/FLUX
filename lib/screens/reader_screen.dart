import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/terminal_theme.dart';
import 'rsvp_screen.dart';

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
  static const int _pageSize = 400;

  int _windowStart = 0;
  int _windowEnd = 0;
  int _lastKnownWordIdx = -1;
  bool _pendingScroll = false;

  final GlobalKey _highlightKey = GlobalKey();
  final GlobalKey _richTextKey = GlobalKey();

  // (charStart, charEnd, wordIndex) — rebuilt in _buildText, used for tap lookup
  final List<(int, int, int)> _wordOffsets = [];

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
    final route = ModalRoute.of(context);
    if (route != null) readerRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    readerRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

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
      Scrollable.ensureVisible(ctx, duration: Duration.zero, alignment: 0.28);
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

  void _handleTextTap(TapUpDetails details, AppState state) {
    final obj = _richTextKey.currentContext?.findRenderObject();
    if (obj == null) return;
    final para = obj as RenderParagraph;
    final localPos = para.globalToLocal(details.globalPosition);
    final charOffset = para.getPositionForOffset(localPos).offset;
    for (final (start, end, wordIdx) in _wordOffsets) {
      if (charOffset >= start && charOffset < end) {
        _onWordTap(state, wordIdx);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Selector: only rebuild when wordIndex, words, or activeBook changes.
    // Ignores unrelated AppState changes (streak, totalWords, etc.).
    return Selector<AppState, (int, List<String>, dynamic)>(
      selector: (_, s) => (s.wordIndex, s.words, s.activeBook),
      builder: (ctx, data, _) {
        final (wordIdx, words, book) = data;
        final colors = Theme.of(context).extension<AppColors>()!;
        final pct = words.isNotEmpty
            ? (wordIdx / words.length * 100).toStringAsFixed(0)
            : '0';

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
                        color: colors.textMuted, fontSize: 11),
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
              child: _buildText(colors, words, wordIdx,
                  context.read<AppState>()),
            ),
          ),
          bottomSheet: _RsvpButton(
            colors: colors,
            onTap: () => _onWordTap(context.read<AppState>(), wordIdx),
          ),
        );
      },
    );
  }

  Widget _buildText(
      AppColors colors, List<String> words, int wordIdx, AppState state) {
    if (words.isEmpty) return const SizedBox.shrink();

    final start = _windowStart;
    final end = _windowEnd.clamp(0, words.length);

    _wordOffsets.clear();
    int charOffset = 0;

    final base = GoogleFonts.jetBrainsMono(
        color: colors.textPrimary, fontSize: 14, height: 1.75);
    final mutedStyle = base.copyWith(color: colors.textMuted);

    final children = <InlineSpan>[];

    if (start > 0) {
      children.add(TextSpan(text: '… ', style: mutedStyle));
      charOffset += 2;
    }

    for (int i = start; i < end; i++) {
      final word = words[i];
      if (i == wordIdx) {
        _wordOffsets.add((charOffset, charOffset + 1, i));
        charOffset += 1; // WidgetSpan = U+FFFC = 1 char in text metrics
        children.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            key: _highlightKey,
            color: colors.amberDim,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              '$word ',
              style: base.copyWith(
                  color: colors.amber, fontWeight: FontWeight.w700),
            ),
          ),
        ));
      } else {
        _wordOffsets.add((charOffset, charOffset + word.length + 1, i));
        charOffset += word.length + 1;
        children.add(TextSpan(text: '$word ', style: base));
      }
    }

    if (end < words.length) {
      children.add(TextSpan(text: '\n\n···', style: mutedStyle));
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) => _handleTextTap(d, state),
      child: RichText(
        key: _richTextKey,
        text: TextSpan(style: base, children: children),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _RsvpButton extends StatelessWidget {
  final VoidCallback onTap;
  final AppColors colors;
  const _RsvpButton({required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.amber, width: 1),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              '▶  READ',
              style: GoogleFonts.jetBrainsMono(
                  color: colors.amber,
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
