import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/terminal_theme.dart';
import '../widgets/book_card.dart';
import '../widgets/scramble_text.dart';
import 'analytics_screen.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _bootDone = false;
  late final PageController _pageController;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (!state.isFirstLaunch) _bootDone = true;
    _pageController = PageController(initialPage: 1);
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 1;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _importBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'txt', 'pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;
    final state = context.read<AppState>();
    await state.importBook(result.files.single.path!);
    if (!mounted) return;
    final err = state.error;
    if (err != null) {
      final colors = Theme.of(context).extension<AppColors>()!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: GoogleFonts.jetBrainsMono(fontSize: 12)),
          backgroundColor: colors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootDone) {
      return Scaffold(body: _buildBoot());
    }

    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _PageHeader(
                  currentPage: _currentPage,
                  colors: colors,
                  onLeft: () => _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  onRight: () => _pageController.animateToPage(
                    2,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    children: [
                      const AnalyticsBody(),
                      _buildLibrary(),
                      const SettingsBody(),
                    ],
                  ),
                ),
              ],
            ),
            // FAB for import, visible only on library page
            Positioned(
              right: 16,
              bottom: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _currentPage == 1 ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: _currentPage != 1,
                  child: FloatingActionButton(
                    onPressed: _importBook,
                    tooltip: 'Import',
                    child: const Icon(Icons.add, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoot() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScrambleText(
              text: 'FLUX v1.0',
              duration: const Duration(milliseconds: 600),
              style: GoogleFonts.jetBrainsMono(
                color: TerminalColors.amber,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            ScrambleText(
              text: 'speed reading system',
              duration: const Duration(milliseconds: 800),
              style: GoogleFonts.jetBrainsMono(
                color: TerminalColors.textMuted,
                fontSize: 12,
                letterSpacing: 2,
              ),
              onComplete: () => setState(() => _bootDone = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrary() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final colors = Theme.of(context).extension<AppColors>()!;

        if (state.loading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: colors.amber),
                ),
                const SizedBox(height: 12),
                Text(
                  'PARSING...',
                  style: GoogleFonts.jetBrainsMono(
                      color: colors.textMuted, fontSize: 11, letterSpacing: 3),
                ),
              ],
            ),
          );
        }

        if (state.books.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '[ NO BOOKS ]',
                  style: GoogleFonts.jetBrainsMono(
                      color: colors.textMuted, fontSize: 12, letterSpacing: 3),
                ),
                const SizedBox(height: 8),
                Text(
                  'tap + to import epub, txt or pdf',
                  style: GoogleFonts.jetBrainsMono(
                      color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (state.totalWordsRead > 0)
              GestureDetector(
                onTap: () => _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: _StatsBar(
                    total: state.totalWordsRead,
                    streak: state.streak,
                    colors: colors),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
                itemCount: state.books.length,
                itemBuilder: (ctx, i) {
                  final book = state.books[i];
                  // Use live wordIndex for active book to prevent stale progress
                  final displayBook =
                      (book.id == state.activeBook?.id && state.words.isNotEmpty)
                          ? book.copyWith(wordIndex: state.wordIndex)
                          : book;
                  return BookCard(
                    book: displayBook,
                    onTap: () async {
                      await state.openBook(book);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReaderScreen()),
                      );
                    },
                    onDelete: () => state.deleteBook(book),
                    onReset: () => state.resetBook(book),
                    onEditMetadata: (title, author) =>
                        state.updateBookMetadata(book, title, author),
                    onJumpTo: (wordIndex) => state.seekToWord(wordIndex),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final int currentPage;
  final AppColors colors;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _PageHeader({
    required this.currentPage,
    required this.colors,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Row(
            children: [
              _NavArrow(
                label: '◀',
                onTap: onLeft,
                active: currentPage != 0,
                colors: colors,
              ),
              Expanded(
                child: Center(
                  child: ScrambleText(
                    text: 'FLUX',
                    duration: const Duration(milliseconds: 500),
                    style: GoogleFonts.jetBrainsMono(
                      color: colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              _NavArrow(
                label: '▶',
                onTap: onRight,
                active: currentPage != 2,
                colors: colors,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == currentPage ? 14 : 6,
              height: 2,
              color: i == currentPage ? colors.amber : colors.border,
            );
          }),
        ),
        const SizedBox(height: 8),
        Divider(color: colors.border, height: 1),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;
  final AppColors colors;

  const _NavArrow({
    required this.label,
    required this.onTap,
    required this.active,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: active ? colors.amber : colors.border,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total;
  final int streak;
  final AppColors colors;
  const _StatsBar(
      {required this.total, required this.streak, required this.colors});

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.jetBrainsMono(
      color: colors.amber,
      fontSize: 11,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration:
                  BoxDecoration(border: Border.all(color: colors.border)),
              child: Text('${_fmt(total)} WORDS',
                  style: labelStyle, textAlign: TextAlign.center),
            ),
          ),
          if (streak > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration:
                  BoxDecoration(border: Border.all(color: colors.border)),
              child: Text('$streak DAY STREAK', style: labelStyle),
            ),
          ],
        ],
      ),
    );
  }
}
