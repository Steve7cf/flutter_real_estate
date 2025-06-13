import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:real_estate/auth/auth_services.dart';
import 'package:real_estate/screens/app_loading_page.dart';
import 'package:real_estate/screens/home.dart';
import 'package:real_estate/screens/onboarding.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    this.pageIfNotConnected,
  });

  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthService>(
      valueListenable: authService,
      builder: (context, authServiceValue, child) {
        return StreamBuilder<User?>(
          stream: authServiceValue.user,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingPage();
            }
            return snapshot.hasData 
                ? const HomePage() 
                : pageIfNotConnected ?? const OnboardingPage();
          },
        );
      },
    );
  }
}