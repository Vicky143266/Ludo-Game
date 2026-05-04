import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import 'game_selection_screen.dart';
import 'user_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Background fade ────────────────────────────────────────────────────────
  late AnimationController _bgController;
  late Animation<double> _bgFade;

  // ── Logo board scale ───────────────────────────────────────────────────────
  late AnimationController _boardController;
  late Animation<double> _boardScale;
  late Animation<double> _boardFade;

  // ── Dice drop + bounce ─────────────────────────────────────────────────────
  late AnimationController _diceDropController;
  late Animation<double> _diceY;       // vertical drop
  late Animation<double> _diceRotate; // 3-D spin feel (2-D skew)
  late Animation<double> _diceScale;

  // ── Dice glow after landing ────────────────────────────────────────────────
  late AnimationController _glowController;
  late Animation<double> _glowOpacity;

  // ── Text slide-up ──────────────────────────────────────────────────────────
  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // ── Play button ───────────────────────────────────────────────────────────
  late AnimationController _btnController;
  late Animation<double> _btnFade;
  late Animation<double> _btnScale;

  // ── Button press scale ────────────────────────────────────────────────────
  double _btnPressScale = 1.0;

  // ── Dice face shown after landing ─────────────────────────────────────────
  int _diceFace = 6;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Background fade-in  (0 → 600 ms)
    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeIn);

    // 2. Board scale 0.8 → 1.0  (400 → 1000 ms)
    _boardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _boardScale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _boardController, curve: Curves.easeOutBack));
    _boardFade = CurvedAnimation(parent: _boardController, curve: Curves.easeOut);

    // 3. Dice drop + bounce  (900 → 1700 ms)
    _diceDropController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _diceY = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: -1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -0.12)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: -0.12, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
    ]).animate(_diceDropController);

    _diceRotate = Tween<double>(begin: -2 * pi, end: 0.0).animate(
        CurvedAnimation(parent: _diceDropController, curve: Curves.easeOut));

    _diceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.05), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(
        CurvedAnimation(parent: _diceDropController, curve: Curves.easeOut));

    // 4. Glow pulse  (1700 → 2200 ms)
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

    // 5. Text fade + slide  (1800 → 2400 ms)
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));

    // 6. Play button  (2400 → 2900 ms)
    _btnController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _btnFade = CurvedAnimation(parent: _btnController, curve: Curves.easeOut);
    _btnScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _btnController, curve: Curves.easeOutBack));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Step 1 – bg
    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Step 2 – board
    _boardController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3 – dice drop
    _diceFace = Random().nextInt(6) + 1;
    _diceDropController.forward();
    await Future.delayed(const Duration(milliseconds: 900));

    // Step 4 – glow
    _glowController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Step 5 – text
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Step 6 – button
    if (mounted) _btnController.forward();
  }

  Future<void> _navigate() async {
    if (_navigating) return;
    _navigating = true;
    if (!mounted) return;
    final storage = context.read<StorageService>();
    final userName = await storage.getUserName();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_buildRoute(
      userName != null && userName.isNotEmpty
          ? GameSelectionScreen(userName: userName)
          : const UserSetupScreen(),
    ));
  }

  PageRoute _buildRoute(Widget screen) => PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.05), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 450),
      );

  @override
  void dispose() {
    _bgController.dispose();
    _boardController.dispose();
    _diceDropController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Cap logo size: on web/desktop it would be huge, so clamp it
    final logoSize = (size.width * 0.72).clamp(200.0, 340.0);

    return Scaffold(
      body: FadeTransition(
        opacity: _bgFade,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF2A1060),
                Color(0xFF0D0828),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Soft colored blobs in background
              _ColorBlob(color: const Color(0xFF1565C0), dx: -0.6, dy: -0.5),
              _ColorBlob(color: const Color(0xFFF9A825), dx: 0.6, dy: -0.5),
              _ColorBlob(color: const Color(0xFFC62828), dx: -0.6, dy: 0.5),
              _ColorBlob(color: const Color(0xFF2E7D32), dx: 0.6, dy: 0.5),

              // Main content
              Center(
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Board logo + dice overlay ──────────────────────────
                    SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Board logo
                          ScaleTransition(
                            scale: _boardScale,
                            child: FadeTransition(
                              opacity: _boardFade,
                              child: Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(logoSize * 0.12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 40,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(logoSize * 0.12),
                                  child: _FallbackBoard(size: logoSize),
                                ),
                              ),
                            ),
                          ),

                          // Dice drop overlay
                          AnimatedBuilder(
                            animation: _diceDropController,
                            builder: (context, _) {
                              final diceSize = logoSize * 0.38;
                              final dropOffset =
                                  _diceY.value * size.height * 0.5;
                              return Transform.translate(
                                offset: Offset(0, dropOffset),
                                child: Transform.rotate(
                                  angle: _diceRotate.value,
                                  child: Transform.scale(
                                    scale: _diceScale.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Glow ring
                                        AnimatedBuilder(
                                          animation: _glowController,
                                          builder: (_, __) => Opacity(
                                            opacity: _glowOpacity.value,
                                            child: Container(
                                              width: diceSize * 1.5,
                                              height: diceSize * 1.5,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withOpacity(0.25),
                                                    blurRadius: 40,
                                                    spreadRadius: 10,
                                                  ),
                                                ],
                              ),
                                            ),
                                          ),
                                        ),
                                        // Dice face
                                        _Dice3D(
                                            size: diceSize,
                                            face: _diceFace),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Game title ─────────────────────────────────────────
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                colors: [
                                  Color(0xFFFFD740),
                                  Color(0xFFFFFFFF),
                                  Color(0xFFFFD740),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'LUDO',
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Classic Board Game',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.65),
                                letterSpacing: 3,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Play button ────────────────────────────────────────
                    ScaleTransition(
                      scale: _btnScale,
                      child: FadeTransition(
                        opacity: _btnFade,
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _btnPressScale = 0.93),
                          onTapUp: (_) {
                            setState(() => _btnPressScale = 1.0);
                            _navigate();
                          },
                          onTapCancel: () =>
                              setState(() => _btnPressScale = 1.0),
                          child: AnimatedScale(
                            scale: _btnPressScale,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 56, vertical: 18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD740),
                                    Color(0xFFFF8F00),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD740)
                                        .withOpacity(0.45),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'PLAY',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1040),
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ), // SingleChildScrollView
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Soft colored background blob ─────────────────────────────────────────────
class _ColorBlob extends StatelessWidget {
  final Color color;
  final double dx;
  final double dy;

  const _ColorBlob(
      {required this.color, required this.dx, required this.dy});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: size.width * 0.5 + dx * size.width * 0.5 - 100,
      top: size.height * 0.5 + dy * size.height * 0.5 - 100,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.35), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ── Fallback board when image is missing ─────────────────────────────────────
class _FallbackBoard extends StatelessWidget {
  final double size;
  const _FallbackBoard({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.12),
        color: Colors.white,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(size * 0.06),
        mainAxisSpacing: size * 0.04,
        crossAxisSpacing: size * 0.04,
        children: const [
          _QuadrantTile(color: Color(0xFF1565C0)),
          _QuadrantTile(color: Color(0xFFF9A825)),
          _QuadrantTile(color: Color(0xFFC62828)),
          _QuadrantTile(color: Color(0xFF2E7D32)),
        ],
      ),
    );
  }
}

class _QuadrantTile extends StatelessWidget {
  final Color color;
  const _QuadrantTile({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(6),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: List.generate(
          4,
          (_) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 3-D styled dice widget ────────────────────────────────────────────────────
class _Dice3D extends StatelessWidget {
  final double size;
  final int face;

  const _Dice3D({required this.size, required this.face});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFD0D0D0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(4, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glossy highlight
          Positioned(
            top: size * 0.06,
            left: size * 0.08,
            child: Container(
              width: size * 0.45,
              height: size * 0.22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.1),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.7),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Dots
          Center(child: _DiceDots(face: face, size: size)),
        ],
      ),
    );
  }
}

class _DiceDots extends StatelessWidget {
  final int face;
  final double size;

  const _DiceDots({required this.face, required this.size});

  @override
  Widget build(BuildContext context) {
    final d = size * 0.14; // dot diameter
    final g = size * 0.18; // gap

    Widget dot() => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        );

    Widget row(List<bool> show) => Row(
          mainAxisSize: MainAxisSize.min,
          children: show
              .map((v) => Padding(
                    padding: EdgeInsets.all(g * 0.3),
                    child: v ? dot() : SizedBox(width: d, height: d),
                  ))
              .toList(),
        );

    switch (face) {
      case 1:
        return dot();
      case 2:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          row([true, false]),
          SizedBox(height: g),
          row([false, true]),
        ]);
      case 3:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          row([true, false]),
          SizedBox(height: g * 0.5),
          row([false, true]),
          SizedBox(height: g * 0.5),
          row([true, false]),
        ]);
      case 4:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          row([true, true]),
          SizedBox(height: g),
          row([true, true]),
        ]);
      case 5:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          row([true, true]),
          SizedBox(height: g * 0.5),
          Padding(padding: EdgeInsets.only(left: d * 0.5), child: dot()),
          SizedBox(height: g * 0.5),
          row([true, true]),
        ]);
      case 6:
      default:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          row([true, true]),
          SizedBox(height: g * 0.5),
          row([true, true]),
          SizedBox(height: g * 0.5),
          row([true, true]),
        ]);
    }
  }
}
