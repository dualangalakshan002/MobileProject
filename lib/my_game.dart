import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/ability_button.dart';
import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/audio_manager.dart';
import 'package:cosmic_havoc/components/boss.dart';
import 'package:cosmic_havoc/components/driver_hud.dart';
import 'package:cosmic_havoc/components/enemy.dart';
import 'package:cosmic_havoc/components/enemy_laser.dart';
import 'package:cosmic_havoc/components/health_bar.dart';
import 'package:cosmic_havoc/components/pause_button.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/components/shoot_button.dart';
import 'package:cosmic_havoc/components/star.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapData {
  final String name;
  final String asset;
  final int cost;

  MapData({required this.name, required this.asset, required this.cost});
}

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late SpawnComponent _asteroidSpawner;
  late SpawnComponent _enemySpawner;
  late SpawnComponent _pickupSpawner;
  final Random _random = Random();
  late ShootButton _shootButton;

  int _score = 0;
  int highScore = 0;
  bool _bossSpawned = false;

  // --- User Profile Data ---
  String playerName = "Commander";

  // --- UPGRADES ---
  int wallet = 0;
  int healthLevel = 0;
  int speedLevel = 0;
  int shieldRegenLevel = 0;
  int fireRateLevel = 0;
  int missileLevel = 0;

  // Customization
  int selectedDriver = 0;
  String selectedTrailColor = 'orange';

  late DriverHud driverHud;

  // --- ABILITY SYSTEM ---
  double energy = 0.0;
  final double maxEnergy = 100.0;
  double timeScale = 1.0;

  // Map System Variables
  final List<MapData> maps = [
    MapData(name: 'Deep Space', asset: 'default', cost: 0),
    MapData(name: 'Nebula', asset: 'map_1.png', cost: 500),
    MapData(name: 'Red Galaxy', asset: 'map_2.png', cost: 1000),
    MapData(name: 'Void Base', asset: 'map_3.png', cost: 2000),
  ];
  List<int> unlockedMapIndices = [0];
  int currentMapIndex = 0;
  ParallaxComponent? _currentBackground;

  double get difficultyMultiplier => 1.0 + (_score / 500);

  late TextComponent _scoreDisplay;
  final List<String> playerColors = ['blue', 'red', 'green', 'purple'];
  int playerColorIndex = 0;
  late final AudioManager audioManager;

  @override
  FutureOr<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();

    audioManager = AudioManager();
    await add(audioManager);

    await loadData();

    _updateBackground();
    _createStars();

    return super.onLoad();
  }

  // --- SAVE & LOAD SYSTEM ---
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    playerName = prefs.getString('playerName') ?? "Commander";
    highScore = prefs.getInt('highScore') ?? 0;
    wallet = prefs.getInt('wallet') ?? 0;
    healthLevel = prefs.getInt('healthLevel') ?? 0;
    speedLevel = prefs.getInt('speedLevel') ?? 0;
    fireRateLevel = prefs.getInt('fireRateLevel') ?? 0;
    shieldRegenLevel = prefs.getInt('shieldRegenLevel') ?? 0;
    missileLevel = prefs.getInt('missileLevel') ?? 0;
    selectedDriver = prefs.getInt('selectedDriver') ?? 0;
    selectedTrailColor = prefs.getString('selectedTrailColor') ?? 'orange';
    currentMapIndex = prefs.getInt('currentMapIndex') ?? 0;
    String? unlockedString = prefs.getString('unlockedMaps');
    if (unlockedString != null && unlockedString.isNotEmpty) {
      unlockedMapIndices =
          unlockedString.split(',').map((e) => int.parse(e)).toList();
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', playerName);
    if (_score > highScore) {
      highScore = _score;
      await prefs.setInt('highScore', highScore);
    }
    await prefs.setInt('wallet', wallet);
    await prefs.setInt('healthLevel', healthLevel);
    await prefs.setInt('speedLevel', speedLevel);
    await prefs.setInt('fireRateLevel', fireRateLevel);
    await prefs.setInt('shieldRegenLevel', shieldRegenLevel);
    await prefs.setInt('missileLevel', missileLevel);
    await prefs.setInt('selectedDriver', selectedDriver);
    await prefs.setString('selectedTrailColor', selectedTrailColor);
    await prefs.setInt('currentMapIndex', currentMapIndex);
    await prefs.setString('unlockedMaps', unlockedMapIndices.join(','));
  }

  void setPlayerName(String name) {
    playerName = name;
    saveData();
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    playerName = "Commander";
    highScore = 0;
    wallet = 0;
    healthLevel = 0;
    speedLevel = 0;
    fireRateLevel = 0;
    shieldRegenLevel = 0;
    missileLevel = 0;
    selectedDriver = 0;
    selectedTrailColor = 'orange';
    currentMapIndex = 0;
    unlockedMapIndices = [0];
    await loadData();
  }

  bool buyMap(int index) {
    if (index < 0 || index >= maps.length) return false;
    if (unlockedMapIndices.contains(index)) return true;
    int cost = maps[index].cost;
    if (wallet >= cost) {
      wallet -= cost;
      unlockedMapIndices.add(index);
      saveData();
      audioManager.playSound('collect');
      return true;
    }
    return false;
  }

  void selectMap(int index) {
    if (unlockedMapIndices.contains(index)) {
      currentMapIndex = index;
      _updateBackground();
      saveData();
      audioManager.playSound('click');
    }
  }

  void _updateBackground() async {
    if (_currentBackground != null) {
      remove(_currentBackground!);
      _currentBackground = null;
    }
    if (currentMapIndex == 0) return;
    String asset = maps[currentMapIndex].asset;
    _currentBackground = await loadParallaxComponent(
      [ParallaxImageData(asset)],
      baseVelocity: Vector2(0, 50),
      velocityMultiplierDelta: Vector2(1, 1),
      repeat: ImageRepeat.repeat,
    );
    _currentBackground!.priority = -100;
    add(_currentBackground!);
  }

  void buyUpgrade(String type) {
    int cost = 0;
    int getLevelCost(int level) => 100 * (level + 1);
    if (type == 'health' && healthLevel < 5) {
      cost = getLevelCost(healthLevel);
      if (wallet >= cost) { wallet -= cost; healthLevel++; }
    } else if (type == 'speed' && speedLevel < 5) {
      cost = getLevelCost(speedLevel);
      if (wallet >= cost) { wallet -= cost; speedLevel++; }
    } else if (type == 'fireRate' && fireRateLevel < 5) {
      cost = getLevelCost(fireRateLevel);
      if (wallet >= cost) { wallet -= cost; fireRateLevel++; }
    } else if (type == 'shield' && shieldRegenLevel < 5) {
      cost = getLevelCost(shieldRegenLevel);
      if (wallet >= cost) { wallet -= cost; shieldRegenLevel++; }
    } else if (type == 'missile' && missileLevel < 5) {
      cost = getLevelCost(missileLevel);
      if (wallet >= cost) { wallet -= cost; missileLevel++; }
    }
    audioManager.playSound('collect');
    saveData();
  }

  void setTrailColor(String color) {
    selectedTrailColor = color;
    saveData();
  }

  // --- ABILITY FUNCTIONS ---

  void chargeEnergy(double amount) {
    energy += amount;
    if (energy > maxEnergy) energy = maxEnergy;
  }

  void consumeEnergy(double amount) {
    energy -= amount;
    if (energy < 0) energy = 0;
  }

  void activateTimeFreeze() {
    audioManager.playSound('collect');
    timeScale = 0.2;
    final overlay = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.blue.withOpacity(0.2),
      priority: 5,
    );
    add(overlay);
    add(TimerComponent(
      period: 5,
      removeOnFinish: true,
      onTick: () {
        timeScale = 1.0;
        overlay.removeFromParent();
      },
    ));
  }

  void activateBomb() {
    audioManager.playSound('explode1');
    shakeWorld(intensity: 20);

    // Flash White
    final flash = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.white,
      priority: 20,
    );
    add(flash);
    flash.add(OpacityEffect.fadeOut(
        EffectController(duration: 0.5), onComplete: () => flash.removeFromParent()));

    // --- FIX: Safely iterate and force destroy everything ---
    // We create a list copy (.toList()) because removing items while iterating them causes crashes.
    final asteroids = children.whereType<Asteroid>().toList();
    final enemies = children.whereType<Enemy>().toList();
    final bullets = children.whereType<EnemyLaser>().toList();

    for (final a in asteroids) {
      a.destroyInstantly(); // Custom method we will add to Asteroid
    }
    for (final e in enemies) {
      e.destroyInstantly(); // Custom method we will add to Enemy
    }
    for (final b in bullets) {
      b.removeFromParent();
    }
  }

  void activateSuperLaser() {
    // Calls the new 3-second mode in Player
    player.activateSuperLaserMode();
  }

  @override
  void startGame() async {
    audioManager.playMusic();
    _bossSpawned = false;

    energy = 0;
    timeScale = 1.0;

    await _createJoystick();
    await _createPlayer();
    _createShootButton();
    _createAsteroidSpawner();
    _createEnemySpawner();
    _createPickupSpawner();
    _createScoreDisplay();

    driverHud = DriverHud();
    add(driverHud);

    add(HealthBar());
    add(PauseButton());

    add(AbilityButton(
      label: "FREEZE",
      icon: Icons.ac_unit,
      color: Colors.cyanAccent,
      cost: 30,
      position: Vector2(size.x - 50, size.y - 280),
      onActivate: activateTimeFreeze,
    )..priority = 15);

    add(AbilityButton(
      label: "LASER",
      icon: Icons.flash_on,
      color: Colors.yellowAccent,
      cost: 60,
      position: Vector2(size.x - 110, size.y - 220),
      onActivate: activateSuperLaser,
    )..priority = 15);

    add(AbilityButton(
      label: "NUKE",
      icon: Icons.local_fire_department,
      color: Colors.redAccent,
      cost: 100,
      position: Vector2(size.x - 50, size.y - 160),
      onActivate: activateBomb,
    )..priority = 15);
  }

  Future<void> _createPlayer() async {
    player = Player()
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y * 0.8);
    add(player);
  }

  Future<void> _createJoystick() async {
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: await loadSprite('joystick_knob.png'),
        size: Vector2.all(50),
      ),
      background: SpriteComponent(
        sprite: await loadSprite('joystick_background.png'),
        size: Vector2.all(100),
      ),
      anchor: Anchor.bottomLeft,
      position: Vector2(20, size.y - 20),
      priority: 10,
    );
    add(joystick);
  }

  void _createShootButton() {
    _shootButton = ShootButton()
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - 20, size.y - 20)
      ..priority = 10;
    add(_shootButton);
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(
        position: _generateSpawnPosition(),
        speedMultiplier: difficultyMultiplier,
      ),
      minPeriod: 1.5,
      maxPeriod: 3.0,
      selfPositioning: true,
    );
    add(_asteroidSpawner);
  }

  void _createEnemySpawner() {
    _enemySpawner = SpawnComponent.periodRange(
      factory: (index) => Enemy(
        position: _generateSpawnPosition(),
        speedMultiplier: difficultyMultiplier,
      ),
      minPeriod: 2.0,
      maxPeriod: 4.0,
      selfPositioning: true,
    );
    add(_enemySpawner);
  }

  void _createPickupSpawner() {
    _pickupSpawner = SpawnComponent.periodRange(
      factory: (index) => Pickup(
        position: _generateSpawnPosition(),
        pickupType:
            PickupType.values[_random.nextInt(PickupType.values.length)],
      ),
      minPeriod: 5.0,
      maxPeriod: 10.0,
      selfPositioning: true,
    );
    add(_pickupSpawner);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(
      10 + _random.nextDouble() * (size.x - 10 * 2),
      -100,
    );
  }

  void _createScoreDisplay() {
    _score = 0;
    _scoreDisplay = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 20),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2),
          ],
        ),
      ),
    );
    add(_scoreDisplay);
  }

  int get currentScore => _score;

  void incrementScore(int amount) {
    _score += amount;
    _scoreDisplay.text = _score.toString();
    _scoreDisplay.add(ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(duration: 0.05, alternate: true, curve: Curves.easeInOut),
    ));
    if (_score >= 200 && !_bossSpawned) {
      _spawnBoss();
    }
  }

  void _spawnBoss() {
    _bossSpawned = true;
    _enemySpawner.timer.stop();
    add(Boss());
  }

  void bossDefeated() {
    _enemySpawner.timer.start();
  }

  void _createStars() {
    for (int i = 0; i < 50; i++) {
      add(Star()..priority = -10);
    }
  }

  void playerDied() async {
    wallet += _score;
    await saveData();
    overlays.add('GameOver');
    pauseEngine();
  }

  void restartGame() {
    children.whereType<PositionComponent>().forEach((component) {
      if (component is Asteroid ||
          component is Pickup ||
          component is HealthBar ||
          component is Enemy ||
          component is EnemyLaser ||
          component is PauseButton ||
          component is Boss ||
          component is DriverHud ||
          component is AbilityButton) {
        remove(component);
      }
    });

    _bossSpawned = false;
    _asteroidSpawner.timer.start();
    _pickupSpawner.timer.start();
    _enemySpawner.timer.start();
    camera.viewfinder.children.whereType<MoveEffect>().forEach((e) => e.removeFromParent());
    camera.viewfinder.position = Vector2.zero();
    _score = 0;
    _scoreDisplay.text = '0';

    _createPlayer();
    driverHud = DriverHud();
    add(driverHud);
    add(HealthBar());
    add(PauseButton());

    add(AbilityButton(
      label: "FREEZE",
      icon: Icons.ac_unit,
      color: Colors.cyanAccent,
      cost: 30,
      position: Vector2(size.x - 50, size.y - 280),
      onActivate: activateTimeFreeze,
    )..priority = 15);

    add(AbilityButton(
      label: "LASER",
      icon: Icons.flash_on,
      color: Colors.yellowAccent,
      cost: 60,
      position: Vector2(size.x - 110, size.y - 220),
      onActivate: activateSuperLaser,
    )..priority = 15);

    add(AbilityButton(
      label: "NUKE",
      icon: Icons.local_fire_department,
      color: Colors.redAccent,
      cost: 100,
      position: Vector2(size.x - 50, size.y - 160),
      onActivate: activateBomb,
    )..priority = 15);

    energy = 0;
    timeScale = 1.0;

    resumeEngine();
  }

  void quitGame() {
    final itemsToRemove = children.whereType<PositionComponent>().toList();
    for (final component in itemsToRemove) {
      if (component is! Star && component is! ParallaxComponent) {
        if (component.parent != null) component.removeFromParent();
      }
    }
    if (_asteroidSpawner.parent != null) _asteroidSpawner.removeFromParent();
    if (_pickupSpawner.parent != null) _pickupSpawner.removeFromParent();
    if (_enemySpawner.parent != null) _enemySpawner.removeFromParent();

    overlays.remove('GameOver');
    overlays.remove('Pause');
    overlays.add('MainMenu');

    resumeEngine();
  }

  void shakeWorld({double intensity = 10, double duration = 0.05}) {
    if (camera.viewfinder.children.whereType<MoveEffect>().isNotEmpty) return;
    camera.viewfinder.add(
      MoveEffect.by(
        Vector2(intensity, intensity),
        EffectController(
          duration: duration,
          alternate: true,
          repeatCount: 4,
        ),
      ),
    );
  }
}