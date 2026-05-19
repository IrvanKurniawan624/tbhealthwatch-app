import 'package:flutter/material.dart';

class SurveillancePillLabel extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const SurveillancePillLabel({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.7,
          color: textColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
