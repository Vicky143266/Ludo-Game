import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/board_path.dart';
import '../models/game_enums.dart';
import '../models/player.dart';
import '../models/token.dart';
import '../state/game_state.dart';
import 'token_widget.dart';

// ── Exact colors matching the reference image ─────────────────────────────────
const _kBlue   = Color(0xFF2196F3);
const _kYellow = Color(0xFFFFC107);
const _kRed    = Color(0xFFF44336);
const _kGreen  = Color(0xFF4CAF50);
const _kWhite  = Color(0xFFFFFFFF);
const _kGrid   = Color(0xFFBDBDBD);
const _kBg     = Color(0xFFFFFFFF);

class LudoBoardWidget extends StatelessWidget {
  const LudoBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = size / 15;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: BoardPainter(cellSize: cellSize),
              ),
              _TokensOverlay(cellSize: cellSize, boardSize: size),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Board Painter — pixel-faithful to the reference image
// ─────────────────────────────────────────────────────────────────────────────
class BoardPainter extends CustomPainter {
  final double cellSize;
  const BoardPainter({required this.cellSize});

  double get s => cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _kBg,
    );

    // 2. Four colored quadrants (6×6 each)
    _fillRect(canvas, 0, 0, 6, 6, _kBlue);    // top-left  = Blue
    _fillRect(canvas, 0, 9, 6, 6, _kYellow);  // top-right = Yellow
    _fillRect(canvas, 9, 0, 6, 6, _kRed);     // bot-left  = Red
    _fillRect(canvas, 9, 9, 6, 6, _kGreen);   // bot-right = Green

    // 3. White rounded inner yard (4×4) inside each quadrant
    _drawYard(canvas, 0, 0, _kBlue);
    _drawYard(canvas, 0, 9, _kYellow);
    _drawYard(canvas, 9, 0, _kRed);
    _drawYard(canvas, 9, 9, _kGreen);

    // 4. Main path cells (white)
    _drawMainPath(canvas);

    // 5. Colored home-stretch paths
    _drawHomePaths(canvas);

    // 6. Safe-cell stars
    _drawSafeCells(canvas);

    // 7. Center finish area (colored triangles)
    _drawCenter(canvas);

    // 8. Grid lines over everything
    _drawGrid(canvas, size);

    // 9. Directional arrows on entry cells
    _drawArrows(canvas);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _fillRect(Canvas canvas, int row, int col, int rows, int cols, Color c) {
    canvas.drawRect(
      Rect.fromLTWH(col * s, row * s, cols * s, rows * s),
      Paint()..color = c,
    );
  }

  /// White rounded inner yard with 4 token-slot circles
  void _drawYard(Canvas canvas, int originRow, int originCol, Color tokenColor) {
    final left   = (originCol + 1) * s;
    final top    = (originRow + 1) * s;
    final size4  = 4 * s;
    final radius = s * 0.35;

    // White rounded rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, size4, size4),
        Radius.circular(radius),
      ),
      Paint()..color = _kWhite,
    );

    // 4 token slots: white circle with colored fill
    final slotPositions = [
      [originRow + 1, originCol + 1],
      [originRow + 1, originCol + 4],
      [originRow + 4, originCol + 1],
      [originRow + 4, originCol + 4],
    ];

    for (final pos in slotPositions) {
      final cx = (pos[1] + 0.5) * s;
      final cy = (pos[0] + 0.5) * s;
      final r  = s * 0.62;

      // White outer ring
      canvas.drawCircle(Offset(cx, cy), r + s * 0.06,
          Paint()..color = _kWhite);
      // Colored fill
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()..color = tokenColor);
      // Subtle inner shadow ring
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = Colors.black.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.06,
      );
      // Glossy highlight
      canvas.drawCircle(
        Offset(cx - r * 0.25, cy - r * 0.28),
        r * 0.32,
        Paint()..color = Colors.white.withOpacity(0.35),
      );
    }
  }

  void _drawMainPath(Canvas canvas) {
    final fill   = Paint()..color = _kWhite;
    for (final cell in BoardPath.mainPath) {
      canvas.drawRect(
        Rect.fromLTWH(cell[1] * s, cell[0] * s, s, s),
        fill,
      );
    }
  }

  void _drawHomePaths(Canvas canvas) {
    final colorMap = {
      PlayerColor.red:    _kRed,
      PlayerColor.green:  _kGreen,
      PlayerColor.yellow: _kYellow,
      PlayerColor.blue:   _kBlue,
    };
    for (final entry in BoardPath.homePaths.entries) {
      final c = colorMap[entry.key]!;
      for (final cell in entry.value) {
        canvas.drawRect(
          Rect.fromLTWH(cell[1] * s, cell[0] * s, s, s),
          Paint()..color = c,
        );
      }
    }
  }

  void _drawSafeCells(Canvas canvas) {
    // Safe cells get a light-grey tint + star
    for (final idx in BoardPath.safeIndices) {
      final cell = BoardPath.mainPath[idx];
      final cx = (cell[1] + 0.5) * s;
      final cy = (cell[0] + 0.5) * s;

      // Light background
      canvas.drawRect(
        Rect.fromLTWH(cell[1] * s, cell[0] * s, s, s),
        Paint()..color = const Color(0xFFEEEEEE),
      );
      _drawStar(canvas, Offset(cx, cy), s * 0.28,
          const Color(0xFF9E9E9E));
    }
  }

  void _drawCenter(Canvas canvas) {
    final cx = 7 * s;
    final cy = 7 * s;

    // White background for center cell
    canvas.drawRect(Rect.fromLTWH(cx, cy, s, s),
        Paint()..color = _kWhite);

    // 4 colored triangles pointing inward
    _tri(canvas, cx, cy, s, _kRed,    'top');
    _tri(canvas, cx, cy, s, _kBlue,   'left');
    _tri(canvas, cx, cy, s, _kYellow, 'right');
    _tri(canvas, cx, cy, s, _kGreen,  'bottom');

    // White star in center
    _drawStar(canvas, Offset(cx + s / 2, cy + s / 2), s * 0.32, _kWhite);
  }

  void _tri(Canvas canvas, double cx, double cy, double sz,
      Color color, String dir) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final m = sz / 2;
    switch (dir) {
      case 'top':
        path.moveTo(cx, cy);
        path.lineTo(cx + sz, cy);
        path.lineTo(cx + m, cy + m);
        break;
      case 'bottom':
        path.moveTo(cx, cy + sz);
        path.lineTo(cx + sz, cy + sz);
        path.lineTo(cx + m, cy + m);
        break;
      case 'left':
        path.moveTo(cx, cy);
        path.lineTo(cx, cy + sz);
        path.lineTo(cx + m, cy + m);
        break;
      case 'right':
        path.moveTo(cx + sz, cy);
        path.lineTo(cx + sz, cy + sz);
        path.lineTo(cx + m, cy + m);
        break;
    }
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kGrid
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * s, 0), Offset(i * s, size.height), paint);
      canvas.drawLine(Offset(0, i * s), Offset(size.width, i * s), paint);
    }

    // Thicker border
    final border = Paint()
      ..color = _kGrid
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), border);
  }

  /// Arrows on the entry cells (matching the reference image)
  void _drawArrows(Canvas canvas) {
    // Blue entry: row=6, col=1 → arrow pointing right (→)
    _drawArrow(canvas, 6, 1, _ArrowDir.right, _kBlue);
    // Green entry: row=1, col=8 → arrow pointing down (↓)
    _drawArrow(canvas, 1, 8, _ArrowDir.down, _kYellow);
    // Yellow entry: row=8, col=13 → arrow pointing left (←)
    _drawArrow(canvas, 8, 13, _ArrowDir.left, _kYellow);
    // Red entry: row=13, col=6 → arrow pointing up (↑)
    _drawArrow(canvas, 13, 6, _ArrowDir.up, _kRed);
  }

  void _drawArrow(Canvas canvas, int row, int col,
      _ArrowDir dir, Color color) {
    final cx = (col + 0.5) * s;
    final cy = (row + 0.5) * s;
    final paint = Paint()
      ..color = color
      ..strokeWidth = s * 0.18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final hw = s * 0.28; // half-width of arrow head
    final hl = s * 0.22; // head length

    double angle;
    switch (dir) {
      case _ArrowDir.right:  angle = 0; break;
      case _ArrowDir.down:   angle = math.pi / 2; break;
      case _ArrowDir.left:   angle = math.pi; break;
      case _ArrowDir.up:     angle = -math.pi / 2; break;
    }

    // Shaft
    final shaftLen = s * 0.3;
    final sx = cx - math.cos(angle) * shaftLen;
    final sy = cy - math.sin(angle) * shaftLen;
    canvas.drawLine(Offset(sx, sy), Offset(cx, cy), paint);

    // Arrowhead (chevron)
    final path = Path();
    final tipX = cx + math.cos(angle) * hl;
    final tipY = cy + math.sin(angle) * hl;
    final perpX = -math.sin(angle) * hw;
    final perpY =  math.cos(angle) * hw;
    path.moveTo(cx + perpX, cy + perpY);
    path.lineTo(tipX, tipY);
    path.lineTo(cx - perpX, cy - perpY);
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    const pts = 5;
    final inner = radius * 0.42;
    for (int i = 0; i < pts * 2; i++) {
      final r = i.isEven ? radius : inner;
      final angle = (i * math.pi / pts) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => old.cellSize != cellSize;
}

enum _ArrowDir { right, down, left, up }

// ─────────────────────────────────────────────────────────────────────────────
//  Tokens Overlay
// ─────────────────────────────────────────────────────────────────────────────
class _TokensOverlay extends StatelessWidget {
  final double cellSize;
  final double boardSize;

  const _TokensOverlay({required this.cellSize, required this.boardSize});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        if (gameState.players.isEmpty) return const SizedBox();

        final List<Widget> tokenWidgets = [];

        for (final player in gameState.players) {
          for (final token in player.tokens) {
            final isHighlighted = gameState.highlightedTokens
                .any((t) => t.id == token.id && t.color == token.color);

            final position = _getTokenPosition(token, player, gameState);
            if (position == null) continue;

            tokenWidgets.add(
              AnimatedPositioned(
                key: ValueKey('${token.color.name}_${token.id}'),
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeInOut,
                left: position.dx,
                top: position.dy,
                child: TokenWidget(
                  token: token,
                  cellSize: cellSize,
                  isHighlighted: isHighlighted,
                  onTap: isHighlighted
                      ? () => gameState.selectToken(token)
                      : null,
                ),
              ),
            );
          }
        }

        return Stack(children: tokenWidgets);
      },
    );
  }

  Offset? _getTokenPosition(Token token, Player player, GameState gameState) {
    List<int>? cell;

    if (token.isHome && !token.isFinished) {
      cell = BoardPath.getHomeBaseCell(token.color, token.id);
    } else if (token.isFinished) {
      final offsets = [
        const Offset(-0.2, -0.2),
        const Offset(0.2, -0.2),
        const Offset(-0.2, 0.2),
        const Offset(0.2, 0.2),
      ];
      final center = BoardPath.centerCell;
      final off = offsets[token.id % 4];
      return Offset(
        (center[1] + off.dx) * cellSize + cellSize * 0.125,
        (center[0] + off.dy) * cellSize + cellSize * 0.125,
      );
    } else {
      cell = BoardPath.getGridCell(token.position, token.color);
    }

    if (cell == null) return null;

    final stackOffset = _getStackOffset(token, player, gameState, cell);
    return Offset(
      cell[1] * cellSize + cellSize * 0.125 + stackOffset.dx,
      cell[0] * cellSize + cellSize * 0.125 + stackOffset.dy,
    );
  }

  Offset _getStackOffset(
      Token token, Player player, GameState gameState, List<int> cell) {
    final List<Token> stacked = [];
    for (final p in gameState.players) {
      for (final t in p.tokens) {
        if (t.isHome || t.isFinished) continue;
        final tCell = BoardPath.getGridCell(t.position, t.color);
        if (tCell != null && tCell[0] == cell[0] && tCell[1] == cell[1]) {
          stacked.add(t);
        }
      }
    }

    if (stacked.length <= 1) return Offset.zero;

    final idx = stacked
        .indexWhere((t) => t.id == token.id && t.color == token.color);
    if (idx < 0) return Offset.zero;

    const stackOffsets = [
      Offset(-3, -3),
      Offset(3, -3),
      Offset(-3, 3),
      Offset(3, 3),
    ];
    return stackOffsets[idx % stackOffsets.length];
  }
}
