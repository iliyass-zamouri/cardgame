import 'package:cardgame/ui/background.dart';
import 'package:cardgame/ui/flame/card_fonts.dart';
import 'package:cardgame/ui/screens/home/home_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureCardFontsLoaded();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardGame',
      debugShowCheckedModeBanner: false,
      theme: buildCasinoTheme(),
      home: const GameBackground(
        child: HomeScreen(),
      ),
    );
  }
}
