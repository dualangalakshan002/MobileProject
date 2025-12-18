import 'package:cosmic_havoc/my_game.dart';
import 'package:cosmic_havoc/overlays/game_over_overlay.dart';
import 'package:cosmic_havoc/overlays/main_menu_overlay.dart';
import 'package:cosmic_havoc/overlays/pause_overlay.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  final MyGame game = MyGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // inclusive dark theme
      home: GameWidget(
        game: game,
        overlayBuilderMap: {
          'MainMenu': (context, MyGame game) => MainMenuOverlay(game: game),
          'GameOver': (context, MyGame game) => GameOverOverlay(game: game),
          'Pause': (context, MyGame game) => PauseOverlay(game: game),
        },
        // Start with the Main Menu
        initialActiveOverlays: const ['MainMenu'],
      ),
    ),
  );
}