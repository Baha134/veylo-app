import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/phone_auth_screen.dart';
import '../../features/profile/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (state.matchedLocation.startsWith('/auth')) return null;
      return '/auth/login';
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final isComplete = doc.exists && (doc.data()?['isProfileComplete'] == true);

    if (!isComplete && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    if (isComplete && state.matchedLocation == '/onboarding') {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, s) => const SplashScreen()),
    GoRoute(path: '/auth/login', builder: (_, s) => const LoginScreen()),
    GoRoute(path: '/auth/phone', builder: (_, s) => const PhoneAuthScreen()),
    GoRoute(path: '/onboarding', builder: (_, s) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (_, s) => const HomeScreen()),
  ],
);
