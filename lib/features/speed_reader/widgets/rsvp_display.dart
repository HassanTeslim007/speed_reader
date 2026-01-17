import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/features/speed_reader/models/rsvp_settings.dart';
import 'package:speed_reader/features/speed_reader/providers/rsvp_provider.dart';

/// RSVP display widget showing one word at a time
class RsvpDisplay extends StatelessWidget {
  const RsvpDisplay({super.key});

  /// Find the Optimal Recognition Point (ORP) - usually around 1/3 from start
  int _findORP(String word) {
    if (word.length <= 1) return 0;
    return (word.length * 0.35).round();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RsvpProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final word = provider.currentWord;

        if (word.isEmpty) {
          return Center(
            child: Text(
              'No text loaded',
              style: TextStyle(
                fontSize: 24,
                color: settings.textColor.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        final orpIndex = _findORP(word);

        return Container(
          color: settings.backgroundColor,
          child: Stack(
            children: [
              // Focus guide (crosshair)
              if (settings.showFocusGuide)
                Center(
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: _FocusGuidePainter(
                      color: settings.textColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),

              // Word display
              Center(
                child: settings.highlightORP
                    ? _buildWordWithORP(word, orpIndex, settings)
                    : _buildSimpleWord(word, settings),
              ),

              // Progress indicator
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: provider.progress,
                      backgroundColor: settings.textColor.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        settings.highlightColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${provider.currentWordIndex + 1} / ${provider.totalWords}',
                      style: TextStyle(
                        color: settings.textColor.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleWord(String word, RsvpSettings settings) {
    return Text(
      word,
      style: TextStyle(
        fontSize: settings.fontSize,
        color: settings.textColor,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildWordWithORP(String word, int orpIndex, RsvpSettings settings) {
    final before = word.substring(0, orpIndex);
    final orp = word[orpIndex];
    final after = orpIndex < word.length - 1
        ? word.substring(orpIndex + 1)
        : '';

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: settings.fontSize,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
        children: [
          TextSpan(
            text: before,
            style: TextStyle(color: settings.textColor),
          ),
          TextSpan(
            text: orp,
            style: TextStyle(
              color: settings.highlightColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: after,
            style: TextStyle(color: settings.textColor),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for focus guide (crosshair)
class _FocusGuidePainter extends CustomPainter {
  final Color color;

  _FocusGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Horizontal line
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );

    // Center circle
    canvas.drawCircle(center, 4, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_FocusGuidePainter oldDelegate) =>
      color != oldDelegate.color;
}
