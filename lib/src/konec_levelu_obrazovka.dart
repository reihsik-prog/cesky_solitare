import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late AnimationController _scoreController;
  late AnimationController _coinAnimController;
  late AnimationController _dialogAnimController;
  late Animation<double> _scaleAnimation;

  int _displayedScore = 0;
  int _displayedCoins = 0;
  bool _animationFinished = false;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _coinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _dialogAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _dialogAnimController,
      curve: Curves.elasticOut,
    );

    _dialogAnimController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAnimations();
      }
    });
  }

  void _startAnimations() {
    final scoreTween = IntTween(begin: 0, end: widget.score);
    final scoreAnimation = scoreTween.animate(
      CurvedAnimation(
        parent: _scoreController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    scoreAnimation.addListener(() {
      if(mounted) {
        setState(() {
          _displayedScore = scoreAnimation.value;
        });
      }
    });

    _scoreController.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        _animationFinished = true;
        _displayedCoins = widget.coins;
      });
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _coinAnimController.dispose();
    _dialogAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.oswald(
      fontSize: 24,
      color: const Color(0xFF4A3933),
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            margin: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC8B6A6), width: 5),
              image: const DecorationImage(
                image: AssetImage('assets/images/stary_papir.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level Dokončen!',
                  style: GoogleFonts.oswald(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A3933),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Lottie.asset(
                    'assets/animations/piggy_bank.json',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Skóre: $_displayedScore', style: textStyle),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      'Získané mince:',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        color: const Color(0xFF4A3933).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBC02D), Color(0xFFFFD700)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Lottie.asset(
                              'assets/animations/coin.json',
                              controller: _coinAnimController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_displayedCoins',
                            style: GoogleFonts.oswald(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4A3933),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_animationFinished)
                  FadeIn(
                    child: Column(
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
