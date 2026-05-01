import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../theme/terminal_theme.dart';
import 'jump_to_sheet.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onReset;
  final void Function(String title, String author) onEditMetadata;
  final void Function(int wordIndex) onJumpTo;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onDelete,
    required this.onReset,
    required this.onEditMetadata,
    required this.onJumpTo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context, colors),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '[${book.format.toUpperCase()}]',
                        style: GoogleFonts.jetBrainsMono(
                          color: colors.amber,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          book.title,
                          style: GoogleFonts.jetBrainsMono(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: GoogleFonts.jetBrainsMono(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _ProgressRing(progress: book.progress, colors: colors),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, AppColors colors) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookContextSheet(
        book: book,
        colors: colors,
        onOpen: () {
          Navigator.pop(ctx);
          onTap();
        },
        onReset: () {
          Navigator.pop(ctx);
          _confirmReset(context, colors);
        },
        onEditMetadata: () {
          Navigator.pop(ctx);
          _showMetadataDialog(context, colors);
        },
        onJumpTo: () {
          Navigator.pop(ctx);
          showJumpToSheet(context: context, book: book, onJump: onJumpTo);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(context, colors);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppColors colors) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'LÖSCHEN',
          style: GoogleFonts.jetBrainsMono(
              color: colors.amber, fontSize: 13, letterSpacing: 2),
        ),
        content: Text(
          '"${book.title}" entfernen?',
          style: GoogleFonts.jetBrainsMono(
              color: colors.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ABBRECHEN',
                style: GoogleFonts.jetBrainsMono(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text('LÖSCHEN',
                style: GoogleFonts.jetBrainsMono(color: colors.amber)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AppColors colors) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'NEUSTART',
          style: GoogleFonts.jetBrainsMono(
              color: colors.amber, fontSize: 13, letterSpacing: 2),
        ),
        content: Text(
          'Fortschritt zurücksetzen?',
          style: GoogleFonts.jetBrainsMono(
              color: colors.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ABBRECHEN',
                style: GoogleFonts.jetBrainsMono(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onReset();
            },
            child: Text('NEUSTART',
                style: GoogleFonts.jetBrainsMono(color: colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showMetadataDialog(BuildContext context, AppColors colors) {
    final titleCtrl = TextEditingController(text: book.title);
    final authorCtrl = TextEditingController(text: book.author);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final fieldStyle = GoogleFonts.jetBrainsMono(
            color: colors.textPrimary, fontSize: 13);
        final labelStyle = GoogleFonts.jetBrainsMono(
            color: colors.textMuted, fontSize: 10, letterSpacing: 1.5);
        final borderSide = BorderSide(color: colors.border);
        final focusBorder = BorderSide(color: colors.amber);

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(
            'METADATEN',
            style: GoogleFonts.jetBrainsMono(
                color: colors.amber, fontSize: 13, letterSpacing: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TITEL', style: labelStyle),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                style: fieldStyle,
                cursorColor: colors.amber,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: borderSide),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: focusBorder),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              Text('AUTOR', style: labelStyle),
              const SizedBox(height: 6),
              TextField(
                controller: authorCtrl,
                style: fieldStyle,
                cursorColor: colors.amber,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: borderSide),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: focusBorder),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ABBRECHEN',
                  style: GoogleFonts.jetBrainsMono(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (titleCtrl.text.trim().isNotEmpty) {
                  onEditMetadata(titleCtrl.text, authorCtrl.text);
                }
              },
              child: Text('SPEICHERN',
                  style: GoogleFonts.jetBrainsMono(color: colors.amber)),
            ),
          ],
        );
      },
    );
  }
}

// ─── Context sheet ────────────────────────────────────────────────────────────

class _BookContextSheet extends StatelessWidget {
  final Book book;
  final AppColors colors;
  final VoidCallback onOpen;
  final VoidCallback onReset;
  final VoidCallback onEditMetadata;
  final VoidCallback onJumpTo;
  final VoidCallback onDelete;

  const _BookContextSheet({
    required this.book,
    required this.colors,
    required this.onOpen,
    required this.onReset,
    required this.onEditMetadata,
    required this.onJumpTo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                book.title,
                style: GoogleFonts.jetBrainsMono(
                  color: colors.amber,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Divider(color: colors.border, height: 1),
            _SheetItem('▶  FORTFÜHREN', colors.textPrimary, colors, onOpen),
            Divider(color: colors.border, height: 1),
            _SheetItem('↺  NEUSTART', colors.textPrimary, colors, onReset),
            Divider(color: colors.border, height: 1),
            _SheetItem('✎  METADATEN', colors.textPrimary, colors, onEditMetadata),
            Divider(color: colors.border, height: 1),
            _SheetItem('⊳  SPRINGE ZU', colors.textPrimary, colors, onJumpTo),
            Divider(color: colors.border, height: 1),
            _SheetItem('✕  LÖSCHEN', colors.amber, colors, onDelete),
          ],
        ),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final String label;
  final Color textColor;
  final AppColors colors;
  final VoidCallback onTap;

  const _SheetItem(this.label, this.textColor, this.colors, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: textColor,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ─── Progress ring ────────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  final double progress;
  final AppColors colors;
  const _ProgressRing({required this.progress, required this.colors});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, colors: colors),
        child: Center(
          child: Text(
            '$pct',
            style: GoogleFonts.jetBrainsMono(
              color: progress > 0 ? colors.amber : colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final AppColors colors;
  const _RingPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = colors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.colors != colors;
}
