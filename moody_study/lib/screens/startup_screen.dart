import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/error/failures.dart';
import '../models/auth_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session_expired_notifier.dart';
import '../services/user_provider.dart';
import '../utils/app_localizations.dart';
import 'character_intro_screen.dart';
import 'theme_selector_screen.dart';

enum _BootstrapState { loading, offline, serverError }

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  _BootstrapState _state = _BootstrapState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (mounted) setState(() => _state = _BootstrapState.loading);

    // 1. Cek connectivity
    final results = await Connectivity().checkConnectivity();
    final isOffline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    if (isOffline) {
      if (mounted) setState(() => _state = _BootstrapState.offline);
      return;
    }

    // 2. Tidak ada token → langsung ke login flow
    if (!ApiClient.hasToken) {
      _navigateToLogin();
      return;
    }

    // 3. Validasi token via /api/profile/me
    final result = await AuthService.getCurrentUser();
    if (!mounted) return;

    AppFailure? failure;
    AuthUser? user;
    result.fold((f) => failure = f, (u) => user = u);

    final f = failure;
    if (f != null) {
      if (f is ApiFailure && (f.statusCode == 401 || f.statusCode == 403)) {
        await ApiClient.clearToken();
        _navigateToLogin();
      } else {
        setState(() => _state = _BootstrapState.serverError);
      }
    } else if (user != null) {
      if (!mounted) return;
      context.read<UserProvider>().setUser(user!);
      _navigateToHome(user!.name ?? 'Friend');
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    SessionExpiredNotifier.instance.deactivate();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ThemeSelectorScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToHome(String userName) {
    if (!mounted) return;
    SessionExpiredNotifier.instance.activate();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CharacterIntroScreen(userName: userName),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _BootstrapState.loading => const _LoadingView(),
      _BootstrapState.offline => _ErrorView(
          icon: Icons.wifi_off_rounded,
          messageKey: 'offline',
          onRetry: _bootstrap,
        ),
      _BootstrapState.serverError => _ErrorView(
          icon: Icons.cloud_off_rounded,
          messageKey: 'server',
          onRetry: _bootstrap,
        ),
    };
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1EE86F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Memuat...',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'BlackHanSans',
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final IconData icon;
  final String messageKey; // 'offline' | 'server'
  final VoidCallback onRetry;

  const _ErrorView({
    required this.icon,
    required this.messageKey,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final message =
        messageKey == 'offline' ? l.errNetworkOffline : l.errServerProblem;

    return Scaffold(
      backgroundColor: const Color(0xFF1EE86F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'BlackHanSans',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF111111), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF111111),
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 18,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
