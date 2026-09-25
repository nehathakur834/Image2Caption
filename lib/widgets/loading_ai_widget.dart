import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Animated AI loading overlay shown while generating captions.
class LoadingAIWidget extends StatefulWidget {
  const LoadingAIWidget({super.key});

  @override
  State<LoadingAIWidget> createState() => _LoadingAIWidgetState();
}

class _LoadingAIWidgetState extends State<LoadingAIWidget>
    with TickerProviderStateMixin {
  static const _steps = [
    (Icons.image_search_rounded, 'Understanding your photo...'),
    (Icons.palette_rounded, 'Finding the right tone...'),
    (Icons.edit_note_rounded, 'Writing creative captions...'),
    (Icons.tag_rounded, 'Generating hashtags...'),
  ];

  late final AnimationController _pulseController;
  late final AnimationController _stepController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _currentStep = (_currentStep + 1) % _steps.length;
            });
            _stepController.forward(from: 0);
          }
        }
      });
    _stepController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xxxl),
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppRadius.cardRadius,
            boxShadow: AppShadows.card(isDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing gradient orb
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 0.9 + _pulseController.value * 0.15;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.brand,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandPurple.withValues(
                              alpha: 0.35 + _pulseController.value * 0.25,
                            ),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(step.$1, color: Colors.white, size: 36),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '✨ AI is working...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  step.$2,
                  key: ValueKey(_currentStep),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Step dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_steps.length, (i) {
                  final active = i == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: active ? AppGradients.brand : null,
                      color: active
                          ? null
                          : (isDark ? Colors.white24 : AppColors.lightBorder),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
