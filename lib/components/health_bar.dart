import 'dart:async';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HealthBar extends PositionComponent with HasGameReference<MyGame> {
  late RectangleComponent _barBuffer;
  late RectangleComponent _barFill;

  // Position the bar at the top left of the screen
  HealthBar() : super(position: Vector2(20, 50), priority: 10);

  @override
  FutureOr<void> onLoad() {
    // 1. The background of the bar (Dark Red) indicating lost health
    _barBuffer = RectangleComponent(
      size: Vector2(200, 20),
      paint: Paint()..color = const Color.fromARGB(255, 75, 0, 0),
    );

    // 2. The foreground (Green) indicating current health
    _barFill = RectangleComponent(
      size: Vector2(200, 20),
      paint: Paint()..color = const Color.fromARGB(255, 0, 255, 0),
    );

    add(_barBuffer);
    add(_barFill);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Calculate percentage of health remaining
    double percent = game.player.health / game.player.maxHealth;

    // Clamp ensures it doesn't go below 0 or above 1
    percent = percent.clamp(0.0, 1.0);

    // Update the width of the green bar based on health percentage
    _barFill.width = 200 * percent;

    // Change color based on health status
    if (percent < 0.3) {
      _barFill.paint.color = const Color.fromARGB(255, 255, 0, 0); // Red
    } else if (percent < 0.6) {
      _barFill.paint.color = const Color.fromARGB(255, 255, 230, 0); // Yellow
    } else {
      _barFill.paint.color = const Color.fromARGB(255, 0, 255, 0); // Green
    }
  }
}