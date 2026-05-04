import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_enums.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../state/game_state.dart';
import '../widgets/ludo_board_widget.dart';
import '../widgets/dice_panel.dart';
import 'result_screen.dart';

class GameScreen extends StatelessWidget {
  final GameMode mode;

  const GameScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final sound = context.read<SoundService>();
    return ChangeNotifierProvider(
      create: (_) {
        final gs = GameState(sound);
        // Fetch user name and init
        context.read<StorageService>().getUserName().then((name) {
          gs.initGame(mode, playerName: name ?? 'Player 1');
        });
        return gs;
      },
      child: _GameScreenBody(mode: mode),
    );
  }
}

class _GameScreenBody extends StatefulWidget {
  final GameMode mode;
  const _GameScreenBody({required this.mode});

  @override
  State<_GameScreenBody> createState() => _GameScreenBodyState();
}

class _GameScreenBodyState extends State<_GameScreenBody> {
  DateTime? _lastBackPress;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    // Start background music when the game screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sound = context.read<SoundService>();
      if (sound.musicEnabled) {
        sound.startMusic('audio/victory.mp3'); // replace with a bg_music.mp3 when available
      }
    });
  }

  @override
  void dispose() {
    // Stop background music when leaving the game screen
    final sound = context.read<SoundService>();
    sound.stopMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        // Navigate to result when game is over
        if (gameState.gameOver && gameState.winner != null && !_resultShown) {
          _resultShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, animation, __) =>
                    ResultScreen(winner: gameState.winner!),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            ).then((_) {
              // When result screen is popped (Play Again), restart
              _resultShown = false;
              gameState.restartGame();
            });
          });
        }

        final currentColor = gameState.players.isNotEmpty
            ? gameState.currentPlayer.color.color
            : const Color(0xFF3B1F8C);

        return WillPopScope(
          onWillPop: () async {
            final now = DateTime.now();
            if (_lastBackPress == null ||
                now.difference(_lastBackPress!) >
                    const Duration(seconds: 2)) {
              _lastBackPress = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                ),
              );
              return false;
            }
            return true;
          },
          child: Scaffold(
            body: Stack(
              children: [
                // Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D0221), Color(0xFF1A0545), Color(0xFF0A1628)],
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // AppBar
                      _GameAppBar(
                        currentColor: currentColor,
                        gameState: gameState,
                        onSettings: () => _showSettings(context, gameState),
                      ),

                      // Board
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: RepaintBoundary(
                            child: gameState.players.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const LudoBoardWidget(),
                          ),
                        ),
                      ),

                      // Dice panel
                      RepaintBoundary(
                        child: DicePanel(gameState: gameState),
                      ),
                    ],
                  ),
                ),

                // Pause overlay
                if (gameState.isPaused)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context, GameState gameState) {
    gameState.togglePause();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0221),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SettingsSheet(gameState: gameState),
    ).then((_) {
      if (gameState.isPaused) gameState.togglePause();
    });
  }
}

class _GameAppBar extends StatelessWidget {
  final Color currentColor;
  final GameState gameState;
  final VoidCallback onSettings;

  const _GameAppBar({
    required this.currentColor,
    required this.gameState,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: currentColor.withOpacity(0.25),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Current player indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: currentColor.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: gameState.players.isEmpty
                ? const SizedBox()
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      gameState.statusMessage.isNotEmpty
                          ? gameState.statusMessage
                          : "${gameState.currentPlayer.name}'s Turn",
                      key: ValueKey(gameState.statusMessage +
                          gameState.currentPlayerIndex.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
          ),
          // Player tokens summary
          if (gameState.players.isNotEmpty)
            Row(
              children: gameState.players.map((p) {
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: p.color.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final GameState gameState;

  const _SettingsSheet({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Sound Effects',
                style: TextStyle(color: Colors.white)),
            subtitle: Text('Game sounds',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
            value: gameState.soundEnabled,
            activeColor: const Color(0xFF7C4DFF),
            onChanged: (_) => gameState.toggleSound(),
          ),
          SwitchListTile(
            title:
                const Text('Music', style: TextStyle(color: Colors.white)),
            subtitle: Text('Background music',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
            value: gameState.musicEnabled,
            activeColor: const Color(0xFF7C4DFF),
            onChanged: (_) => gameState.toggleMusic(),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.refresh_rounded, color: Colors.orange),
            title: const Text('Restart Game',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF0D0221),
                  title: const Text('Restart Game?',
                      style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'All progress will be lost.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        gameState.restartGame();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      child: const Text('Restart'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
            title: const Text('Exit Match',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF0D0221),
                  title: const Text('Exit Match?',
                      style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'You will lose your current game.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
