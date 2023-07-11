import 'package:flutter/material.dart';
class Bird extends StatelessWidget {
  const Bird({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Image.asset('assets/images/catrronbird.gif'),
      height: 100,
      width: 100,
    );
  }
}
