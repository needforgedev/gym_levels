import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Radio card used by every onboarding single-select screen (tenure,
/// reward style, weight direction, session minutes, etc).
///
/// Visual matches design v2 `OBRadioCard` (`design/v2/onboarding-shell.jsx`):
/// 16px-padded card, optional 40px icon block on the left, big title
/// + smaller subtitle in the middle, and a 22px round radio dot on the
/// right. Selected state warms to amber + violet gradient with a soft
/// outer glow; unselected sits on dark violet card-bg.
class OnboardingRadioTile extends StatelessWidget {
  const OnboardingRadioTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.themeColor = AppPalette.amber,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;

  /// Optional icon (typically `Icon(Icons.xxx)`) — rendered inside the
  /// 40px violet/amber square block on the left of the row.
  final Widget? icon;

  final bool selected;
  final VoidCallback onTap;

  /// Kept for compat — most callers can omit. Ignored visually since
  /// design v2 uses a fixed amber+violet selected state regardless of
  /// section theme.
  // ignore: unused_element_parameter
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppPalette.amber.withValues(alpha: 0.16),
                        AppPalette.purple.withValues(alpha: 0.12),
                      ],
                    )
                  : null,
              color: selected
                  ? null
                  : AppPalette.bgCard.withValues(alpha: 0.7),
              border: Border.all(
                color: selected
                    ? AppPalette.amber.withValues(alpha: 0.55)
                    : AppPalette.purple.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppPalette.amber.withValues(alpha: 0.45),
                        blurRadius: 20,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selected
                          ? AppPalette.amber.withValues(alpha: 0.20)
                          : AppPalette.purple.withValues(alpha: 0.12),
                      border: Border.all(
                        color: selected
                            ? AppPalette.amber.withValues(alpha: 0.40)
                            : AppPalette.purple.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: IconTheme(
                      data: IconThemeData(
                        size: 18,
                        color: selected
                            ? AppPalette.amber
                            : AppPalette.purpleSoft,
                      ),
                      child: icon!,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _RadioDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppPalette.amber : Colors.transparent,
        border: Border.all(
          color: selected
              ? AppPalette.amber
              : AppPalette.purple.withValues(alpha: 0.40),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.voidBg,
              ),
            )
          : null,
    );
  }
}

/// Multi-select pill chip used by onboarding screens that take a list
/// (priority muscles, equipment, limitations, training styles). Matches
/// design v2 `OBChip` — 22px-radius pill, amber-tinted when selected,
/// violet-ghost when unselected, optional disabled state.
class OnboardingChip extends StatelessWidget {
  const OnboardingChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: disabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: selected
                    ? AppPalette.amber.withValues(alpha: 0.18)
                    : AppPalette.purple.withValues(alpha: 0.08),
                border: Border.all(
                  color: selected
                      ? AppPalette.amber.withValues(alpha: 0.55)
                      : AppPalette.purple.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppPalette.amber.withValues(alpha: 0.50),
                          blurRadius: 14,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppPalette.amber
                      : disabled
                          ? AppPalette.textDim
                          : AppPalette.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
