
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:real_estate/auth/auth_layout.dart';
import 'package:real_estate/firebase_options.dart';
import 'package:real_estate/models/book_manager.dart';
import 'package:real_estate/screens/bookmark.dart';
import 'package:real_estate/screens/forgetPassword.dart';
import 'package:real_estate/screens/home.dart';
import 'package:real_estate/screens/login.dart';
import 'package:real_estate/screens/messages.dart';
import 'package:real_estate/screens/notification.dart';
import 'package:real_estate/screens/onboarding.dart';
import 'package:real_estate/screens/profile.dart';
import 'package:real_estate/screens/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android, // Fixed typo: currentgitPlatform -> currentPlatform
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff35573B),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(),
        primaryColor: const Color(0xff35573B),
      ),
      home: const OnboardingPage(),
      routes: {
        '/auth': (context) => const AuthLayout(),
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const RegisterScreen(),
        '/reset': (context) => const ForgotPasswordScreen(),
        '/message': (context) => const MessageScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/bookmark': (context) => BookmarksScreen(), // Fixed: BookmarkManager -> BookmarksScreen
        '/notifications': (context) => const NotificationScreen(),
        '/homePage': (context) => const HomePage(),
      },
      initialRoute: '/auth',
    );
  }
}
