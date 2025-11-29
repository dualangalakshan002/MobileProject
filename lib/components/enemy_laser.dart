import 'dart:async';

import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class EnemyLaser extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  EnemyLaser({required super.position})
      : super(
          size: Vector2(10, 30), // Slightly different size
          anchor: Anchor.center,
          priority: -1,
        );

  @override
  FutureOr<void> onLoad() async {
    // Make sure you have this image, or reuse 'laser.png'
    sprite = await game.loadSprite('laser_enemy.png');

    add(RectangleHitbox());

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move DOWN (positive Y)
    position.y += 400 * dt;

    // Remove if it goes off the bottom of the screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Player) {
      removeFromParent();
      // Deal 10 damage to the player
      other.takeDamage(10);
    }
  }
}