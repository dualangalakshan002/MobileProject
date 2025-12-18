import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

// Changed to a simple widget to be used inside the Main Menu
class UpgradeWidget extends StatefulWidget {
  final MyGame game;

  const UpgradeWidget({super.key, required this.game});

  @override
  State<UpgradeWidget> createState() => _UpgradeWidgetState();
}

class _UpgradeWidgetState extends State<UpgradeWidget> {
  // Cost Formula: 100 * (Level + 1)
  int getCost(int level) => 100 * (level + 1);

  void buyUpgrade(String type) {
    setState(() {
      widget.game.buyUpgrade(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'SHIP HANGAR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),

        // Wallet Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.yellow),
            borderRadius: BorderRadius.circular(20),
            color: Colors.black45,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.yellow, size: 20),
              const SizedBox(width: 10),
              Text(
                '${widget.game.wallet}',
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // --- DRIVER SELECTION ---
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const Center(
                child: Text('SELECT PILOT',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.game.playerColors.length, (index) {
                    bool isSelected = widget.game.selectedDriver == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.game.selectedDriver = index;
                          widget.game.saveData();
                          widget.game.audioManager.playSound('click');
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.greenAccent : Colors.white24,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [const BoxShadow(color: Colors.greenAccent, blurRadius: 10)]
                              : [],
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage:
                              AssetImage('assets/images/driver_$index.png'),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white24),

              // UPGRADES
              _buildUpgradeRow('Hull Armor', Icons.shield, widget.game.healthLevel,
                  () => buyUpgrade('health')),
              _buildUpgradeRow('Thrusters', Icons.rocket_launch, widget.game.speedLevel,
                  () => buyUpgrade('speed')),
              _buildUpgradeRow('Cannons', Icons.flash_on, widget.game.fireRateLevel,
                  () => buyUpgrade('fireRate')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeRow(
      String name, IconData icon, int level, VoidCallback onBuy) {
    int cost = getCost(level);
    bool canAfford = widget.game.wallet >= cost;
    bool isMaxed = level >= 5;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(5, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 2, top: 4),
                      width: 12,
                      height: 4,
                      color: index < level ? Colors.green : Colors.grey[800],
                    );
                  }),
                )
              ],
            ),
          ),
          isMaxed
              ? const Icon(Icons.check_circle, color: Colors.green)
              : ElevatedButton(
                  onPressed: canAfford ? onBuy : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? Colors.blue : Colors.grey[800],
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(60, 30),
                  ),
                  child: Text(
                    '$cost',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
        ],
      ),
    );
  }
}