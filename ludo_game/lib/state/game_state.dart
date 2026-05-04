import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/board_path.dart';
import '../models/game_enums.dart';
import '../models/player.dart';
import '../models/token.dart';
import '../services/sound_service.dart';

class GameState extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  List<Player> players = [];
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool isDiceRolled = false;
  bool isRolling = false;
  bool isMoving = false;
  bool gameOver = false;
  Player? winner;
  GameMode mode = GameMode.fourPlayer;
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool isPaused = false;
  int consecutiveSixes = 0;
  List<Token> highlightedTokens = [];
  String statusMessage = '';

  final SoundService _sound;
  final Random _random = Random();

  GameState(this._sound);

  // ── Initialisation ─────────────────────────────────────────────────────────
  void initGame(GameMode gameMode, {String playerName = 'Player'}) {
    mode = gameMode;
    gameOver = false;
    winner = null;
    currentPlayerIndex = 0;
    diceValue = 1;
    isDiceRolled = false;
    isRolling = false;
    isMoving = false;
    consecutiveSixes = 0;
    highlightedTokens = [];
    statusMessage = '';

    players = _buildPlayers(gameMode, playerName);
    notifyListeners();
  }

  List<Player> _buildPlayers(GameMode gameMode, String playerName) {
    switch (gameMode) {
      case GameMode.twoPlayer:
        return [
          Player(
            name: playerName,
            color: PlayerColor.red,
            startIndex: BoardPath.startIndices[PlayerColor.red]!,
          ),
          Player(
            name: 'Player 2',
            color: PlayerColor.blue,
            startIndex: BoardPath.startIndices[PlayerColor.blue]!,
          ),
        ];
      case GameMode.threePlayer:
        return [
          Player(
            name: playerName,
            color: PlayerColor.red,
            startIndex: BoardPath.startIndices[PlayerColor.red]!,
          ),
          Player(
            name: 'Player 2',
            color: PlayerColor.green,
            startIndex: BoardPath.startIndices[PlayerColor.green]!,
          ),
          Player(
            name: 'Player 3',
            color: PlayerColor.blue,
            startIndex: BoardPath.startIndices[PlayerColor.blue]!,
          ),
        ];
      case GameMode.fourPlayer:
        return [
          Player(
            name: playerName,
            color: PlayerColor.red,
            startIndex: BoardPath.startIndices[PlayerColor.red]!,
          ),
          Player(
            name: 'Player 2',
            color: PlayerColor.green,
            startIndex: BoardPath.startIndices[PlayerColor.green]!,
          ),
          Player(
            name: 'Player 3',
            color: PlayerColor.yellow,
            startIndex: BoardPath.startIndices[PlayerColor.yellow]!,
          ),
          Player(
            name: 'Player 4',
            color: PlayerColor.blue,
            startIndex: BoardPath.startIndices[PlayerColor.blue]!,
          ),
        ];
      case GameMode.vsAI:
        return [
          Player(
            name: playerName,
            color: PlayerColor.red,
            startIndex: BoardPath.startIndices[PlayerColor.red]!,
          ),
          Player(
            name: 'AI',
            color: PlayerColor.blue,
            startIndex: BoardPath.startIndices[PlayerColor.blue]!,
            isAI: true,
          ),
        ];
    }
  }

  // ── Accessors ──────────────────────────────────────────────────────────────
  Player get currentPlayer => players[currentPlayerIndex];

  bool get canRoll =>
      !isRolling && !isDiceRolled && !isPaused && !gameOver && !isMoving;

  // ── Dice ───────────────────────────────────────────────────────────────────
  Future<void> rollDice() async {
    if (!canRoll) return;

    isRolling = true;
    notifyListeners();

    await _sound.play(SoundEffect.diceRoll);
    HapticFeedback.mediumImpact();

    // Simulate rolling animation delay (actual animation is in DiceWidget)
    await Future.delayed(const Duration(milliseconds: 1000));

    final value = _random.nextInt(6) + 1;
    diceValue = value;
    isRolling = false;
    isDiceRolled = true;

    if (value == 6) {
      await _sound.play(SoundEffect.diceSix);
    } else {
      await _sound.play(SoundEffect.diceResult);
    }

    _onDiceRolled(value);
  }

  /// Called internally after dice value is determined.
  void _onDiceRolled(int value) {
    if (value == 6) {
      consecutiveSixes++;
      if (consecutiveSixes == 3) {
        consecutiveSixes = 0;
        statusMessage = 'Three sixes! Turn cancelled.';
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 1200), _nextTurn);
        return;
      }
    } else {
      consecutiveSixes = 0;
    }

    final validTokens = _getValidTokens(currentPlayer, value);

    if (validTokens.isEmpty) {
      statusMessage = 'No moves available!';
      _sound.play(SoundEffect.invalidMove);
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 1200), _nextTurn);
      return;
    }

    if (validTokens.length == 1) {
      statusMessage = '';
      notifyListeners();
      _moveToken(currentPlayer, validTokens[0], value);
    } else {
      highlightedTokens = validTokens;
      statusMessage = 'Select a token to move';
      notifyListeners();
    }
  }

  // ── Token Selection ────────────────────────────────────────────────────────
  void selectToken(Token token) {
    if (!isDiceRolled || isMoving || gameOver) return;
    if (!highlightedTokens.any((t) => t.id == token.id && t.color == token.color)) return;

    highlightedTokens = [];
    statusMessage = '';
    notifyListeners();

    _moveToken(currentPlayer, token, diceValue);
  }

  // ── Valid Moves ────────────────────────────────────────────────────────────
  List<Token> _getValidTokens(Player player, int dice) {
    return player.tokens.where((t) {
      if (t.isFinished) return false;
      if (t.isHome) return dice == 6; // needs 6 to enter board
      if (t.position >= 52) {
        // In home path (positions 52–56), needs exact or room to move
        final spacesLeft = 57 - t.position;
        return dice <= spacesLeft;
      }
      // On main board — check if moving into home path is valid
      final spacesLeft = 52 - t.position; // steps to reach home path entry
      if (dice > spacesLeft + 5) return false; // would overshoot home path
      return true;
    }).toList();
  }

  // ── Token Movement ─────────────────────────────────────────────────────────
  Future<void> _moveToken(Player player, Token token, int steps) async {
    isMoving = true;
    notifyListeners();

    for (int i = 0; i < steps; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      _advanceToken(token, player);
      if (!token.isFinished) {
        await _sound.play(SoundEffect.tokenMove);
      }
      notifyListeners();
    }

    isMoving = false;
    await _onTokenLanded(player, token);
  }

  void _advanceToken(Token token, Player player) {
    if (token.isHome) {
      // Enter the board
      token.position = 0;
      token.isHome = false;
      _sound.play(SoundEffect.tokenEntry);
      return;
    }

    token.position++;

    // Transition from main path to home path
    if (token.position == 52) {
      // Entered home path
      token.position = 52;
    }

    // Finished
    if (token.position >= 57) {
      token.position = 57;
      token.isFinished = true;
      player.finishedCount++;
      _sound.play(SoundEffect.tokenFinish);
    }
  }

  Future<void> _onTokenLanded(Player player, Token token) async {
    if (token.isFinished) {
      _checkWin(player);
      if (!gameOver) _nextTurn();
      return;
    }

    // Check capture (only on main board)
    if (token.position < 52) {
      _checkCapture(player, token);
    }

    if (!gameOver) _nextTurn();
  }

  // ── Capture ────────────────────────────────────────────────────────────────
  void _checkCapture(Player attacker, Token attackerToken) {
    final attackerGlobal = BoardPath.getGlobalIndex(
      attackerToken.position,
      attacker.color,
    );

    // Safe zone — no capture
    if (BoardPath.isSafeIndex(attackerGlobal)) return;

    for (final opponent in players) {
      if (opponent.color == attacker.color) continue;

      for (final opToken in opponent.tokens) {
        if (opToken.isHome || opToken.isFinished || opToken.position >= 52) {
          continue;
        }

        final opGlobal = BoardPath.getGlobalIndex(
          opToken.position,
          opponent.color,
        );

        if (opGlobal != attackerGlobal) continue;

        // Check if opponent has a stack (2+ tokens) — safe stack
        final stackCount = opponent.tokens
            .where((t) =>
                !t.isHome &&
                !t.isFinished &&
                t.position < 52 &&
                BoardPath.getGlobalIndex(t.position, opponent.color) ==
                    opGlobal)
            .length;

        if (stackCount >= 2) continue;

        // Capture!
        opToken.position = -1;
        opToken.isHome = true;
        HapticFeedback.heavyImpact();
        _sound.play(SoundEffect.tokenCapture);
        statusMessage = '${attacker.name} captured ${opponent.name}\'s token!';

        // Reward: treat like rolling a 6 (extra turn)
        consecutiveSixes = 0;
        diceValue = 6;
        notifyListeners();
      }
    }
  }

  // ── Win Check ──────────────────────────────────────────────────────────────
  void _checkWin(Player player) {
    if (player.finishedCount == 4) {
      gameOver = true;
      winner = player;
      HapticFeedback.vibrate();
      _sound.play(SoundEffect.victory);
      notifyListeners();
      // Navigation is handled by the GameScreen listener
    }
  }

  // ── Turn Advancement ───────────────────────────────────────────────────────
  void _nextTurn() {
    isDiceRolled = false;
    highlightedTokens = [];
    statusMessage = '';

    // Keep turn if rolled a 6 (and not 3-six cancel) or captured
    final keepTurn = diceValue == 6 && consecutiveSixes > 0;

    if (!keepTurn) {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      // Skip players who have finished
      int safety = 0;
      while (players[currentPlayerIndex].hasWon && safety < players.length) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
        safety++;
      }
    }

    notifyListeners();

    if (currentPlayer.isAI && !gameOver) {
      _triggerAI();
    }
  }

  // ── AI ─────────────────────────────────────────────────────────────────────
  Future<void> _triggerAI() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (gameOver || !currentPlayer.isAI) return;

    // Simulate dice roll
    isRolling = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));

    final value = _random.nextInt(6) + 1;
    diceValue = value;
    isRolling = false;
    isDiceRolled = true;

    if (value == 6) {
      await _sound.play(SoundEffect.diceSix);
    } else {
      await _sound.play(SoundEffect.diceResult);
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));

    if (value == 6) {
      consecutiveSixes++;
      if (consecutiveSixes == 3) {
        consecutiveSixes = 0;
        statusMessage = 'AI: Three sixes! Turn cancelled.';
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 1000), _nextTurn);
        return;
      }
    } else {
      consecutiveSixes = 0;
    }

    final validTokens = _getValidTokens(currentPlayer, value);
    if (validTokens.isEmpty) {
      statusMessage = 'AI: No moves available!';
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 1000), _nextTurn);
      return;
    }

    final chosen = _aiChooseToken(validTokens, value);
    await _moveToken(currentPlayer, chosen, value);
  }

  Token _aiChooseToken(List<Token> tokens, int dice) {
    // Priority 1: Can capture an opponent?
    for (final t in tokens) {
      if (t.isHome) continue;
      final futurePos = t.position + dice;
      if (futurePos >= 52) continue; // entering home path, no capture
      final futureGlobal = BoardPath.getGlobalIndex(futurePos, currentPlayer.color);

      for (final opp in players) {
        if (opp.color == currentPlayer.color) continue;
        for (final ot in opp.tokens) {
          if (ot.isHome || ot.isFinished || ot.position >= 52) continue;
          final opGlobal = BoardPath.getGlobalIndex(ot.position, opp.color);
          if (opGlobal == futureGlobal &&
              !BoardPath.isSafeIndex(futureGlobal)) {
            return t;
          }
        }
      }
    }

    // Priority 2: Enter a new token if dice == 6 and tokens still home
    if (dice == 6) {
      final homeToken = tokens.firstWhere((t) => t.isHome, orElse: () => tokens.first);
      if (homeToken.isHome) return homeToken;
    }

    // Priority 3: Move token closest to finish
    final onBoard = tokens.where((t) => !t.isHome).toList();
    if (onBoard.isNotEmpty) {
      onBoard.sort((a, b) => b.position.compareTo(a.position));
      return onBoard.first;
    }

    return tokens.first;
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  void togglePause() {
    isPaused = !isPaused;
    notifyListeners();
  }

  void toggleSound() {
    soundEnabled = !soundEnabled;
    _sound.soundEnabled = soundEnabled;
    notifyListeners();
  }

  void toggleMusic() {
    musicEnabled = !musicEnabled;
    _sound.setMusicEnabled(musicEnabled);
    if (musicEnabled) {
      // Resume background music when toggled back on
      _sound.startMusic('audio/victory.mp3'); // replace with bg_music.mp3 when available
    }
    notifyListeners();
  }

  void restartGame() {
    for (final p in players) {
      p.reset();
    }
    currentPlayerIndex = 0;
    diceValue = 1;
    isDiceRolled = false;
    isRolling = false;
    isMoving = false;
    gameOver = false;
    winner = null;
    consecutiveSixes = 0;
    highlightedTokens = [];
    statusMessage = '';
    isPaused = false;
    notifyListeners();
  }
}
