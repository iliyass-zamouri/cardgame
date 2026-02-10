import 'package:flutter/material.dart';
import 'package:shadow_hand/services/auth_service.dart';
import 'package:shadow_hand/screens/auth/login_screen.dart';
import 'package:shadow_hand/screens/home/home_screen.dart';
import 'package:shadow_hand/GameState_VM.dart';
import 'package:shadow_hand/background.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Add a small delay for splash screen effect
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // Check if user is logged in and token is valid
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (isLoggedIn) {
        // Validate token with server
        final isTokenValid = await AuthService.validateToken();
        
        if (isTokenValid) {
          // Get user data and navigate to home
          final userData = await AuthService.getUserData();
          if (userData != null && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (context) => GameViewModel(),
                  child: GameBackground(
                    child: HomeScreen(
                      userId: userData['userId'],
                      username: userData['username'],
                      totalPoints: userData['totalPoints'],
                      wins: userData['wins'],
                      losses: userData['losses'],
                      currentStreak: userData['currentStreak'],
                    ),
                  ),
                ),
              ),
            );
          }
        } else {
          // Token is invalid, go to login
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } else {
        // Not logged in, go to login screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      print('Splash screen error: $e');
      // On error, go to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6B46C1),
              const Color(0xFF9333EA),
              const Color(0xFFEC4899),
              const Color(0xFFF97316),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(
                Icons.casino,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              // App name
              Text(
                'Shadow Hand',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
