import 'game_enums.dart';
import 'token.dart';

class Player {
  final String name;
  final PlayerColor color;
  final bool isAI;
  final List<Token> tokens;

  /// Index into boardPath where this player's tokens enter the main path
  final int startIndex;

  int finishedCount;

  Player({
    required this.name,
    required this.color,
    required this.startIndex,
    this.isAI = false,
    int? finishedCount,
  })  : tokens = List.generate(
          4,
          (i) => Token(id: i, color: color),
        ),
        finishedCount = finishedCount ?? 0;

  void reset() {
    finishedCount = 0;
    for (final t in tokens) {
      t.reset();
    }
  }

  bool get hasWon => finishedCount == 4;

  @override
  String toString() => 'Player($name, ${color.name}, AI:$isAI)';
}
