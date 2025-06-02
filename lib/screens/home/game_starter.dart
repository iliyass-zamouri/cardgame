import 'package:cardgame/GameState_VM.dart';
import 'package:cardgame/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StartGameWidget extends StatefulWidget {
  const StartGameWidget({Key? key}) : super(key: key);

  @override
  State<StartGameWidget> createState() => _StartGameWidgetState();
}

class _StartGameWidgetState extends State<StartGameWidget> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: DecoratedBox(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(Assets.background.path),
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4), BlendMode.darken),
                fit: BoxFit.fitHeight)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                "Card Game",
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<GameViewModel>().newGame();
                },
                child: const Text("New Game",
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
