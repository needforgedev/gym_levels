import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Base container for every screen — enforces background and the stack-friendly
/// sizing the prototype's `ScreenBase` relies on.
class ScreenBase extends StatelessWidget {
  const ScreenBase({
    super.key,
    this.background = AppPalette.voidBg,
    required this.child,
  });

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `Material(type: transparency)` gives every child a Material ancestor
    // without painting anything. Required by `Slider`, `Switch`, `TextField`,
    // `InkWell`, etc. — none of our screens wrap in Scaffold, so without this
    // those widgets throw "No Material widget found" at render time.
    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: background,
        child: SafeArea(
          bottom: false,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}
