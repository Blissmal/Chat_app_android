import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // While checking auth state, show the branded splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBrandedSplash(theme);
        }

        // Animated Switcher provides a smooth cross-fade between login and home
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: snapshot.hasData ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }

  Widget _buildBrandedSplash(ThemeData theme) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Modern subtle gradient for depth
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              theme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Stylized Logo Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 80,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'CHATLY',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: theme.primaryColor,
              ),
            ),
            const Spacer(),
            // Modern thin loader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Securing your connection...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}