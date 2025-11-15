import 'package:flutter/material.dart';
import 'package:campus_pulse/theme.dart';
import 'package:campus_pulse/screens/onboarding_screen.dart';
import 'package:campus_pulse/screens/main_screen.dart';
import 'package:campus_pulse/auth/auth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Insforge authentication
  await DefaultAuthManager.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aftercls - Campus Viral Social',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DefaultAuthManager.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in
          return const MainScreen();
        } else {
          // User is not logged in
          return const OnboardingScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwipzeeColors.lightGray,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: SwipzeeStyles.fireGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SwipzeeColors.fireOrange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                size: 60,
                color: SwipzeeColors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Swipzee',
              style: SwipzeeTypography.heading1.copyWith(
                color: SwipzeeColors.darkGray,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Campus Viral Social',
              style: SwipzeeTypography.bodyLarge.copyWith(
                color: SwipzeeColors.mediumGray,
              ),
            ),
            
            const SizedBox(height: 48),
            
            CircularProgressIndicator(
              color: SwipzeeColors.fireOrange,
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Loading amazing content...',
              style: SwipzeeTypography.bodyMedium.copyWith(
                color: SwipzeeColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
