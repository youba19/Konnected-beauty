import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class WelcomeEvent {}

class StartLogoAnimation extends WelcomeEvent {}

class CompleteLogoAnimation extends WelcomeEvent {}

class SkipLogoAnimation extends WelcomeEvent {}

class ShowContent extends WelcomeEvent {}

// States
abstract class WelcomeState {
  final bool isAnimating;
  final bool showContent;
  final bool skipAnimation;

  const WelcomeState({
    required this.isAnimating,
    required this.showContent,
    required this.skipAnimation,
  });
}

class WelcomeInitial extends WelcomeState {
  const WelcomeInitial()
      : super(
          isAnimating: false,
          showContent: false,
          skipAnimation: false,
        );
}

class WelcomeAnimating extends WelcomeState {
  const WelcomeAnimating()
      : super(
          isAnimating: true,
          showContent: false,
          skipAnimation: false,
        );
}

class WelcomeContentShown extends WelcomeState {
  const WelcomeContentShown()
      : super(
          isAnimating: false,
          showContent: true,
          skipAnimation: false,
        );
}

class WelcomeSkippedAnimation extends WelcomeState {
  const WelcomeSkippedAnimation()
      : super(
          isAnimating: false,
          showContent: true,
          skipAnimation: true,
        );
}

// Bloc
class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc() : super(const WelcomeInitial()) {
    on<StartLogoAnimation>(_onStartLogoAnimation);
    on<CompleteLogoAnimation>(_onCompleteLogoAnimation);
    on<SkipLogoAnimation>(_onSkipLogoAnimation);
    on<ShowContent>(_onShowContent);
  }

  void _onStartLogoAnimation(
      StartLogoAnimation event, Emitter<WelcomeState> emit) {
    emit(const WelcomeAnimating());
  }

  void _onCompleteLogoAnimation(
      CompleteLogoAnimation event, Emitter<WelcomeState> emit) {
    emit(const WelcomeContentShown());
  }

  void _onSkipLogoAnimation(
      SkipLogoAnimation event, Emitter<WelcomeState> emit) {
    emit(const WelcomeSkippedAnimation());
  }

  void _onShowContent(ShowContent event, Emitter<WelcomeState> emit) {
    emit(const WelcomeContentShown());
  }
}
