import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_token.dart';
import '../services/rsvp_service.dart';
import '../theme/terminal_theme.dart';
import 'scramble_text.dart';

class _FocalRingPainter extends CustomPainter {
  final double progress;
  final AppColors colors;
  _FocalRingPainter(this.progress, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(1.5);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = colors.amberDim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (progress > 0) {
      final fullPath = Path()..addRRect(rrect);
      final metric = fullPath.computeMetrics().first;
      final total = metric.length;
      final startLen = (rect.width / 2 - rrect.tlRadiusX).clamp(0.0, total);
      final endLen = startLen + progress * total;
      final arcPaint = Paint()
        ..color = colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      if (endLen <= total) {
        canvas.drawPath(metric.extractPath(startLen, endLen), arcPaint);
      } else {
        canvas.drawPath(metric.extractPath(startLen, total), arcPaint);
        canvas.drawPath(metric.extractPath(0, endLen - total), arcPaint);
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 1, size.height / 2 - 4, 2, 8),
      Paint()..color = colors.amber,
    );
  }

  @override
  bool shouldRepaint(_FocalRingPainter old) =>
      old.progress != progress || old.colors != colors;
}

/// Spritz-style RSVP display.
/// ORP character is always at 40% of the word area (fixed focal point).
/// Display width is capped to avoid wide gaps in landscape.
class RsvpDisplay extends StatelessWidget {
  final List<String> words;
  final int currentIndex;
  final bool showContext;
  final double fontSize;
  final double? streakProgress;
  final bool isDecrypting;
  final VoidCallback? onDecryptComplete;

  const RsvpDisplay({
    super.key,
    required this.words,
    required this.currentIndex,
    required this.showContext,
    required this.fontSize,
    this.streakProgress,
    this.isDecrypting = false,
    this.onDecryptComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<AppColors>()!;
    final idx = currentIndex.clamp(0, words.length - 1);
    final token = RsvpService.tokenize(words[idx]);
    final prev = (idx > 0 && showContext) ? words[idx - 1] : null;
    final next = (idx < words.length - 1 && showContext) ? words[idx + 1] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDisplayW = min(constraints.maxWidth, 440.0);
        final ctxW = showContext ? (maxDisplayW * 0.20).clamp(50.0, 86.0) : 0.0;
        final ctxGap = showContext ? 10.0 : 0.0;
        final wordAreaW = (maxDisplayW - 2 * (ctxW + ctxGap)).clamp(60.0, maxDisplayW);

        return Center(
          child: SizedBox(
            width: maxDisplayW,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: fontSize,
                  child: _buildRow(colors, token, prev, next, ctxW, ctxGap, wordAreaW),
                ),
                const SizedBox(height: 6),
                _buildFocalLine(colors, ctxW, ctxGap, wordAreaW, maxDisplayW),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(
    AppColors colors,
    WordToken token,
    String? prev,
    String? next,
    double ctxW,
    double ctxGap,
    double wordAreaW,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showContext) ...[
          SizedBox(
            width: ctxW,
            child: Text(
              isDecrypting ? '' : (prev ?? ''),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.jetBrainsMono(
                color: colors.amberDim,
                fontSize: (fontSize * 0.48).clamp(10.0, 18.0),
              ),
            ),
          ),
          SizedBox(width: ctxGap),
        ],
        _buildWord(colors, token, wordAreaW),
        if (showContext) ...[
          SizedBox(width: ctxGap),
          SizedBox(
            width: ctxW,
            child: Text(
              isDecrypting ? '' : (next ?? ''),
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.jetBrainsMono(
                color: colors.amberDim,
                fontSize: (fontSize * 0.48).clamp(10.0, 18.0),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWord(AppColors colors, WordToken token, double wordAreaW) {
    const ratio = 0.601;
    final charW = fontSize * ratio;

    final neededW = token.word.length * charW;
    final scaledFS = neededW > wordAreaW
        ? (fontSize * (wordAreaW / neededW)).clamp(11.0, fontSize)
        : fontSize;
    final scaledCharW = scaledFS * ratio;

    final focalX = wordAreaW * 0.40;
    final prefW = (focalX - scaledCharW * 0.5).clamp(0.0, wordAreaW * 0.7);
    final orpW = scaledCharW;
    final sufW = (wordAreaW - prefW - orpW).clamp(0.0, wordAreaW);

    if (isDecrypting) {
      final textLeft = (prefW - token.prefix.length * scaledCharW).clamp(0.0, wordAreaW);
      return SizedBox(
        width: wordAreaW,
        child: Padding(
          padding: EdgeInsets.only(left: textLeft),
          child: ScrambleText(
            key: ValueKey('decrypt_${token.word}'),
            text: token.word,
            duration: const Duration(milliseconds: 600),
            style: GoogleFonts.jetBrainsMono(
              color: colors.amber,
              fontSize: scaledFS,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
            digitColor: colors.textPrimary,
            onComplete: onDecryptComplete,
          ),
        ),
      );
    }

    final base = GoogleFonts.jetBrainsMono(
      color: colors.textPrimary,
      fontSize: scaledFS,
      fontWeight: FontWeight.w400,
      height: 1.0,
    );

    return SizedBox(
      width: wordAreaW,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: prefW,
            child: Text(token.prefix,
                textAlign: TextAlign.right,
                overflow: TextOverflow.clip,
                maxLines: 1,
                style: base),
          ),
          SizedBox(
            width: orpW,
            child: Text(token.orpChar,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: base.copyWith(
                    color: colors.amber,
                    fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: sufW,
            child: Text(token.suffix,
                textAlign: TextAlign.left,
                overflow: TextOverflow.clip,
                maxLines: 1,
                style: base),
          ),
        ],
      ),
    );
  }

  Widget _buildFocalLine(
      AppColors colors, double ctxW, double ctxGap, double wordAreaW, double displayW) {
    final wordAreaLeft = ctxW + ctxGap;
    final focalX = wordAreaLeft + wordAreaW * 0.40;

    if (streakProgress != null) {
      return SizedBox(
        width: displayW,
        height: 22,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: focalX - 11,
              top: 0,
              width: 22,
              height: 22,
              child: CustomPaint(
                painter: _FocalRingPainter(streakProgress!, colors),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: displayW,
      height: 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: focalX - 1,
            top: 0,
            width: 2,
            height: 8,
            child: Container(color: colors.amber),
          ),
        ],
      ),
    );
  }
}
