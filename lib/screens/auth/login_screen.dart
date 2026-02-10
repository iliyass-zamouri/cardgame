import 'package:flutter/material.dart';
import 'package:shadow_hand/screens/auth/register_screen.dart';
import 'package:shadow_hand/services/auth_service.dart';
import 'package:shadow_hand/screens/home/home_screen.dart';
import 'package:shadow_hand/GameState_VM.dart';
import 'package:shadow_hand/background.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (context) => GameViewModel(),
              child: GameBackground(
                child: HomeScreen(
                  userId: result['userId'],
                  username: result['username'],
                  totalPoints: result['totalPoints'],
                  wins: result['wins'],
                  losses: result['losses'],
                  currentStreak: result['currentStreak'],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildTitle(),
                    const SizedBox(height: 40),
                    _buildUsernameField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 30),
                    _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildRegisterLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.yellow.shade400,
            Colors.orange.shade500,
            Colors.red.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.casino,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
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
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: _usernameController,
        decoration: const InputDecoration(
          labelText: 'Username',
          prefixIcon: Icon(Icons.person, color: Color(0xFF6B46C1)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your username';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF6B46C1)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF6B46C1),
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) {
        setState(() {});
        _login();
      },
      onTapCancel: () => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isLoading
                  ? [
                      Colors.green.shade600,
                      Colors.green.shade700,
                      Colors.green.shade800,
                    ]
                  : [
                      Colors.green.shade400,
                      Colors.green.shade500,
                      Colors.green.shade600,
                    ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'LOGGING IN...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text(
            'Register',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
