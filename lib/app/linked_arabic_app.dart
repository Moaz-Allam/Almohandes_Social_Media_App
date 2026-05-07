import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/app_repositories.dart';
import '../data/session/session_store.dart';
import '../features/home/main_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../state/app_controller.dart';
import '../state/app_scope.dart';
import 'splash_screen.dart';

class LinkedArabicApp extends StatefulWidget {
  const LinkedArabicApp({super.key, this.sessionStore, this.repositories});

  final SessionStore? sessionStore;
  final AppRepositories? repositories;

  @override
  State<LinkedArabicApp> createState() => _LinkedArabicAppState();
}

class _LinkedArabicAppState extends State<LinkedArabicApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    final sessionStore = widget.sessionStore ?? SharedPreferencesSessionStore();
    _controller = AppController(
      sessionStore: sessionStore,
      repositories:
          widget.repositories ??
          AppRepositories.production(sessionStore: sessionStore),
    )..bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'المهندس',
            locale: const Locale('ar'),
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _controller.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: _controller.isBootstrapped
                ? (_controller.isSignedIn
                      ? const MainShell()
                      : const OnboardingScreen())
                : const SplashScreen(),
          );
        },
      ),
    );
  }
}
