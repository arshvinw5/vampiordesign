import 'package:flutter/foundation.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/onboarding_usecases.dart';

class OnboardingSlide {
  const OnboardingSlide({required this.title, required this.body, required this.cells});
  final String title;
  final String body;

  /// 3×3 colour-block art, row-major ARGB values.
  final List<int> cells;
}

class OnboardingController extends ChangeNotifier {
  OnboardingController({required this._completeOnboarding});

  final CompleteOnboarding _completeOnboarding;

  static const slides = [
    OnboardingSlide(
      title: 'Design that sets your brand apart',
      body: 'Vampior Designs crafts brand identities, logos and visuals that make your business instantly recognisable.',
      cells: [0xFF023E8A, 0xFFCAF0F8, 0xFFCAF0F8, 0xFF0096C7, 0xFF023E8A, 0xFFCAF0F8, 0xFFADE8F4, 0xFF0096C7, 0xFF023E8A],
    ),
    OnboardingSlide(
      title: 'Websites and apps built to convert',
      body: 'From UI/UX to development, we design digital products that are clean, fast and easy to use.',
      cells: [0xFFCAF0F8, 0xFF48CAE4, 0xFF023E8A, 0xFFCAF0F8, 0xFF0096C7, 0xFF48CAE4, 0xFF023E8A, 0xFFADE8F4, 0xFFCAF0F8],
    ),
    OnboardingSlide(
      title: 'One team from idea to launch',
      body: 'Share your project, track progress and collaborate with our designers in one place.',
      cells: [0xFFADE8F4, 0xFF023E8A, 0xFFADE8F4, 0xFF023E8A, 0xFF48CAE4, 0xFF023E8A, 0xFFADE8F4, 0xFF023E8A, 0xFF0096C7],
    ),
  ];

  int _index = 0;
  int get index => _index;
  bool get isFirst => _index == 0;
  bool get isLast => _index == slides.length - 1;

  void setIndex(int i) {
    final next = i.clamp(0, slides.length - 1);
    if (next == _index) return;
    _index = next;
    notifyListeners();
  }

  /// Marks onboarding as seen so later launches open on Login.
  Future<void> complete() async {
    await _completeOnboarding(const NoParams());
  }
}
