import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class AbilityButton extends PositionComponent
    with HasGameReference<MyGame>, TapCallbacks {
  final String label;
  final IconData icon;
  final Color color;
  final double cost; // Energy required (0-100)
  final VoidCallback onActivate;

  AbilityButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.cost,
    required this.onActivate,
    required Vector2 position,
  }) : super(position: position, size: Vector2.all(70), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Background (Dark Circle)
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.8);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, bgPaint);

    // 2. Progress Arc (Fills up based on energy vs cost)
    // We visualize it relative to the global max energy or the cost?
    // Let's visualize if it's ready. If energy >= cost, it's full (or filled to percentage of max)
    // To mimic the UI, let's make it a progress bar for THIS skill.
    double percentage = (game.energy / cost).clamp(0.0, 1.0);

    // Draw "Unfilled" track
    final trackPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2 - 2, trackPaint);

    // Draw "Filled" arc
    final progressPaint = Paint()
      ..color = percentage >= 1.0 ? color : color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw arc starting from top (-pi/2)
    canvas.drawArc(
      Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
      -pi / 2,
      2 * pi * percentage,
      false,
      progressPaint,
    );

    // 3. Icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 30,
          fontFamily: icon.fontFamily,
          color: percentage >= 1.0 ? Colors.white : Colors.white38,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2 - 5),
    );

    // 4. Label Text
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: percentage >= 1.0 ? color : Colors.white38,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset((size.x - labelPainter.width) / 2, size.y - 15),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.energy >= cost) {
      game.consumeEnergy(cost);
      onActivate();
      // Add a scale effect for visual feedback
      add(ScaleEffect.to(Vector2.all(0.9), EffectController(duration: 0.1, alternate: true)));
    } else {
      // Not enough energy feedback
      game.audioManager.playSound('click');
    }
  }
}