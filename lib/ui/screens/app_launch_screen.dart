import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell_screen.dart';
import 'walkthrough_screen.dart';
import 'whats_new_screen.dart';

const walkthroughSeenKey = 'walkthrough_seen';
const whatsNewSeenKey = 'whats_new_seen_release';

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
  late final Animation<double> _bookTurn;
  late final Animation<double> _bookRock;
  late final Animation<double> _bookLift;
  late final Animation<double> _pageOpacity;
  late final Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _brandOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1), weight: 66),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 34),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _brandScale = Tween<double>(
      begin: 0.86,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    final bookMotion = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.64, curve: Curves.easeInOutCubic),
    );
    _bookTurn = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.34, end: 0.15), weight: 42),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.055), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.055, end: 0), weight: 28),
    ]).animate(bookMotion);
    _bookRock = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.075, end: 0.045), weight: 48),
      TweenSequenceItem(tween: Tween(begin: 0.045, end: 0), weight: 52),
    ]).animate(bookMotion);
    _bookLift = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 4, end: -9), weight: 48),
      TweenSequenceItem(tween: Tween(begin: -9, end: 0), weight: 52),
    ]).animate(bookMotion);
    _pageOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.64, 1, curve: Curves.easeOut),
    );
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.055), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.64, 1, curve: Curves.easeOutCubic),
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      await _controller.forward();
    }
    final preferences = SharedPreferencesAsync();
    final seen = await preferences.getBool(walkthroughSeenKey) ?? false;
    if (!mounted) return;

    if (seen) {
      final whatsNewSeen = await preferences.getString(whatsNewSeenKey);
      if (!mounted || whatsNewSeen == WhatsNewScreen.releaseId) return;
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const WhatsNewScreen()));
      await preferences.setString(whatsNewSeenKey, WhatsNewScreen.releaseId);
      return;
    }

    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const WalkthroughScreen()));
    await preferences.setBool(walkthroughSeenKey, true);
    await preferences.setString(whatsNewSeenKey, WhatsNewScreen.releaseId);
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
            child: const AppShellScreen(),
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
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _bookLift.value),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0018)
                              ..rotateY(_bookTurn.value)
                              ..rotateZ(_bookRock.value),
                            child: child,
                          ),
                        ),
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 42,
                            color: colors.onPrimary,
                          ),
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
