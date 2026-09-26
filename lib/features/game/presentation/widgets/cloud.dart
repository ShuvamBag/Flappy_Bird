import 'package:flutter/material.dart';

class Cloud extends StatelessWidget {
  final double size;

  const Cloud({super.key, this.size = 150});
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset('assets/images/cloud.gif'),
    );
  }
}
