import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/bloc/welcome/welcome_bloc.dart';

class AnimatedLogo extends StatefulWidget {
  final VoidCallback? onFirstStageComplete;
  final VoidCallback? onAnimationComplete;

  const AnimatedLogo({
    super.key,
    this.onFirstStageComplete,
    this.onAnimationComplete,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _sizeController;
  late AnimationController _positionController;
  late Animation<double> _sizeAnimation;
  late Animation<Alignment> _positionAnimation;

  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _sizeController = AnimationController(
      duration: const Duration(milliseconds: 800), // Faster pulse effect
      vsync: this,
    );

    _positionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Check if we should skip animation
    final welcomeState = context.read<WelcomeBloc>().state;
    if (welcomeState.skipAnimation) {
      // Skip animation - set controllers to final state
      _sizeController.value = 1.0;
      _positionController.value = 1.0;

      // Set animations to final state
      _sizeAnimation = Tween<double>(
        begin: 60.0,
        end: 60.0,
      ).animate(CurvedAnimation(
        parent: _sizeController,
        curve: Curves.easeInOut,
      ));

      _positionAnimation = Tween<Alignment>(
        begin: Alignment.topLeft,
        end: Alignment.topLeft,
      ).animate(CurvedAnimation(
        parent: _positionController,
        curve: Curves.easeInOut,
      ));

      setState(() {
        _isAnimationComplete = true;
      });

      // Immediately show welcome screen content when skipping animation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          context.read<WelcomeBloc>().add(CompleteLogoAnimation());
        }
      });

      return;
    }

    // Animation sequence setup
    _startAnimation();
  }

  void _startAnimation() async {
    if (!mounted) return;

    try {
      // Step 1: Start small in middle, grow bigger with enhanced pulse effect
      _sizeAnimation = Tween<double>(
        begin: 80.0, // Start small
        end: 200.0, // Grow bigger
      ).animate(CurvedAnimation(
        parent: _sizeController,
        curve: Curves.elasticOut, // Elastic/pulse effect when growing
      ));

      _positionAnimation = Tween<Alignment>(
        begin: Alignment.center, // Stay in middle
        end: Alignment.center,
      ).animate(CurvedAnimation(
        parent: _sizeController,
        curve: Curves.easeInOut,
      ));

      // Create enhanced pulse effect with multiple oscillations
      _createPulseEffect();

      // Grow the logo with enhanced pulse effect (NO TEXT APPEARS YET)
      await _sizeController.forward();

      if (!mounted) return;

      // Step 2: Move to top-left corner and shrink
      _positionAnimation = Tween<Alignment>(
        begin: Alignment.center,
        end: Alignment.topLeft,
      ).animate(CurvedAnimation(
        parent: _positionController,
        curve: Curves.easeInOutCubic,
      ));

      // Create new size animation for shrinking
      _sizeAnimation = Tween<double>(
        begin: 200.0, // Current size (big)
        end: 82.0, // Final size (small)
      ).animate(CurvedAnimation(
        parent: _positionController,
        curve: Curves.easeInOutCubic,
      ));

      // NOW start fading in welcome screen content when logo starts moving
      _startWelcomeScreenFadeIn();

      // Move to top-left and shrink simultaneously
      await _positionController.forward();

      if (mounted) {
        setState(() {
          _isAnimationComplete = true;
        });

        widget.onAnimationComplete?.call();
      }
    } catch (e) {
      // Handle any animation errors silently
      if (mounted) {
        setState(() {
          _isAnimationComplete = true;
        });
      }
    }
  }

  void _createPulseEffect() {
    // Create a sequence of pulses for more dramatic effect
    _sizeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 80.0, end: 220.0),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 220.0, end: 180.0),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 180.0, end: 210.0),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 210.0, end: 200.0),
        weight: 30.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _sizeController,
      curve: Curves.easeInOut,
    ));
  }

  void _startWelcomeScreenFadeIn() {
    // Start fading in welcome screen content ONLY when logo starts moving to top-left
    // This ensures text appears only after logo has grown and is repositioning
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<WelcomeBloc>().add(CompleteLogoAnimation());
      }
    });
  }

  @override
  void dispose() {
    try {
      _sizeController.dispose();
      _positionController.dispose();
    } catch (e) {
      // Handle disposal errors silently
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([_sizeController, _positionController]),
      builder: (context, child) {
        try {
          return Stack(
            children: [
              // Animated logo
              Positioned.fill(
                child: Align(
                  alignment: _positionAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: _sizeAnimation.value,
                      height: _sizeAnimation.value,
                      child: _buildLogo(),
                    ),
                  ),
                ),
              ),
            ],
          );
        } catch (e) {
          // Return a fallback widget if animation fails
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildLogo() {
    return SvgPicture.asset(
      'assets/images/Konected beauty - Logo white.svg',
      colorFilter: const ColorFilter.mode(
        Colors.white,
        BlendMode.srcIn,
      ),
      fit: BoxFit.contain,
      allowDrawingOutsideViewBox: true,
    );
  }
}
