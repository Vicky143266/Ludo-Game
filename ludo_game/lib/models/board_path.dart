import 'game_enums.dart';

/// The 15×15 Ludo board path system.
///
/// Main board path: 52 cells (indices 0–51), shared by all players.
/// Each player has a different entry point (startIndex) on this path.
/// Home paths: 5 cells per color (positions 52–56 in token.position space).
/// Finished: position 57.
///
/// Grid coordinates are [row, col] with (0,0) at top-left.
class BoardPath {
  /// Main board path — 52 cells, clockwise starting from Red's entry cell.
  /// Red enters at index 0, Green at 13, Yellow at 26, Blue at 39.
  static const List<List<int>> mainPath = [
    // Red start area → going up left column
    [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], // 0–4
    // Turn up
    [5, 6], [4, 6], [3, 6], [2, 6], [1, 6], [0, 6], // 5–10
    // Top row right
    [0, 7], // 11
    [0, 8], [1, 8], [2, 8], [3, 8], [4, 8], [5, 8], // 12–17  ← Green enters at 13
    // Turn right
    [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14], // 18–23
    // Right column down
    [7, 14], // 24
    [8, 14], [8, 13], [8, 12], [8, 11], [8, 10], [8, 9], // 25–30  ← Yellow enters at 26
    // Turn down
    [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], [14, 8], // 31–36
    // Bottom row left
    [14, 7], // 37
    [14, 6], [13, 6], [12, 6], [11, 6], [10, 6], [9, 6], // 38–43  ← Blue enters at 39
    // Turn left
    [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0], // 44–49
    // Left column up
    [7, 0], // 50
    [6, 0], // 51
  ];

  /// Home paths per color — 5 cells leading toward center (positions 52–56).
  static const Map<PlayerColor, List<List<int>>> homePaths = {
    PlayerColor.red: [
      [7, 1], [7, 2], [7, 3], [7, 4], [7, 5],
    ],
    PlayerColor.green: [
      [1, 7], [2, 7], [3, 7], [4, 7], [5, 7],
    ],
    PlayerColor.yellow: [
      [7, 13], [7, 12], [7, 11], [7, 10], [7, 9],
    ],
    PlayerColor.blue: [
      [13, 7], [12, 7], [11, 7], [10, 7], [9, 7],
    ],
  };

  /// Center finish cell
  static const List<int> centerCell = [7, 7];

  /// Player start indices on mainPath
  static const Map<PlayerColor, int> startIndices = {
    PlayerColor.red: 0,
    PlayerColor.green: 13,
    PlayerColor.yellow: 26,
    PlayerColor.blue: 39,
  };

  /// Safe cell indices on mainPath (cannot be captured here)
  static const List<int> safeIndices = [0, 8, 13, 21, 26, 34, 39, 47];

  /// Home base areas (6×6 corner squares) — top-left cell of each 6×6 area
  static const Map<PlayerColor, List<int>> homeAreaOrigin = {
    PlayerColor.red: [9, 0],
    PlayerColor.green: [0, 0],
    PlayerColor.yellow: [0, 9],
    PlayerColor.blue: [9, 9],
  };

  /// Returns the grid [row, col] for a token given its position and color.
  /// position == -1 → returns null (token is in home base, handled separately)
  /// position 0–51 → main path
  /// position 52–56 → home path
  /// position 57 → center
  static List<int>? getGridCell(int position, PlayerColor color) {
    if (position == -1) return null;
    if (position == 57) return centerCell;
    if (position >= 52) {
      final hp = homePaths[color]!;
      final idx = position - 52;
      if (idx < hp.length) return hp[idx];
      return centerCell;
    }
    // Main path: position is relative to player's start
    final startIdx = startIndices[color]!;
    final globalIdx = (startIdx + position) % 52;
    return mainPath[globalIdx];
  }

  /// Returns the absolute mainPath index for a token on the main board.
  static int getGlobalIndex(int relativePosition, PlayerColor color) {
    final startIdx = startIndices[color]!;
    return (startIdx + relativePosition) % 52;
  }

  /// Checks if a given absolute mainPath index is a safe cell.
  static bool isSafeIndex(int globalIndex) {
    return safeIndices.contains(globalIndex);
  }

  /// Home base token positions within the 6×6 corner area.
  /// Returns [row, col] for token slot [0–3] in the home base.
  static List<int> getHomeBaseCell(PlayerColor color, int tokenId) {
    final origin = homeAreaOrigin[color]!;
    // Arrange 4 tokens in a 2×2 grid centered in the 6×6 area
    const offsets = [
      [1, 1], [1, 4], [4, 1], [4, 4],
    ];
    final offset = offsets[tokenId % 4];
    return [origin[0] + offset[0], origin[1] + offset[1]];
  }
}
