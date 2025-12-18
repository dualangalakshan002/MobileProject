import 'package:cosmic_havoc/my_game.dart';
import 'package:cosmic_havoc/overlays/map_selection_overlay.dart';
import 'package:cosmic_havoc/overlays/upgrade_overlay.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math; // For the 3D rotation math

class MainMenuOverlay extends StatefulWidget {
  final MyGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Define pages here so they rebuild when state changes
    final List<Widget> pages = [
      _buildHomePage(),      // 0: Home
      HangarWidget(game: widget.game), // 1: Advanced Hangar (Replacing Shop)
      _buildMapPage(),       // 2: Maps
      _buildProfilePage(),   // 3: Logs
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.black.withAlpha(180),
        child: SafeArea(
          child: Column(
            children: [
              // --- CONTENT AREA ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: pages[_selectedIndex],
                    ),
                  ),
                ),
              ),

              // --- BOTTOM NAVIGATION BAR ---
              Container(
                margin: const EdgeInsets.all(20),
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(100),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                    const BoxShadow(
                      color: Colors.white10,
                      blurRadius: 1,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, "Home"),
                    _buildNavItem(1, Icons.build_circle_rounded, "Hangar"), // Changed Icon
                    _buildNavItem(2, Icons.grid_view_rounded, "Maps"),
                    _buildNavItem(3, Icons.receipt_long_rounded, "Logs"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        widget.game.audioManager.playSound('click');
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withAlpha(50) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blueAccent : Colors.grey,
              size: 28,
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold
                ),
              )
          ],
        ),
      ),
    );
  }

  // --- PAGE 1: HOME ---
  Widget _buildHomePage() {
    final String playerColor = widget.game.playerColors[widget.game.playerColorIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/title.png', width: 300),
        const SizedBox(height: 30),

        // --- SHIP SELECTOR ROW ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 30),
              onPressed: () {
                widget.game.audioManager.playSound('click');
                setState(() {
                  widget.game.playerColorIndex--;
                  if (widget.game.playerColorIndex < 0) {
                    widget.game.playerColorIndex = widget.game.playerColors.length - 1;
                  }
                });
              },
            ),
            Container(
              height: 150,
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getShipColor(playerColor).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]
              ),
              child: Image.asset(
                'assets/images/player_${playerColor}_off.png',
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 30),
              onPressed: () {
                widget.game.audioManager.playSound('click');
                setState(() {
                  widget.game.playerColorIndex++;
                  if (widget.game.playerColorIndex >= widget.game.playerColors.length) {
                    widget.game.playerColorIndex = 0;
                  }
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 10),
        Text(
          playerColor.toUpperCase(),
          style: TextStyle(
            color: _getShipColor(playerColor),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2
          )
        ),

        const SizedBox(height: 50),

        GestureDetector(
          onTap: () {
             widget.game.audioManager.playSound('start');
             widget.game.startGame();
             widget.game.overlays.remove('MainMenu');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.blueAccent, blurRadius: 15)],
            ),
            child: const Text(
              "PLAY GAME",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Color _getShipColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.redAccent;
      case 'green': return Colors.greenAccent;
      case 'purple': return Colors.purpleAccent;
      default: return Colors.blueAccent;
    }
  }

  // --- PAGE 3: MAPS ---
  Widget _buildMapPage() {
    return MapSelectionWidget(game: widget.game);
  }

  // --- PAGE 4: LOGS (PROFILE) ---
  Widget _buildProfilePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'PILOT LOGS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 30),

          // PROFILE CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.2),
                  Colors.purple.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.5),
                            blurRadius: 15,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: AssetImage(
                            'assets/images/driver_${widget.game.selectedDriver}.png'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("COMMANDER ID",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  letterSpacing: 1.5)),
                          Text(
                            widget.game.playerName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber)),
                            child: Text(
                              "HIGH SCORE: ${widget.game.highScore}",
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () => _showEditProfileDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("CREDITS", "${widget.game.wallet}", Icons.monetization_on),
                    _buildStatItem("SHIPS", "${widget.game.speedLevel + 1}/5", Icons.rocket_launch),
                    _buildStatItem("MAPS", "${widget.game.unlockedMapIndices.length}/4", Icons.map),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // SETTINGS
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("SYSTEM SETTINGS",
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 10),
          _buildSwitchTile(
            "Music System",
            widget.game.audioManager.musicEnabled,
            (bool newValue) {
              setState(() {
                widget.game.audioManager.toggleMusic();
              });
            },
          ),
          _buildSwitchTile(
            "SFX System",
            widget.game.audioManager.soundsEnabled,
            (bool newValue) {
              setState(() {
                widget.game.audioManager.toggleSounds();
              });
            },
          ),

          const SizedBox(height: 20),

          // DANGER ZONE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  "DANGER ZONE",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text("RESET PILOT PROFILE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
            inactiveTrackColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: widget.game.playerName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Pilot ID", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Enter Pilot Name",
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.game.setPlayerName(controller.text);
                });
                Navigator.pop(context);
                widget.game.audioManager.playSound('click');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("Save ID", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Factory Reset", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "Are you sure? This will wipe your High Score, Credits, Upgrades, and Map Unlocks forever.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.game.resetProgress();
              setState(() {});
              Navigator.pop(context);
              widget.game.audioManager.playSound('explode1');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("WIPE DATA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
//  NEW ADVANCED HANGAR WIDGET (Replaces UpgradeWidget)
// --------------------------------------------------------------------------
class HangarWidget extends StatefulWidget {
  final MyGame game;
  const HangarWidget({super.key, required this.game});

  @override
  State<HangarWidget> createState() => _HangarWidgetState();
}

class _HangarWidgetState extends State<HangarWidget> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 3 Tabs: Systems, Combat, Visuals
    _tabController = TabController(length: 3, vsync: this);
  }

  void _buyUpgrade(String type) {
    setState(() {
      widget.game.buyUpgrade(type);
    });
  }

  int getCost(int level) => 100 * (level + 1);

  @override
  Widget build(BuildContext context) {
    final String shipAsset = 'assets/images/player_${widget.game.playerColors[widget.game.playerColorIndex]}_off.png';

    return Column(
      children: [
        // --- HEADER ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SHIP HANGAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(20),
                color: Colors.black45,
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.game.wallet}',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // --- 3D HOLOGRAPHIC PREVIEW ---
        Expanded(
          flex: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grid Floor Effect
              Positioned(
                bottom: 20,
                child: Container(
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.blueAccent.withOpacity(0.2), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              // The 3D Ship
              Ship3DPreview(imagePath: shipAsset),

              // Stats Overview (Floating)
              Positioned(
                right: 0,
                top: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMiniStat("HP", widget.game.healthLevel, Colors.green),
                    _buildMiniStat("SPD", widget.game.speedLevel, Colors.blue),
                    _buildMiniStat("DMG", widget.game.fireRateLevel, Colors.red),
                  ],
                ),
              )
            ],
          ),
        ),

        // --- TABS ---
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "SYSTEMS"),
            Tab(text: "COMBAT"),
            Tab(text: "VISUALS"),
          ],
        ),

        const SizedBox(height: 10),

        // --- CONTENT AREA ---
        Expanded(
          flex: 5,
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. SYSTEMS TAB
              ListView(
                children: [
                  _buildUpgradeRow("Hull Armor", Icons.shield, widget.game.healthLevel, () => _buyUpgrade('health')),
                  _buildUpgradeRow("Ion Thrusters", Icons.speed, widget.game.speedLevel, () => _buyUpgrade('speed')),
                  _buildUpgradeRow("Shield Gen", Icons.security, widget.game.shieldRegenLevel, () => _buyUpgrade('shield')),
                ],
              ),
              // 2. COMBAT TAB
              ListView(
                children: [
                  _buildUpgradeRow("Plasma Cannons", Icons.flash_on, widget.game.fireRateLevel, () => _buyUpgrade('fireRate')),
                  _buildUpgradeRow("Missile Rack", Icons.rocket, widget.game.missileLevel, () => _buyUpgrade('missile')),
                ],
              ),
              // 3. VISUALS TAB (Customization)
              _buildVisualsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildMiniStat(String label, int level, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(width: 5),
          Row(
            children: List.generate(5, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 6, height: 4,
              color: i <= level ? color : Colors.white10,
            )),
          )
        ],
      ),
    );
  }

  Widget _buildUpgradeRow(String name, IconData icon, int level, VoidCallback onBuy) {
    int cost = getCost(level);
    bool canAfford = widget.game.wallet >= cost;
    bool isMaxed = level >= 5;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: List.generate(5, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 3),
                      width: 15, height: 5,
                      decoration: BoxDecoration(
                        color: index < level ? Colors.greenAccent : Colors.grey[800],
                        borderRadius: BorderRadius.circular(2),
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(80, 30),
                ),
                child: Text("\$$cost", style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
        ],
      ),
    );
  }

  Widget _buildVisualsTab() {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("SELECT PILOT", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
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
                    border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white24, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/images/driver_$index.png'),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(color: Colors.white12, height: 30),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("ENGINE TRAIL COLOR", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _colorOption('orange', Colors.orange),
            _colorOption('cyan', Colors.cyan),
            _colorOption('pink', Colors.pinkAccent),
            _colorOption('lime', Colors.limeAccent),
          ],
        )
      ],
    );
  }

  Widget _colorOption(String val, Color color) {
    bool isSelected = widget.game.selectedTrailColor == val;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.game.setTrailColor(val);
          widget.game.audioManager.playSound('click');
        });
      },
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)
          ]
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
//  3D PREVIEW WIDGET
//  Simulates 3D rotation using Transform matrix
// --------------------------------------------------------------------------
class Ship3DPreview extends StatefulWidget {
  final String imagePath;
  const Ship3DPreview({super.key, required this.imagePath});

  @override
  State<Ship3DPreview> createState() => _Ship3DPreviewState();
}

class _Ship3DPreviewState extends State<Ship3DPreview> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate rotation angle (-0.2 to 0.2 radians)
        double angleY = math.sin(_controller.value * math.pi * 2) * 0.1;
        double angleX = math.cos(_controller.value * math.pi * 2) * 0.05;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(angleY)
            ..rotateX(angleX),
          alignment: Alignment.center,
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}