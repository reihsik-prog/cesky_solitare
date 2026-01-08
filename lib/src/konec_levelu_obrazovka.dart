import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'pomocne_widgety.dart';

class KonecLeveluObrazovka extends StatefulWidget {
  final int score;
  final int coins;
  final VoidCallback onNextLevel;
  final VoidCallback onMenu;

  const KonecLeveluObrazovka({
    super.key,
    required this.score,
    required this.coins,
    required this.onNextLevel,
    required this.onMenu,
  });

  @override
  State<KonecLeveluObrazovka> createState() => _KonecLeveluObrazovkaState();
}

class _KonecLeveluObrazovkaState extends State<KonecLeveluObrazovka>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<_CoinParticle> _particles = [];
  int _displayedScore = 0;
  int _displayedCoins = 0;
  bool _animationFinished = false;

  final GlobalKey _piggyBankKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAnimations();
      }
    });
  }

  void _startAnimations() {
    // Score counting animation
    final scoreTween = IntTween(begin: 0, end: widget.score);
    final scoreAnimation = scoreTween.animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    scoreAnimation.addListener(() {
      setState(() {
        _displayedScore = scoreAnimation.value;
      });
    });

    // Animate particles
    final particleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));
    particleAnimation.addListener(() {
      for (var particle in _particles) {
        particle.update(particleAnimation.value);
      }
    });

    // Start animation right away
    _controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        _animationFinished = true;
        _displayedCoins = widget.coins;
      });
    });

    // Schedule particle creation after a delay.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      // create particles and trigger a rebuild to paint them
      setState(() {
        _createParticles();
      });
    });
  }

  void _createParticles() {
    final RenderBox? piggyBox =
        _piggyBankKey.currentContext?.findRenderObject() as RenderBox?;
    if (piggyBox == null) return;

    final piggyPosition = piggyBox.localToGlobal(Offset.zero) +
        Offset(piggyBox.size.width / 2, piggyBox.size.height / 2);

    final random = Random();
    _particles = List.generate(widget.coins > 20 ? 20 : widget.coins, (index) {
      final startPosition = Offset(
        MediaQuery.of(context).size.width / 2 + (random.nextDouble() - 0.5) * 100,
        MediaQuery.of(context).size.height * 0.4,
      );
      return _CoinParticle(
        startPosition: startPosition,
        endPosition: piggyPosition,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Stack(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E8C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC8B6A6), width: 5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Level Dokončen!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A3933),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Skóre: $_displayedScore',
                    style: const TextStyle(fontSize: 24, color: Color(0xFF4A3933)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Získané mince: $_displayedCoins',
                        style: const TextStyle(
                            fontSize: 24, color: Color(0xFF4A3933)),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        key: _piggyBankKey,
                        width: 180,
                        height: 180,
                        child: Lottie.asset(
                          'assets/animations/piggy_bank.json',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_animationFinished)
                    Column(
                      children: [
                        MenuTlacitko(
                          text: 'DALŠÍ LEVEL',
                          ikona: Icons.play_arrow_rounded,
                          onTap: widget.onNextLevel,
                        ),
                        const SizedBox(height: 20),
                        MenuTlacitko(
                          text: 'HLAVNÍ MENU',
                          ikona: Icons.menu,
                          onTap: widget.onMenu,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (!_animationFinished)
            SizedBox.expand(
              child: CustomPaint(
                painter: _CoinPainter(particles: _particles),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  final List<_CoinParticle> particles;

  _CoinPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.amber;
    for (var particle in particles) {
      if (particle.progress > 0 && particle.progress < 1) {
        canvas.drawCircle(particle.currentPosition, 8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CoinParticle {
  Offset startPosition;
  Offset endPosition;
  double progress = 0;
  Offset currentPosition;

  _CoinParticle({required this.startPosition, required this.endPosition})
      : currentPosition = startPosition;

  void update(double animationValue) {
    progress = animationValue;
    // Simple linear interpolation
    // For a more dynamic path, you could use a curved path
    currentPosition = Offset.lerp(startPosition, endPosition, progress)!;
  }
}
