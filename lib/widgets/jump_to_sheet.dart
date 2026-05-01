import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../theme/terminal_theme.dart';
import 'amber_slider.dart';

Future<void> showJumpToSheet({
  required BuildContext context,
  required Book book,
  required void Function(int wordIndex) onJump,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _JumpToSheet(book: book, onJump: onJump),
  );
}

class _JumpToSheet extends StatefulWidget {
  final Book book;
  final void Function(int wordIndex) onJump;
  const _JumpToSheet({required this.book, required this.onJump});

  @override
  State<_JumpToSheet> createState() => _JumpToSheetState();
}

class _JumpToSheetState extends State<_JumpToSheet> {
  double _pct = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.book.totalWords > 0) {
      _pct = (widget.book.wordIndex / widget.book.totalWords * 100).clamp(0.0, 100.0);
    }
  }

  String _eta(double percent, int wpm) {
    if (wpm <= 0 || widget.book.totalWords <= 0) return '';
    final remaining = ((1.0 - percent / 100) * widget.book.totalWords).round();
    if (remaining <= 0) return '';
    final minutes = (remaining / wpm).ceil();
    if (minutes >= 60) return '${minutes ~/ 60}h ${minutes % 60}m';
    return '~ $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hasChapters = widget.book.chapters.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: SafeArea(
        top: false,
        child: hasChapters ? _buildChapterList(colors) : _buildSlider(colors),
      ),
    );
  }

  Widget _buildChapterList(AppColors colors) {
    final chapters = widget.book.chapters;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetHeader('KAPITEL', colors),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: chapters.length,
            itemBuilder: (_, i) {
              final ch = chapters[i];
              final pct = widget.book.totalWords > 0
                  ? (ch.wordIndex / widget.book.totalWords * 100).round()
                  : 0;
              final isCurrent = widget.book.wordIndex >= ch.wordIndex &&
                  (i == chapters.length - 1 || widget.book.wordIndex < chapters[i + 1].wordIndex);
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onJump(ch.wordIndex);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ch.name,
                          style: GoogleFonts.jetBrainsMono(
                            color: isCurrent ? colors.amber : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$pct%',
                        style: GoogleFonts.jetBrainsMono(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(AppColors colors) {
    // Default wpm for ETA — we don't have access to AppState here, use 250
    const wpm = 250;
    final eta = _eta(_pct, wpm);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHeader('SPRINGE ZU', colors),
          AmberSlider(
            label: 'POSITION',
            value: _pct,
            min: 0,
            max: 100,
            divisions: 100,
            valueLabel: (v) => '${v.round()}%',
            onChanged: (v) => setState(() => _pct = v),
          ),
          if (eta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              eta,
              style: GoogleFonts.jetBrainsMono(
                  color: colors.textMuted, fontSize: 11, letterSpacing: 1),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                final idx = (_pct / 100 * widget.book.totalWords).round()
                    .clamp(0, widget.book.totalWords > 0 ? widget.book.totalWords - 1 : 0);
                widget.onJump(idx);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.amber),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'JUMP',
                style: GoogleFonts.jetBrainsMono(
                    color: colors.amber,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final AppColors colors;
  const _SheetHeader(this.title, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              color: colors.amber,
              fontSize: 10,
              letterSpacing: 3.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              '✕',
              style: GoogleFonts.jetBrainsMono(
                  color: colors.textMuted, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
