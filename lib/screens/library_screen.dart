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

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (!state.isFirstLaunch) _bootDone = true;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('FLUX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, size: 18),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _bootDone ? _buildLibrary() : _buildBoot(),
      floatingActionButton: _bootDone
          ? FloatingActionButton(
              onPressed: _importBook,
              tooltip: 'Import',
              child: const Icon(Icons.add, size: 20),
            )
          : null,
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
                    strokeWidth: 1.5,
                    color: colors.amber,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'PARSING...',
                  style: GoogleFonts.jetBrainsMono(
                    color: colors.textMuted,
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
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
                    color: colors.textMuted,
                    fontSize: 12,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'tap + to import epub, txt or pdf',
                  style: GoogleFonts.jetBrainsMono(
                    color: colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (state.totalWordsRead > 0)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                ),
                child: _StatsBar(
                    total: state.totalWordsRead,
                    streak: state.streak,
                    colors: colors),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: state.books.length,
                itemBuilder: (ctx, i) {
                  final book = state.books[i];
                  return BookCard(
                    book: book,
                    onTap: () async {
                      await state.openBook(book);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReaderScreen()),
                      );
                    },
                    onDelete: () => state.deleteBook(book),
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

class _StatsBar extends StatelessWidget {
  final int total;
  final int streak;
  final AppColors colors;
  const _StatsBar({required this.total, required this.streak, required this.colors});

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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: colors.border)),
              child: Text('${_fmt(total)} WORDS', style: labelStyle, textAlign: TextAlign.center),
            ),
          ),
          if (streak > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: colors.border)),
              child: Text('$streak DAY STREAK', style: labelStyle),
            ),
          ],
        ],
      ),
    );
  }
}
