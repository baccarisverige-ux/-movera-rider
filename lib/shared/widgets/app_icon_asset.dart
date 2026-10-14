import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An icon from the asset bundle: an SVG is drawn in [color] (its strokes use
/// currentColor), a bitmap is drawn as is.
class AppIconAsset extends StatelessWidget {
  const AppIconAsset(this.asset, {super.key, required this.size, this.color});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color!, BlendMode.srcIn),
      );
    }
    return Image.asset(
      asset,
      excludeFromSemantics: true,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
