import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles/styles.dart';

class AnimatedWhereToText extends StatefulWidget {
  final Size media;
  final String baseText;

  const AnimatedWhereToText({
    Key? key,
    required this.media,
    required this.baseText,
  }) : super(key: key);

  @override
  State<AnimatedWhereToText> createState() => _AnimatedWhereToTextState();
}

class _AnimatedWhereToTextState extends State<AnimatedWhereToText> {
  final List<String> _extraHints = [
    'Aéroport International de Ouagadougou...',
    'Centre commercial Laafi...',
    'Hôpital Yalgado...',
    'Place de la Nation...',
    'Université de Ouaga...',
  ];

  int _currentIndex = 0;
  bool _showBase = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _showBase = !_showBase;
        if (_showBase) {
          _currentIndex = (_currentIndex + 1) % _extraHints.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _showBase ? widget.baseText : _extraHints[_currentIndex];
    return TypewriterText(
      text: displayText,
      style: GoogleFonts.inter(
        fontSize: widget.media.width * 0.035,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({
    Key? key,
    required this.text,
    required this.style,
  }) : super(key: key);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayed = '';
  int _charIndex = 0;
  Timer? _charTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _charTimer?.cancel();
      _displayed = '';
      _charIndex = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    _charTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayed = widget.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _charTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}