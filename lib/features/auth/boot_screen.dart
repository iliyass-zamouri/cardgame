import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/dependency_injection.dart';
import 'splash_screen.dart';

class BootScreen extends ConsumerStatefulWidget {
  const BootScreen({super.key});

  @override
  ConsumerState<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends ConsumerState<BootScreen> {
  static const _minSplash = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(_minSplash);
    if (!mounted) return;

    final session = ref.read(sessionProvider);
    if (session.isAuthenticated) {
      context.go('/lobby');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
