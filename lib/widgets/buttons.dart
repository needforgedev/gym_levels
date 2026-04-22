import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum AppButtonSize { sm, md, lg }

double _heightOf(AppButtonSize s) =>
    s == AppButtonSize.sm ? 40 : (s == AppButtonSize.md ? 48 : 56);

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = AppButtonSize.lg,
    this.icon,
    this.disabled = false,
    this.glow = GlowColor.teal,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback? onTap;
  final AppButtonSize size;
  final Widget? icon;
  final bool disabled;
  final GlowColor glow;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final h = _heightOf(size);
    final bg = background ?? AppPalette.teal;
    final fg = foreground ?? AppPalette.obsidian;
    final effectiveOnTap = disabled ? null : onTap;

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppGlow.shadow(glow, intensity: 0.8, alpha: 0.4),
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: effectiveOnTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    IconTheme(
                      data: IconThemeData(color: fg, size: 18),
                      child: icon!,
                    ),
                    const SizedBox(width: AppSpace.s3),
                  ],
                  Text(
                    label.toUpperCase(),
                    style: AppType.displaySM(color: fg).copyWith(
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = AppButtonSize.lg,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final AppButtonSize size;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final h = _heightOf(size);
    return Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppPalette.strokeSubtle, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: const IconThemeData(
                      color: AppPalette.textPrimary,
                      size: 18,
                    ),
                    child: icon!,
                  ),
                  const SizedBox(width: AppSpace.s3),
                ],
                Text(
                  label.toUpperCase(),
                  style: AppType.displaySM(color: AppPalette.textPrimary)
                      .copyWith(letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppPalette.teal,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final btn = TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s3,
        ),
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label.toUpperCase(), style: AppType.label(color: color)),
    );
    if (fullWidth) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }
}
