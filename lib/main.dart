import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/navigation/main_navigation.dart';
import 'screens/welcome/welcome_page.dart';
import 'screens/home/home_page.dart';
import 'screens/bookings/bookings_screen.dart';
import 'screens/history/history_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/booking/book_package_screen.dart';
import 'screens/booking/book_service_screen.dart';
import 'screens/packages/filter_package_list_screen.dart';
import 'screens/packages/customize_package_page.dart';
import 'screens/services/coordination_service_page.dart';
import 'screens/vendors/vendor_categories_page.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  await SupabaseConfig.initialize();
  await NotificationService().initialize();

  runApp(const DreamVentzApp());
}

class DreamVentzApp extends StatelessWidget {
  const DreamVentzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DreamVentz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'sans-serif',
      ),
      home: const AuthWrapper(),
      routes: {
        AppConstants.loginRoute: (context) => const LoginScreen(),
        AppConstants.signupRoute: (context) => const SignUpScreen(),
        AppConstants.forgotPasswordRoute: (context) =>
            const ForgotPasswordScreen(),
        AppConstants.homeRoute: (context) => const MainNavigation(),
        '/homepage': (context) => const HomePage(),
        '/bookingspage': (context) => const BookingsScreen(),
        '/historypage': (context) => const HistoryPage(),
        '/profilepage': (context) => const ProfilePage(),
        '/bookpackage': (context) => const BookPackageScreen(),
        '/bookservice': (context) => const BookServiceScreen(),
        '/vendorcategories': (context) => const VendorCategoriesPage(),
        '/packages': (context) => const FilterPackageListScreen(),
        '/customize_package_page': (context) => const CustomizePackagePage(),
        '/coordination_service_page': (context) =>
            const CoordinationServicePage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    debugPrint('🕒 Setting up Auth Listener...');
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      debugPrint(
        '🔔 Auth State Change: $event (Session: ${session != null ? "active" : "null"})',
      );

      if (mounted) {
        if (session != null &&
            (event == AuthChangeEvent.signedIn ||
                event == AuthChangeEvent.initialSession ||
                event == AuthChangeEvent.tokenRefreshed)) {
          // Save FCM token whenever user signs in
          NotificationService().saveFcmToken();

          debugPrint('🚀 Navigating to Home...');
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppConstants.homeRoute,
            (route) => false,
          );
        }
      }
    });
  }

  Future<void> _checkInitialSession() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final session = Supabase.instance.client.auth.currentSession;
    debugPrint(
      '🧐 Initial Session Check: ${session != null ? "Authenticated" : "Not Authenticated"}',
    );

    // Save FCM token if already logged in
    if (session != null) {
      await NotificationService().saveFcmToken();
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SplashScreen();
    }

    try {
      if (SupabaseConfig.isAuthenticated) {
        debugPrint('🏠 User authenticated, showing MainNavigation');
        return const MainNavigation();
      }
    } catch (e) {
      debugPrint('Error checking auth state: $e');
    }

    debugPrint('👋 User not authenticated, showing WelcomePage');
    return const WelcomePage();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF121212), Colors.black],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icons/DV.png', width: 150),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
              ),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "Dream",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: "Ventz",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
