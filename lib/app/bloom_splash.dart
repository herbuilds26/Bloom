import 'dart:async';
import 'package:flutter/material.dart';
import 'splash_lily.dart';
import '../features/home/bloom_home.dart';
import '../features/auth/auth_service.dart';
import '../features/auth/bloom_auth_page.dart';

class BloomSplash extends StatefulWidget {
  const BloomSplash({super.key, this.isReopen = false});
  final bool isReopen;

  @override
  State<BloomSplash> createState() => _BloomSplashState();
}

class _BloomSplashState extends State<BloomSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
      value: 0.0,
    );

    // Guarantee that animation begins only after the first frame is painted,
    // so cold start engine initialization and shader compilation will never
    // eat into the animation or show an already-bloomed flower.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.forward(from: 0.0);
    });

    _timer = Timer(const Duration(milliseconds: 4350), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (_launched || !mounted) return;
    _launched = true;
    _timer?.cancel();
    if (widget.isReopen && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    final target = AuthService.instance.isLoggedIn
        ? const BloomHome()
        : const BloomAuthPage();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToHome,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF0DDF4),
                Color(0xFFFFF5F1),
                Color(0xFFF8E3ED),
              ],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SplashLily(progress: t),
                    const SizedBox(height: 0),
                    Opacity(
                      opacity: Curves.easeIn.transform(
                        ((t - .76) / .18).clamp(0.0, 1.0).toDouble(),
                      ),
                      child: const Text(
                        'Bloom',
                        style: TextStyle(
                          fontFamily: 'serif',
                          color: Color(0xFF542565),
                          fontSize: 60,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: Curves.easeIn.transform(
                        ((t - .89) / .11).clamp(0.0, 1.0).toDouble(),
                      ),
                      child: const Text(
                        'your cycle, your way',
                        style: TextStyle(
                          color: Color(0xFF754483),
                          letterSpacing: 2.4,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
