import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:real_estate/auth/auth_layout.dart';
import 'package:real_estate/firebase_options.dart';
import 'package:real_estate/screens/bookmark.dart';
import 'package:real_estate/screens/forget_password.dart';
import 'package:real_estate/screens/home.dart';
import 'package:real_estate/screens/login.dart';
import 'package:real_estate/screens/messages.dart';
import 'package:real_estate/screens/notification.dart';
import 'package:real_estate/screens/onboarding.dart';
import 'package:real_estate/screens/profile.dart';
import 'package:real_estate/screens/signup.dart';
import 'package:real_estate/screens/add_listing.dart';
import 'package:real_estate/screens/edit_listing.dart';
import 'package:real_estate/models/property.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  // You can handle background messages here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Optionally request permissions on app start (for iOS, Android 13+)
  await FirebaseMessaging.instance.requestPermission();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    darkModeNotifier.addListener(_onDarkModeChanged);
    // FCM foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotificationBanner(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          icon: Icons.notifications,
          backgroundColor: const Color(0xff35573B),
          textColor: Colors.white,
        );
      }
    });
  }

  @override
  void dispose() {
    darkModeNotifier.removeListener(_onDarkModeChanged);
    super.dispose();
  }

  void _onDarkModeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff35573B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(),
        primaryColor: const Color(0xff35573B),
        cardColor: Colors.white,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff35573B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        primaryColor: const Color(0xff35573B),
        cardColor: const Color(0xFF23272A),
        scaffoldBackgroundColor: const Color(0xFF181A1B),
      ),
      themeMode: darkModeNotifier.value ? ThemeMode.dark : ThemeMode.light,
      home: const OnboardingPage(),
      routes: {
        '/auth': (context) => const AuthLayout(),
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const RegisterScreen(),
        '/reset': (context) => const ForgotPasswordScreen(),
        '/message': (context) => const MessageScreen(),
        '/profile': (context) =>
            ProfileScreen(darkModeNotifier: darkModeNotifier),
        '/bookmark': (context) => BookmarksScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/homePage': (context) => const HomePage(),
        '/addListing': (context) => const AddListingScreen(),
        '/editListing': (context) {
          final property =
              ModalRoute.of(context)!.settings.arguments as Property;
          return EditListingScreen(property: property);
        },
      },
      initialRoute: '/auth',
      navigatorKey: navigatorKey,
    );
  }
}

// Add a global navigatorKey for dialogs
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void showNotificationBanner({
  required String title,
  required String body,
  IconData icon = Icons.notifications,
  Color? backgroundColor,
  Color? textColor,
}) {
  final context = navigatorKey.currentContext!;
  final overlay = Overlay.of(context);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      return _NotificationBanner(
        title: title,
        body: body,
        icon: icon,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        textColor: textColor ?? Colors.white,
        onDismiss: () => entry.remove(),
      );
    },
  );
  overlay.insert(entry);
}

class _NotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onDismiss;
  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onDismiss,
  });
  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: widget.backgroundColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.textColor, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: widget.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.body,
                          style: TextStyle(
                            color: widget.textColor.withAlpha(
                              (255 * 0.95).toInt(),
                            ),
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close,
                      color: widget.textColor.withAlpha((255 * 0.8).toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
