import 'package:cosmic_havoc/my_game.dart';
import 'package:cosmic_havoc/overlays/game_over_overlay.dart';
import 'package:cosmic_havoc/overlays/pause_overlay.dart';
import 'package:cosmic_havoc/overlays/title_overlay.dart';
import 'package:cosmic_havoc/overlays/upgrade_overlay.dart';
import 'package:cosmic_havoc/overlays/map_selection_overlay.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CosmicHavocApp());
}

class CosmicHavocApp extends StatelessWidget {
  const CosmicHavocApp({super.key});

  @override
  Widget build(BuildContext context) {
    final MyGame game = MyGame();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;

          // 📱 Mobile scaling
          final double scaleFactor = screenWidth < 600 ? 0.75 : 1.0;

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: Center(
              child: Transform.scale(
                scale: scaleFactor,
                child: SizedBox(
                  width: screenWidth,
                  height: constraints.maxHeight,
                  child: GameWidget(
                    game: game,
                    overlayBuilderMap: {
                      'GameOver': (context, MyGame game) =>
                          GameOverOverlay(game: game),
                      'Title': (context, MyGame game) =>
                          TitleOverlay(game: game),
                      'Pause': (context, MyGame game) =>
                          PauseOverlay(game: game),
                      'Upgrades': (context, MyGame game) =>
                          UpgradeOverlay(game: game),
                      'MapSelection': (context, MyGame game) =>
                          MapSelectionOverlay(game: game),
                    },
                    initialActiveOverlays: const ['Title'],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
