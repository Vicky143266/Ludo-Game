import 'package:flutter/material.dart';

import '../models/game_enums.dart';
import '../state/game_state.dart';
import 'dice_widget.dart';

class DicePanel extends StatelessWidget {
  final GameState gameState;

  const DicePanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    if (gameState.players.isEmpty) return const SizedBox(height: 180);

    final currentPlayer = gameState.currentPlayer;
    final playerColor = currentPlayer.color.color;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0221), Color(0xFF1A0545)],
        ),
        border: Border(
          top: BorderSide(
            color: playerColor.withOpacity(0.6),
            width: 2.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: playerColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: playerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentPlayer.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (currentPlayer.isAI) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.purple.withOpacity(0.5)),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Token progress indicators
                  Row(
                    children: List.generate(4, (i) {
                      final token = currentPlayer.tokens[i];
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: token.isFinished
                              ? playerColor
                              : token.isHome
                                  ? Colors.white.withOpacity(0.15)
                                  : playerColor.withOpacity(0.6),
                          border: Border.all(
                            color: playerColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: token.isFinished
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // Consecutive sixes indicator
                  if (gameState.consecutiveSixes > 0)
                    Row(
                      children: List.generate(
                        gameState.consecutiveSixes,
                        (_) => const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.star_rounded,
                              color: Colors.amber, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Dice
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DiceWidget(
                  value: gameState.diceValue,
                  isRolling: gameState.isRolling,
                  onRoll: () {},
                ),
                const SizedBox(height: 12),
                _RollButton(gameState: gameState, playerColor: playerColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RollButton extends StatelessWidget {
  final GameState gameState;
  final Color playerColor;

  const _RollButton({required this.gameState, required this.playerColor});

  @override
  Widget build(BuildContext context) {
    final canRoll = gameState.canRoll;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: canRoll ? 1.0 : 0.4,
      child: SizedBox(
        width: 120,
        height: 40,
        child: ElevatedButton(
          onPressed: canRoll ? gameState.rollDice : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: playerColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: playerColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: canRoll ? 4 : 0,
          ),
          child: Text(
            gameState.isRolling
                ? 'Rolling...'
                : gameState.isDiceRolled
                    ? 'Rolled: ${gameState.diceValue}'
                    : 'ROLL DICE',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
