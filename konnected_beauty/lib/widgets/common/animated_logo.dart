import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
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

    // Always initialize controllers (needed for build method)
    _sizeController = AnimationController(
      duration: AppConstants.logoInitialAnimationDuration,
      vsync: this,
    );

    _positionController = AnimationController(
      duration: AppConstants.logoShrinkAnimationDuration,
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
        begin: AppConstants.logoFinalSize,
        end: AppConstants.logoFinalSize,
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
      widget.onAnimationComplete?.call();
      return;
    }

    // Normal animation setup
    _sizeAnimation = Tween<double>(
      begin: AppConstants.logoInitialSize,
      end: AppConstants.logoExpandedSize,
    ).animate(CurvedAnimation(
      parent: _sizeController,
      curve: Curves.easeInOut,
    ));

    _positionAnimation = Tween<Alignment>(
      begin: Alignment.center,
      end: Alignment.topLeft,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    if (!mounted) return;

    try {
      // Step 1: Grow the logo
      await _sizeController.forward();

      if (!mounted) return;

      // Step 2: Shrink and move to top-left
      _sizeAnimation = Tween<double>(
        begin: AppConstants.logoExpandedSize,
        end: AppConstants.logoFinalSize,
      ).animate(CurvedAnimation(
        parent: _sizeController,
        curve: Curves.easeInOut,
      ));

      // Start position animation
      _positionController.forward();

      // Shrink the logo
      await _sizeController.forward();

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
          return Align(
            alignment: _positionAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(20),
              child: SizedBox(
                width: _sizeAnimation.value,
                height: _sizeAnimation.value,
                child: _buildLogo(),
              ),
            ),
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
