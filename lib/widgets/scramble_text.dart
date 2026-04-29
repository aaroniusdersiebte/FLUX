import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/terminal_theme.dart';

class ScrambleText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final VoidCallback? onComplete;

  const ScrambleText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends State<ScrambleText> {
  static const String _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
  final Random _rng = Random();
  late String _displayed;
  Timer? _timer;
  int _step = 0;
  late int _totalSteps;

  @override
  void initState() {
    super.initState();
    _displayed = _randomString(widget.text.length);
    _totalSteps = (widget.duration.inMilliseconds / 30).round();
    _startAnimation();
  }

  String _randomString(int len) {
    return List.generate(
      len,
      (i) => widget.text[i] == ' ' ? ' ' : _chars[_rng.nextInt(_chars.length)],
    ).join();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _step++;
      final progress = _step / _totalSteps;
      final revealedChars = (progress * widget.text.length).floor();
      setState(() {
        _displayed = widget.text.substring(0, revealedChars) +
            _randomString(widget.text.length - revealedChars);
      });
      if (_step >= _totalSteps) {
        t.cancel();
        setState(() => _displayed = widget.text);
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style ??
          GoogleFonts.jetBrainsMono(
            color: TerminalColors.amber,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
    );
  }
}
