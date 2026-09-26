import 'package:flutter/material.dart';

class Bird extends StatelessWidget {
  final double size;

  const Bird({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset('assets/images/catrronbird.gif'),
    );
  }
}
