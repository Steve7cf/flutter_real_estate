import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:real_estate/screens/bookmark.dart';
import 'package:real_estate/screens/messages.dart';
import 'package:real_estate/screens/onboarding.dart';
import 'package:real_estate/screens/profile.dart';


void main() {
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
      home: OnboardingPage(),
      routes: {
        '/onboarding': (context) => const OnboardingPage(), // Onboarding screen
        '/message': (context) => const MessageScreen(),  
        '/profile': (context) => const ProfileScreen(), 
        '/bookmark': (context) => const BookmarksScreen(),  // Message screen
      },
    );
  }
}