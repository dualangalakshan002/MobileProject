import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

class UpgradeOverlay extends StatefulWidget {
  final MyGame game;

  const UpgradeOverlay({super.key, required this.game});

  @override
  State<UpgradeOverlay> createState() => _UpgradeOverlayState();
}

class _UpgradeOverlayState extends State<UpgradeOverlay> {

  // Cost Formula: 100 * (Level + 1). Ex: Lvl 0->1 costs 100. Lvl 1->2 costs 200.
  int getCost(int level) => 100 * (level + 1);

  void buyUpgrade(String type) {
    setState(() {
      widget.game.buyUpgrade(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(230),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'SHIP HANGAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Wallet Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.yellow),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                const SizedBox(width: 10),
                Text(
                  'CREDITS: ${widget.game.wallet}',
                  style: const TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // UPGRADE 1: HULL (Health)
          _buildUpgradeRow(
            'Hull Armor',
            Icons.shield,
            widget.game.healthLevel,
            () => buyUpgrade('health')
          ),

          // UPGRADE 2: THRUSTERS (Speed)
          _buildUpgradeRow(
            'Thrusters',
            Icons.speed,
            widget.game.speedLevel,
            () => buyUpgrade('speed')
          ),

          // UPGRADE 3: BLASTERS (Fire Rate)
          _buildUpgradeRow(
            'Laser Cannons',
            Icons.flash_on,
            widget.game.fireRateLevel,
            () => buyUpgrade('fireRate')
          ),

          const Spacer(),

          // BACK BUTTON
          ElevatedButton(
            onPressed: () {
              widget.game.audioManager.playSound('click');
              widget.game.overlays.remove('Upgrades');
              widget.game.overlays.add('Title');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('BACK TO MENU', style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeRow(String name, IconData icon, int level, VoidCallback onBuy) {
    int cost = getCost(level);
    bool canAfford = widget.game.wallet >= cost;
    bool isMaxed = level >= 5; // Max level 5

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Level: ${level} / 5', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          isMaxed
          ? const Text('MAXED', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold))
          : ElevatedButton(
              onPressed: canAfford ? onBuy : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? Colors.green : Colors.grey[800],
              ),
              child: Text(
                'Buy: $cost',
                style: TextStyle(color: canAfford ? Colors.white : Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}