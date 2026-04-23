import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Single themed radio-style row used across every onboarding radio screen
/// (tenure, reward style, weight direction, session minutes). Abstracted from
/// the ad-hoc tile in the original experience screen so every radio looks the
/// same on every section theme.
class OnboardingRadioTile extends StatelessWidget {
  const OnboardingRadioTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.themeColor,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final Widget? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? themeColor.withValues(alpha: 0.12)
                : AppPalette.slate,
            border: Border.all(
              color: selected ? themeColor : AppPalette.strokeSubtle,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: selected ? themeColor : AppPalette.textSecondary,
                    size: 18,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: AppSpace.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppType.label(
                        color: selected ? themeColor : AppPalette.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppType.bodySM(
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check, color: themeColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
