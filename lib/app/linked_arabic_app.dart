import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/app_repositories.dart';
import '../data/session/session_store.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/main_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../state/app_controller.dart';
import '../state/app_scope.dart';

class LinkedArabicApp extends StatefulWidget {
  const LinkedArabicApp({super.key, this.sessionStore, this.repositories});

  final SessionStore? sessionStore;
  final AppRepositories? repositories;

  @override
  State<LinkedArabicApp> createState() => _LinkedArabicAppState();
}

class _LinkedArabicAppState extends State<LinkedArabicApp> {
  late final AppController _controller;
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  bool _isShowingResetPassword = false;

  @override
  void initState() {
    super.initState();
    final sessionStore = widget.sessionStore ?? SharedPreferencesSessionStore();
    _controller = AppController(
      sessionStore: sessionStore,
      repositories:
          widget.repositories ??
          AppRepositories.production(sessionStore: sessionStore),
    );
    _controller.bootstrap();
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(_handleAuthStateChange);
    } catch (_) {
      // Supabase is optional in local/offline runs.
    }
    _listenForResetPasswordLinks();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleAuthStateChange(AuthState state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      _openResetPasswordScreen();
    }
  }

  void _listenForResetPasswordLinks() {
    try {
      final appLinks = AppLinks();
      appLinks.getInitialLink().then((uri) {
        if (uri != null) {
          unawaited(_handleIncomingLink(uri));
        }
      });
      appLinks.getLatestLink().then((uri) {
        if (uri != null) {
          unawaited(_handleIncomingLink(uri));
        }
      });
      _deepLinkSubscription = appLinks.uriLinkStream.listen(
        (uri) => unawaited(_handleIncomingLink(uri)),
        onError: (_) {},
      );
    } catch (_) {
      // Deep links are optional in local/offline runs.
    }
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    if (!_isResetPasswordLink(uri)) {
      return;
    }
    await _recoverPasswordSessionFromLink(uri);
    if (!mounted) {
      return;
    }
    _openResetPasswordScreen();
  }

  bool _isResetPasswordLink(Uri uri) {
    return uri.scheme == 'com.almohandes.app' &&
        (uri.host == 'reset-password' ||
            uri.pathSegments.contains('reset-password'));
  }

  Future<void> _recoverPasswordSessionFromLink(Uri uri) async {
    try {
      final auth = Supabase.instance.client.auth;
      if (auth.currentSession != null || !_hasAuthCredentials(uri)) {
        return;
      }
      await auth.getSessionFromUrl(uri);
    } catch (_) {
      // The Supabase deep-link observer may already have consumed the session.
    }
  }

  bool _hasAuthCredentials(Uri uri) {
    return uri.fragment.contains('access_token') ||
        uri.queryParameters.containsKey('code');
  }

  void _openResetPasswordScreen() {
    if (_isShowingResetPassword) {
      return;
    }
    _isShowingResetPassword = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _isShowingResetPassword = false;
        return;
      }
      navigator
          .push(MaterialPageRoute(builder: (_) => const ResetPasswordScreen()))
          .whenComplete(() => _isShowingResetPassword = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
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
                : const Scaffold(body: SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
