import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'progress_header.dart';
import 'screen_base.dart';

/// Onboarding shell — matches design v2 `OBShell`
/// (`design/v2/onboarding-shell.jsx`).
///
/// Layout (top → bottom):
///   1. Top row: 34px round chevron-back + thin gradient progress bar +
///      "NN%" mono label (right).
///   2. Optional `[SYS] {subtitle}` italic mono kicker + big display title.
///   3. Scrollable body provided by the caller.
///   4. Sticky amber-gradient pill `CONTINUE →` at the bottom.
///
/// The accent color (per onboarding section) tints the progress bar's
/// left end and the ambient radial wash behind the body. The CTA is
/// always amber-gradient regardless of section.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.section,
    required this.percent,
    this.kicker,
    this.subtitle,
    this.title,
    required this.onBack,
    required this.onNext,
    this.nextEnabled = true,
    this.continueLabel = 'CONTINUE',
    required this.child,
  });

  final OnboardingSection section;
  final double percent;

  /// Legacy kicker — kept for compatibility but no longer rendered. The
  /// section name moves to the dedicated section-intro splash screen per
  /// design v2; the in-question chrome shows only progress + back +
  /// optional SYS subtitle + title.
  final String? kicker;

  /// Italic mono `[SYS] {subtitle}` line above the question title.
  final String? subtitle;

  /// Big display question (Bebas Neue ~28px). Shows below the SYS line.
  final String? title;

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool nextEnabled;
  final String continueLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accent = sectionAccent(section);
    return ScreenBase(
      background: AppPalette.voidBg,
      child: Stack(
        children: [
          // Ambient radial wash from top with section accent — matches
          // the design's `radial-gradient(ellipse at 50% -10%, accent22)`.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1.4),
                    radius: 1.1,
                    colors: [
                      accent.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              _ProgressRow(
                accent: accent,
                percent: percent,
                onBack: onBack,
              ),
              if (subtitle != null || title != null) ...[
                const SizedBox(height: 6),
                _Header(
                  subtitle: subtitle,
                  title: title,
                  accent: accent,
                ),
              ],
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: child,
                ),
              ),
              _ContinueBar(
                onTap: onNext,
                enabled: nextEnabled,
                label: continueLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.accent,
    required this.percent,
    required this.onBack,
  });

  final Color accent;
  final double percent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.purple.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppPalette.purple.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: AppPalette.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: AppPalette.purple.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppPalette.purple.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (percent.clamp(0, 100)) / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [accent, AppPalette.amber],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.55),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            child: Text(
              '${percent.round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrainsMono',
                color: AppPalette.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.subtitle,
    required this.title,
    required this.accent,
  });

  final String? subtitle;
  final String? title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null)
            Text(
              '[SYS] ${subtitle!.toUpperCase()}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: accent,
                fontFamily: 'JetBrainsMono',
                fontStyle: FontStyle.italic,
              ),
            ),
          if (title != null) ...[
            if (subtitle != null) const SizedBox(height: 8),
            Text(
              title!,
              style: AppType.displayMD(color: AppPalette.textPrimary)
                  .copyWith(fontSize: 28, height: 1.05, letterSpacing: 0.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.onTap,
    required this.enabled,
    required this.label,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, safe + 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(27),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              gradient: enabled
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppPalette.amber, AppPalette.amberSoft],
                    )
                  : null,
              color: enabled
                  ? null
                  : AppPalette.purple.withValues(alpha: 0.20),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppPalette.amber.withValues(alpha: 0.50),
                        blurRadius: 24,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: enabled
                        ? AppPalette.voidBg
                        : AppPalette.textDim,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: enabled ? AppPalette.voidBg : AppPalette.textDim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
