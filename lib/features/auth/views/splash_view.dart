import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    // Check authentication state after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Wait until AuthViewModel is initialized
    while (!authViewModel.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Delay briefly to allow splash animation to settle
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    if (authViewModel.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = context.scaleFactor;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E1E38)]
                : [const Color(0xFFEEF2F6), const Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        children: [
                          // App Icon/Logo Container
                          Container(
                            padding: EdgeInsets.all(24 * scaleFactor),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 30 * scaleFactor,
                                  offset: Offset(0, 10 * scaleFactor),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.note_alt_rounded,
                              size: 72 * scaleFactor,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 24 * scaleFactor),
                          // Title
                          Text(
                            'Notes Manager',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 32 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8 * scaleFactor),
                          // Subtitle
                          Text(
                            'Organize your thoughts beautifully',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 16 * scaleFactor,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              LoadingSpinner(size: 36 * scaleFactor),
              SizedBox(height: 48 * scaleFactor),
            ],
          ),
        ),
      ),
    );
  }
}
