# Flutter Ludo Game

A production-quality Flutter Ludo game with smooth animations, AI opponent, sound effects, and haptic feedback.

## Features

- **4 Game Modes**: 2 Players, 3 Players, 4 Players, vs AI
- **Complete Ludo Rules**: Captures, safe cells, home paths, consecutive-six cancellation
- **Animations**: Token movement, dice roll, splash screen, confetti on win
- **Sound Effects**: 9 distinct sound effects for all game events
- **Haptic Feedback**: Medium impact on dice roll, heavy impact on capture
- **AI Opponent**: Priority-based AI (capture > enter > advance closest token)
- **Settings**: Sound/music toggle, restart, exit match
- **Persistence**: Player name and preferences saved via SharedPreferences

## Setup

### 1. Prerequisites

- Flutter 3.x (stable channel)
- Dart SDK ≥ 3.0.0
- Android Studio / Xcode for device deployment

### 2. Install dependencies

```bash
cd ludo_game
flutter pub get
```

### 3. Add audio assets

Replace the placeholder `.mp3` files in `assets/audio/` with real audio files:

| File | Trigger |
|------|---------|
| `dice_roll.mp3` | When dice starts rolling |
| `dice_result.mp3` | When dice lands (non-six) |
| `dice_six.mp3` | When dice lands on 6 |
| `token_move.mp3` | Each step of token movement |
| `token_entry.mp3` | Token enters the board |
| `token_capture.mp3` | Token captures an opponent |
| `token_finish.mp3` | Token reaches the center |
| `victory.mp3` | Player wins the game |
| `invalid_move.mp3` | No valid moves available |

Free audio sources: [freesound.org](https://freesound.org), [mixkit.co](https://mixkit.co/free-sound-effects/)

### 4. Add fonts (optional)

The app uses `Poppins` font. Download from [Google Fonts](https://fonts.google.com/specimen/Poppins) and place in `assets/fonts/`:
- `Poppins-Regular.ttf`
- `Poppins-SemiBold.ttf`
- `Poppins-Bold.ttf`

Or remove the font references from `pubspec.yaml` to use the system default.

### 5. Run

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point, providers
├── models/
│   ├── game_enums.dart          # PlayerColor, GameMode enums + extensions
│   ├── token.dart               # Token data model
│   ├── player.dart              # Player data model
│   └── board_path.dart          # 15×15 grid path definitions
├── services/
│   ├── sound_service.dart       # Singleton audio player
│   └── storage_service.dart     # SharedPreferences wrapper
├── state/
│   └── game_state.dart          # ChangeNotifier — all game logic
├── screens/
│   ├── splash_screen.dart
│   ├── user_setup_screen.dart
│   ├── game_selection_screen.dart
│   ├── ludo_mode_screen.dart
│   ├── game_screen.dart
│   └── result_screen.dart
└── widgets/
    ├── ludo_board_widget.dart   # CustomPaint board + token overlay
    ├── token_widget.dart        # Animated token circle
    ├── dice_widget.dart         # Animated dice face
    └── dice_panel.dart          # Dice + roll button + player info
```

## Game Rules Implemented

- **Entry**: Requires rolling a 6 to move a token from home base onto the board
- **Capture**: Landing on an opponent's token sends it back to home base (safe cells are immune)
- **Safe cells**: 8 safe cells on the main path (start cells + cells before each start)
- **Stack protection**: 2+ same-color tokens on a cell cannot be captured
- **Home path**: 5-cell colored path leading to center; tokens must enter exactly or with room
- **Consecutive sixes**: Rolling three 6s in a row cancels the turn
- **Extra turn on 6**: Rolling a 6 grants another roll
- **Extra turn on capture**: Capturing an opponent grants another roll
- **Win condition**: First player to get all 4 tokens to the center wins

## Architecture

- **State management**: Provider (`ChangeNotifier`)
- **Navigation**: `Navigator` with `PageRouteBuilder` (fade + slide transitions)
- **Performance**: `RepaintBoundary` on board and dice, `AnimatedPositioned` for tokens, single `notifyListeners()` per turn phase
