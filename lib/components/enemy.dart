import 'dart:async';
import 'dart:math';
import 'dart:ui'; // Required for Color

import 'package:cosmic_havoc/components/enemy_laser.dart';
import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/laser.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class Enemy extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {

  // Movement variables
  final double _speed = 150;
  double _time = 0;
  final double _initialX;

  // Shooting variables
  late Timer _shootTimer;
  final Random _random = Random();

  // Health
  int _hp = 2;

  Enemy({required Vector2 position})
      : _initialX = position.x,
        // UPDATED: Changed size from 60 to 180 (3x bigger)
        super(position: position, size: Vector2.all(180), anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('enemy.png');

    // Rotate 180 degrees so it faces down
    angle = pi;

    // Hitbox will automatically match the new size (180x180)
    add(RectangleHitbox());

    // Set up shooting timer
    _shootTimer = Timer(
      1.5 + _random.nextDouble() * 1.5,
      onTick: _shoot,
      repeat: true,
    );
    _shootTimer.start();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _shootTimer.update(dt);
    _time += dt;

    // 1. Move Down
    position.y += _speed * dt;

    // 2. Sine Wave Movement
    position.x = _initialX + sin(_time * 3) * 100;

    // 3. Cleanup if off screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  void _shoot() {
    if (position.y < 0 || position.y > game.size.y) return;

    game.audioManager.playSound('laser');

    // UPDATED: Calculate spawn position dynamically based on size
    // size.y / 2 ensures the laser spawns at the nose of the ship
    game.add(EnemyLaser(position: position + Vector2(0, size.y / 2)));
  }

  void takeDamage() {
    game.audioManager.playSound('hit');
    _hp--;

    add(ColorEffect(
      const Color(0xFFFFFFFF),
      EffectController(duration: 0.1, alternate: true),
    ));

    if (_hp <= 0) {
      _destroy();
    }
  }

  void _destroy() {
    removeFromParent();
    game.incrementScore(5);

    game.add(Explosion(
      position: position,
      explosionSize: size.x, // Explosion size scales automatically too
      explosionType: ExplosionType.fire,
    ));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Laser) {
      other.removeFromParent();
      takeDamage();
    }
  }
}