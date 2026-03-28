import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/phone_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDw_NH-upfoA7x3fX2eW3IOlaEzjBY4co0',
      appId: '1:32379336494:android:dc4045b99bd2bf824decbf',
      messagingSenderId: '32379336494',
      projectId: 'veylo-app',
      storageBucket: 'veylo-app.firebasestorage.app',
    ),
  );
  runApp(const VeyloApp());
}

class VeyloApp extends StatelessWidget {
  const VeyloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc()..add(CheckAuthStatus()),
      child: MaterialApp(
        title: 'Veylo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/phone-auth': (context) => const PhoneAuthScreen(),
          '/home': (context) =>
              const Scaffold(body: Center(child: Text('🏠 Главная — скоро!'))),
        },
      ),
    );
  }
}
