import 'dart:async';

import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class DriverHud extends PositionComponent with HasGameReference<MyGame> {

  DriverHud() : super(
    position: Vector2(20, 10), // Top Left, above health bar
    size: Vector2.all(50),
    priority: 10,
  );

  @override
  FutureOr<void> onLoad() async {
    // 1. Create a Circular Mask for the profile picture
    // Uses the new integer based system: driver_0.png, driver_1.png...
    final sprite = await game.loadSprite('driver_${game.selectedDriver}.png');

    final profile = SpriteComponent(
      sprite: sprite,
      size: size,
    );

    // Add a simple border
    final border = CircleComponent(
      radius: size.x / 2 + 2,
      paint: Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2,
      position: size / 2,
      anchor: Anchor.center,
    );

    add(profile);
    add(border);

    // Entrance effect
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.5, curve: Curves.elasticOut),
    ));
    scale = Vector2.zero(); // Start invisible

    return super.onLoad();
  }
}