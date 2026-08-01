import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bucket_screen.dart';
import 'walkthrough_screen.dart';

const walkthroughSeenKey = 'walkthrough_seen';

class AppLaunchScreen extends StatefulWidget {
  const AppLaunchScreen({super.key});

  @override
  State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _brandOpacity;
  late final Animation<double> _brandScale;
  late final Animation<double> _pageOpacity;
  late final Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    _brandOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1), weight: 58),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 42),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _brandScale = Tween<double>(
      begin: 0.86,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _pageOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.56, 1, curve: Curves.easeOut),
    );
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.055), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.56, 1, curve: Curves.easeOutCubic),
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    await _controller.forward();
    final preferences = SharedPreferencesAsync();
    final seen = await preferences.getBool(walkthroughSeenKey) ?? false;
    if (!mounted || seen) return;

    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const WalkthroughScreen()));
    await preferences.setBool(walkthroughSeenKey, true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: _pageOpacity,
          child: SlideTransition(
            position: _pageSlide,
            child: const BucketScreen(),
          ),
        ),
        IgnorePointer(
          child: FadeTransition(
            opacity: _brandOpacity,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: ScaleTransition(
                  scale: _brandScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 42,
                          color: colors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'WordBucket',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
