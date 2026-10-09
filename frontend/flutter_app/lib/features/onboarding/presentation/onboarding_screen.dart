import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';

class OnboardingSlide {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  const OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const _slides = [
  OnboardingSlide(
    eyebrow: 'Welcome to SkinCore',
    title: 'Smarter care.\nGlowing skin.',
    description:
        'AI-guided skin assessment, a routine built around you, and a dermatology-aware companion — every day.',
    icon: Icons.favorite_rounded,
  ),
  OnboardingSlide(
    eyebrow: 'Understand your skin',
    title: 'Scan. Learn.\nTrack progress.',
    description: 'Snap a photo for an instant preliminary read, then watch your skin score improve over time.',
    icon: Icons.camera_alt_rounded,
  ),
  OnboardingSlide(
    eyebrow: 'Always-on support',
    title: 'Ask anything,\nanytime.',
    description: 'A dermatology-aware AI chatbot answers questions and bursts skincare myths, daily.',
    icon: Icons.chat_bubble_rounded,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) context.go('/login');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(onPressed: _finish, child: Text(AppLocalizations.of(context).translate('common_skip'))),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 7,
                  width: i == _index ? 22 : 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: i == _index ? AppColors.brandGradient : null,
                    color: i == _index ? null : AppColors.mutedLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GradientButton(
                label: _index == _slides.length - 1 ? 'Get started' : 'Continue',
                onPressed: () {
                  if (_index == _slides.length - 1) {
                    _finish();
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final OnboardingSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
            child: Icon(slide.icon, color: Colors.white, size: 56),
          ),
          const SizedBox(height: 36),
          Text(
            slide.eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.rose,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 10),
          Text(slide.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}
