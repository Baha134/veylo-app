import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/phone_auth_screen.dart';
import '../../features/profile/screens/onboarding_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/bloc/feed_bloc.dart';
import '../../features/feed/repositories/feed_repository.dart';
import '../../features/requests/screens/requests_screen.dart';
import '../../features/requests/repositories/request_repository.dart';

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

    // ← было '/home', теперь '/feed'
    if (isComplete && state.matchedLocation == '/onboarding') {
      return '/feed';
    }

    // Защита от захода на '/' или '/home' после логина
    if (isComplete &&
        (state.matchedLocation == '/' || state.matchedLocation == '/home')) {
      return '/feed';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, s) => const SplashScreen()),
    GoRoute(path: '/auth/login', builder: (_, s) => const LoginScreen()),
    GoRoute(path: '/auth/phone', builder: (_, s) => const PhoneAuthScreen()),
    GoRoute(path: '/onboarding', builder: (_, s) => const OnboardingScreen()),

    // ← Этап 3: лента
    GoRoute(
      path: '/feed',
      builder: (context, state) => BlocProvider(
        create: (_) => FeedBloc(
          feedRepository: FeedRepository(),
          requestRepository: RequestRepository(),
        ),
        child: const FeedScreen(),
      ),
    ),

    // ← Этап 3: входящие запросы
    GoRoute(
      path: '/requests',
      builder: (context, state) => RepositoryProvider(
        create: (_) => RequestRepository(),
        child: const RequestsScreen(),
      ),
    ),
  ],
);
