import 'game_enums.dart';

class Token {
  final int id;
  final PlayerColor color;

  /// -1 = at home base (not yet entered)
  /// 0–55 = on main board path (relative to player's start)
  /// 56–61 = on colored home path (6 cells)
  /// 62 = finished (locked in center)
  int position;
  bool isFinished;
  bool isHome;

  Token({
    required this.id,
    required this.color,
    this.position = -1,
    this.isFinished = false,
    this.isHome = true,
  });

  Token copyWith({
    int? position,
    bool? isFinished,
    bool? isHome,
  }) {
    return Token(
      id: id,
      color: color,
      position: position ?? this.position,
      isFinished: isFinished ?? this.isFinished,
      isHome: isHome ?? this.isHome,
    );
  }

  void reset() {
    position = -1;
    isFinished = false;
    isHome = true;
  }

  @override
  String toString() =>
      'Token(id:$id, color:${color.name}, pos:$position, home:$isHome, finished:$isFinished)';
}
