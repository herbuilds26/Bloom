import 'package:flutter/material.dart';
import 'bloom_splash.dart';
import 'theme.dart';

class BloomApp extends StatefulWidget {
  const BloomApp({super.key});

  @override
  State<BloomApp> createState() => _BloomAppState();
}

class _BloomAppState extends State<BloomApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final away = DateTime.now().difference(_pausedAt!);
        _pausedAt = null;
        // When the user leaves Bloom and reopens it after being away:
        if (away > const Duration(seconds: 4)) {
          _navigatorKey.currentState?.push(
            PageRouteBuilder<void>(
              pageBuilder: (_, __, ___) => const BloomSplash(isReopen: true),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: BloomTheme.paletteNotifier,
        builder: (context, _, __) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Bloom',
          debugShowCheckedModeBanner: false,
          theme: BloomTheme.light,
          darkTheme: BloomTheme.light,
          themeMode: ThemeMode.light,
          home: const BloomSplash(),
        ),
      );
}
