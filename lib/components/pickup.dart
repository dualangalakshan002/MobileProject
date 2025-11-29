import 'dart:async';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

enum PickupType { bomb, laser, shield, health } // Added health

class Pickup extends SpriteComponent with HasGameReference<MyGame> {
  final PickupType pickupType;

  Pickup({required super.position, required this.pickupType})
      : super(size: Vector2.all(100), anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    String assetName;
    switch (pickupType) {
      case PickupType.bomb:
        assetName = 'bomb_pickup.png';
        break;
      case PickupType.laser:
        assetName = 'laser_pickup.png';
        break;
      case PickupType.shield:
        assetName = 'shield_pickup.png';
        break;
      case PickupType.health:
        assetName = 'health_pickup.png'; // your asset
        break;
    }

    sprite = await game.loadSprite(assetName);
    add(CircleHitbox());

    final ScaleEffect pulsatingEffect = ScaleEffect.to(
      Vector2.all(0.9),
      EffectController(
        duration: 0.6,
        alternate: true,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    );
    add(pulsatingEffect);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y += 300 * dt;

    if (position.y > game.size.y + size.y / 2) {
      removeFromParent();
    }
  }
}
