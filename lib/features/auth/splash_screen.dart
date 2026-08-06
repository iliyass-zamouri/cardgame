import 'package:flutter/material.dart';

import '../../core/widgets/waiting_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const tips = [
    'Lowest score wins the round.',
    'Pick your stake before queuing.',
    'Private room games are for friends only.',
    'Reveal phase — peek or launch at the right time.',
  ];

  @override
  Widget build(BuildContext context) {
    return const WaitingScreen(tips: tips);
  }
}
