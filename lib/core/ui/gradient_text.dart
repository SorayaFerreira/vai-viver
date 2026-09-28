import 'package:flutter/material.dart';

import '../theme/vaiviver_tokens.dart';

/// Text filled with the brand gradient (CSS `bg-clip-text` equivalent).
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final gradient = context.tokens.brandGradient;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          gradient.createShader(Offset.zero & bounds.size),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
