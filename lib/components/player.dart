import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/bomb.dart';
import 'package:cosmic_havoc/components/enemy.dart';
import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/laser.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/shield.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/services.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<MyGame>, KeyboardHandler, CollisionCallbacks {
  bool _isShooting = false;
  final double _fireCooldown = 0.2;
  double _elapsedFireTime = 0.0;
  final Vector2 _keyboardMovement = Vector2.zero();
  bool _isDestroyed = false;
  final Random _random = Random();
  late Timer _explosionTimer;
  late Timer _laserPowerupTimer;

  // NEW: Speed Boost Timer and Multiplier
  late Timer _speedPowerupTimer;
  double _moveSpeedMultiplier = 1.0;

  Shield? activeShield;
  late String _color;

  // Health
  double maxHealth = 100;
  double health = 100;

  Player() {
    _explosionTimer = Timer(
      0.1,
      onTick: _createRandomExplosion,
      repeat: true,
      autoStart: false,
    );

    _laserPowerupTimer = Timer(
      10.0,
      autoStart: false,
    );

    // NEW: Initialize Speed Timer (e.g., 8 seconds duration)
    _speedPowerupTimer = Timer(
      8.0,
      onTick: _resetSpeed,
      autoStart: false,
    );
  }

  @override
  FutureOr<void> onLoad() async {
    _color = game.playerColors[game.playerColorIndex];

    animation = await _loadAnimation();

    size *= 0.3;

    add(RectangleHitbox.relative(
      Vector2(0.6, 0.9),
      parentSize: size,
      anchor: Anchor.center,
    ));

    return super.onLoad();
  }

  // ----------------------------------------------------------
  // 🚀 ENGINE THRUSTER PARTICLES (Updated for Speed Boost)
  // ----------------------------------------------------------
  void _spawnThrusterParticle() {
    final Vector2 particlePos =
        position.clone() + Vector2(0, size.y * 0.55);

    // NEW: Change particle color if Speed Boost is active
    final bool isSpeedBoosted = _moveSpeedMultiplier > 1.0;

    // Normal: Orange/Red. Boosted: Cyan/Blue
    final Color colorStart = isSpeedBoosted
        ? const Color(0xFF00FFFF) // Cyan
        : const Color(0xFFFFA800); // Orange

    final Color colorEnd = isSpeedBoosted
        ? const Color(0xFF0077FF) // Blue
        : const Color(0xFFFF3C00); // Red

    // Boosted particles are slightly faster/larger
    final double speedFactor = isSpeedBoosted ? 2.0 : 1.0;

    final particle = ParticleSystemComponent(
      particle: Particle.generate(
        count: 1,
        lifespan: 0.15,
        generator: (i) {
          return AcceleratedParticle(
            acceleration: Vector2(0, 200 * speedFactor),
            speed: Vector2(0, 50 * speedFactor),
            position: particlePos,
            child: CircleParticle(
              radius: (3 + _random.nextDouble() * 3) * (isSpeedBoosted ? 1.2 : 1.0),
              paint: Paint()
                ..color = Color.lerp(
                  colorStart,
                  colorEnd,
                  _random.nextDouble(),
                )!,
            ),
          );
        },
      ),
    );

    game.add(particle);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDestroyed) {
      _explosionTimer.update(dt);
      return;
    }

    _spawnThrusterParticle();

    if (_laserPowerupTimer.isRunning()) {
      _laserPowerupTimer.update(dt);
    }
    // NEW: Update Speed Timer
    if (_speedPowerupTimer.isRunning()) {
      _speedPowerupTimer.update(dt);
    }

    final Vector2 movement = game.joystick.relativeDelta + _keyboardMovement;

    // NEW: Apply the _moveSpeedMultiplier here
    // Base speed 200 * Multiplier
    position += movement.normalized() * 200 * _moveSpeedMultiplier * dt;

    _handleScreenBounds();

    _elapsedFireTime += dt;
    if (_isShooting && _elapsedFireTime >= _fireCooldown) {
      _fireLaser();
      _elapsedFireTime = 0.0;
    }
  }

  Future<SpriteAnimation> _loadAnimation() async {
    return SpriteAnimation.spriteList(
      [
        await game.loadSprite('player_${_color}_on0.png'),
        await game.loadSprite('player_${_color}_on1.png'),
      ],
      stepTime: 0.1,
      loop: true,
    );
  }

  void _handleScreenBounds() {
    final double screenWidth = game.size.x;
    final double screenHeight = game.size.y;

    position.y = clampDouble(
      position.y,
      size.y / 2,
      screenHeight - size.y / 2,
    );

    if (position.x < 0) {
      position.x = screenWidth;
    } else if (position.x > screenWidth) {
      position.x = 0;
    }
  }

  void startShooting() {
    _isShooting = true;
  }

  void stopShooting() {
    _isShooting = false;
  }

  void _fireLaser() {
    game.audioManager.playSound('laser');

    // ... (Existing laser logic) ...
    game.add(
      Laser(position: position.clone() + Vector2(0, -size.y / 2)),
    );

    if (_laserPowerupTimer.isRunning()) {
      game.add(
        Laser(
          position: position.clone() + Vector2(0, -size.y / 2),
          angle: 15 * degrees2Radians,
        ),
      );
      game.add(
        Laser(
          position: position.clone() + Vector2(0, -size.y / 2),
          angle: -15 * degrees2Radians,
        ),
      );
    }
  }

  void takeDamage(double damage) {
    if (_isDestroyed) return;

    health -= damage;

    add(ColorEffect(
      const Color.fromRGBO(255, 0, 0, 1.0),
      EffectController(
        duration: 0.1,
        alternate: true,
      ),
    ));

    game.audioManager.playSound('hit');

    if (health <= 0) {
      health = 0;
      _handleDestruction();
    }
  }

  void _handleDestruction() async {
    // ... (Existing destruction logic) ...
    animation = SpriteAnimation.spriteList(
      [
        await game.loadSprite('player_${_color}_off.png'),
      ],
      stepTime: double.infinity,
    );

    add(ColorEffect(
      const Color.fromRGBO(255, 255, 255, 1.0),
      EffectController(duration: 0.0),
    ));

    add(OpacityEffect.fadeOut(
      EffectController(duration: 3.0),
      onComplete: () => _explosionTimer.stop(),
    ));

    add(MoveEffect.by(
      Vector2(0, 200),
      EffectController(duration: 3.0),
    ));

    add(RemoveEffect(
      delay: 4.0,
      onComplete: game.playerDied,
    ));

    _isDestroyed = true;

    _explosionTimer.start();
  }

  void _createRandomExplosion() {
     // ... (Existing explosion logic) ...
    final Vector2 explosionPosition = Vector2(
      position.x - size.x / 2 + _random.nextDouble() * size.x,
      position.y - size.y / 2 + _random.nextDouble() * size.y,
    );

    final ExplosionType explosionType =
        _random.nextBool() ? ExplosionType.smoke : ExplosionType.fire;

    final Explosion explosion = Explosion(
      position: explosionPosition,
      explosionSize: size.x * 0.7,
      explosionType: explosionType,
    );

    game.add(explosion);
  }

  // NEW: Reset speed callback
  void _resetSpeed() {
    _moveSpeedMultiplier = 1.0;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_isDestroyed) return;

    if (other is Asteroid || other is Enemy) {
      if (activeShield != null) {
        if (other is Asteroid) other.takeDamage();
        if (other is Enemy) other.takeDamage();
        return;
      }

      takeDamage(30);

      if (other is Asteroid) other.takeDamage();
      if (other is Enemy) other.takeDamage();

    } else if (other is Pickup) {
        game.audioManager.playSound('collect');
        other.removeFromParent();
        game.incrementScore(1);

        switch (other.pickupType) {
          case PickupType.laser:
            _laserPowerupTimer.start();
            break;
          case PickupType.bomb:
            game.add(Bomb(position: position.clone()));
            break;
          case PickupType.shield:
            if (activeShield != null) remove(activeShield!);
            activeShield = Shield();
            add(activeShield!);
            break;
          case PickupType.health:
            health += 30;
            if (health > maxHealth) health = maxHealth;
            break;
          // NEW: Handle Speed Pickup
          case PickupType.speed:
            _moveSpeedMultiplier = 2.0; // Double speed
            _speedPowerupTimer.stop(); // Reset timer if already running
            _speedPowerupTimer.start();
            break;
        }
      }

  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardMovement.x = 0;
    _keyboardMovement.x +=
        keysPressed.contains(LogicalKeyboardKey.arrowLeft) ? -1 : 0;
    _keyboardMovement.x +=
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ? 1 : 0;

    _keyboardMovement.y = 0;
    _keyboardMovement.y +=
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ? -1 : 0;
    _keyboardMovement.y +=
        keysPressed.contains(LogicalKeyboardKey.arrowDown) ? 1 : 0;

    return true;
  }
}