import 'package:flutter/material.dart';

class Led extends StatefulWidget {
  const Led({super.key});

  @override
  State<Led> createState() => _LedState();

  void switchOn() {
    switchOn();
  }
}

class _LedState extends State<Led> {
  bool isOn = false;

  void switchOn() {
    setState(() {
      isOn = true;
    });
  }

  void switchOff() {
    setState(() {
      isOn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn
              ? const Color.fromARGB(255, 0, 255, 8)
              : const Color.fromARGB(255, 50, 97, 0)),
    );
  }
}
