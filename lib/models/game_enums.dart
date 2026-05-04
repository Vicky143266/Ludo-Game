import 'package:flutter/material.dart';

enum PlayerColor { red, green, yellow, blue }

enum GameMode { twoPlayer, threePlayer, fourPlayer, vsAI }

extension PlayerColorExtension on PlayerColor {
  Color get color {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFFF1744);
      case PlayerColor.green:
        return const Color(0xFF00E676);
      case PlayerColor.yellow:
        return const Color(0xFFFFD600);
      case PlayerColor.blue:
        return const Color(0xFF2979FF);
    }
  }

  Color get lightColor {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFFF8A80);
      case PlayerColor.green:
        return const Color(0xFFB9F6CA);
      case PlayerColor.yellow:
        return const Color(0xFFFFFF8D);
      case PlayerColor.blue:
        return const Color(0xFF82B1FF);
    }
  }

  String get name {
    switch (this) {
      case PlayerColor.red:
        return 'Red';
      case PlayerColor.green:
        return 'Green';
      case PlayerColor.yellow:
        return 'Yellow';
      case PlayerColor.blue:
        return 'Blue';
    }
  }
}

extension GameModeExtension on GameMode {
  String get label {
    switch (this) {
      case GameMode.twoPlayer:
        return '2 Players';
      case GameMode.threePlayer:
        return '3 Players';
      case GameMode.fourPlayer:
        return '4 Players';
      case GameMode.vsAI:
        return 'Play with AI';
    }
  }

  String get subtitle {
    switch (this) {
      case GameMode.twoPlayer:
        return 'Best for quick games';
      case GameMode.threePlayer:
        return 'Balanced competition';
      case GameMode.fourPlayer:
        return 'Full Ludo experience';
      case GameMode.vsAI:
        return 'Challenge the computer';
    }
  }

  int get playerCount {
    switch (this) {
      case GameMode.twoPlayer:
        return 2;
      case GameMode.threePlayer:
        return 3;
      case GameMode.fourPlayer:
        return 4;
      case GameMode.vsAI:
        return 2;
    }
  }
}
