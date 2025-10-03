import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showGraph;

  const AppLogo({
    super.key,
    this.size = 40.0,
    this.color,
    this.showGraph = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/dial dark.png',
        fit: BoxFit.contain,
        // color: color,
        // colorBlendMode: color != null ? BlendMode.srcIn : BlendMode.dst,
      ),
    );
  }
}

