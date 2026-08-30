import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:flutter/material.dart';

class CashIcon extends StatelessWidget {
  const CashIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/cash.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

class ChipIcon extends StatelessWidget {
  const ChipIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/chip.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

class CurrencyIcon extends StatelessWidget {
  const CurrencyIcon({super.key, required this.currency, this.size = 16});

  final CurrencyType currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (currency) {
      CurrencyType.money => CashIcon(size: size),
      CurrencyType.chips => ChipIcon(size: size),
    };
  }
}
