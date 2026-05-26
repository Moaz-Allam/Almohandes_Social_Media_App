import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/app_repositories.dart';
import '../data/session/session_store.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/main_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../models/app_theme_mode.dart';
import '../shared/widgets/upload_progress_overlay.dart';
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
    // AppScope is an InheritedNotifier — descendants opt in via
    // AppScope.watch only where they actually need to rebuild.
    //
    // MaterialApp is built ONCE and stays stable. Only the parts that
    // genuinely depend on AppController state subscribe via dedicated
    // listeners below.
    return AppScope(
      controller: _controller,
      child: _AppShell(controller: _controller, navigatorKey: _navigatorKey),
    );
  }
}

/// Wraps MaterialApp so only theme + bootstrap/sign-in state rebuild it,
/// instead of every notifyListeners on AppController rebuilding the whole
/// app tree.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.controller, required this.navigatorKey});

  final AppController controller;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    // Only theme changes rebuild MaterialApp. Other AppController notifies
    // (likes, messages, profile…) propagate via AppScope.watch deeper in
    // the tree without invalidating navigation/themes.
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: controller.themeModeListenable,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'المهندس',
          // Force the entire app into Arabic / RTL. Material widgets
          // (date pickers, snackbars, dialogs, tooltips) pick up the right
          // strings + direction from these delegates; the explicit
          // Directionality wrapper guarantees RTL even for widgets that
          // ignore Localizations.
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: UploadProgressOverlay(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          // Follow OS by default, or the user's explicit override from
          // Settings. MaterialApp handles the brightness flip automatically
          // when the platform brightness changes (ThemeMode.system).
          themeMode: themeMode.materialMode,
          home: _AppRoot(controller: controller),
        );
      },
    );
  }
}

/// Only this small widget listens to AppController for routing. When the
/// controller notifies, only this subtree (and whichever consumer widgets
/// opted in further down) rebuilds — not the whole MaterialApp.
class _AppRoot extends StatelessWidget {
  const _AppRoot({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.isBootstrapped) {
          return _BootstrapSplash(
            onRetry: () => controller.bootstrap(),
          );
        }
        if (!controller.isSignedIn) {
          return const OnboardingScreen();
        }
        return const MainShell();
      },
    );
  }
}

/// Splash shown until [AppController.bootstrap] completes. If it doesn't
/// finish within ~8 seconds we surface a retry CTA so a hung network
/// doesn't leave the user staring at a spinner forever.
class _BootstrapSplash extends StatefulWidget {
  const _BootstrapSplash({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<_BootstrapSplash> createState() => _BootstrapSplashState();
}

class _BootstrapSplashState extends State<_BootstrapSplash> {
  Timer? _timeoutTimer;
  bool _showRetry = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _showRetry = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_retrying) {
      return;
    }
    setState(() {
      _retrying = true;
      _showRetry = false;
    });
    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() => _retrying = false);
        _timeoutTimer?.cancel();
        _timeoutTimer = Timer(const Duration(seconds: 8), () {
          if (mounted) {
            setState(() => _showRetry = true);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Image(
              image: AssetImage('assets/branding/app_logo.png'),
              width: 168,
              height: 168,
            ),
            const SizedBox(height: 18),
            if (_showRetry) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'يستغرق التحميل وقتا أطول من المعتاد. تحقق من اتصالك بالإنترنت.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ] else
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
          ],
        ),
      ),
    );
  }
}
