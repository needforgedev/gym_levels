import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../widgets/screen_base.dart';

/// Paywall — matches design v2 (`design/v2/screens-outro.jsx`).
///
/// Layout:
///   • "Maybe later" link top-right.
///   • Big `TURN YOUR WORKOUTS / INTO A GAME` headline (INTO A GAME amber).
///   • Strapline.
///   • 3 tier pills in a row: WEEKLY ₹1,050/wk · BEST VALUE ₹3,200/3 mo
///     (selected, amber, with `SAVE 64%` badge above) · ANNUAL ₹8,800/yr
///     (with `7d TRIAL` badge).
///   • Comparison table with 8 features × FREE/PRO columns.
///   • `ACTIVATE PRO` amber CTA.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selected = 'best';

  static const _tiers = [
    _TierData(
      key: 'weekly',
      label: 'WEEKLY',
      price: '₹1,050',
      cadence: '/ wk',
      badge: null,
    ),
    _TierData(
      key: 'best',
      label: 'BEST VALUE',
      price: '₹3,200',
      cadence: '/ 3 mo',
      badge: 'SAVE 64%',
    ),
    _TierData(
      key: 'annual',
      label: 'ANNUAL',
      price: '₹8,800',
      cadence: '/ yr',
      badge: '7d TRIAL',
    ),
  ];

  static const _features = [
    _FeatureRow('Daily Quests', free: true, pro: true),
    _FeatureRow('Muscle Ranks (E → S)', free: true, pro: true),
    _FeatureRow('Workouts / week', free: '3', pro: '∞'),
    _FeatureRow('Weekly Quests', free: false, pro: true),
    _FeatureRow('Boss Challenges', free: false, pro: true),
    _FeatureRow('Advanced Analytics', free: false, pro: true),
    _FeatureRow('AI Form Check', free: false, pro: true),
    _FeatureRow('Cosmetic Skins', free: false, pro: true),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.voidBg,
      child: Stack(
        children: [
          // Amber radial wash from top.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      AppPalette.amber.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Top row: back chevron + Maybe later.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 24, 0),
                child: Row(
                  children: [
                    _BackButton(
                      onTap: () => context.go('/challenge-system'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/loader-pre-home'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppPalette.textMuted,
                      ),
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title.
                      Text(
                        'TURN YOUR WORKOUTS',
                        style: AppType.displayXL(
                          color: AppPalette.textPrimary,
                        ).copyWith(fontSize: 32, height: 1.05),
                      ),
                      Text(
                        'INTO A GAME',
                        style: AppType.displayXL(color: AppPalette.amber)
                            .copyWith(
                          fontSize: 32,
                          height: 1.05,
                          shadows: [
                            Shadow(
                              color: AppPalette.amber.withValues(alpha: 0.6),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unlock boss challenges, advanced analytics, and the full System.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppPalette.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          for (var i = 0; i < _tiers.length; i++) ...[
                            Expanded(
                              child: _TierCard(
                                data: _tiers[i],
                                selected: _selected == _tiers[i].key,
                                onTap: () => setState(
                                  () => _selected = _tiers[i].key,
                                ),
                              ),
                            ),
                            if (i < _tiers.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      _FeatureTable(rows: _features),
                      const SizedBox(height: 18),
                      _ActivateButton(
                        onTap: () => context.go('/loader-pre-home'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.purple.withValues(alpha: 0.12),
            border: Border.all(
              color: AppPalette.purple.withValues(alpha: 0.25),
            ),
          ),
          child: const Icon(
            Icons.chevron_left,
            size: 18,
            color: AppPalette.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TierData {
  const _TierData({
    required this.key,
    required this.label,
    required this.price,
    required this.cadence,
    required this.badge,
  });

  final String key;
  final String label;
  final String price;
  final String cadence;
  final String? badge;
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _TierData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? AppPalette.amber.withValues(alpha: 0.15)
                    : AppPalette.purple.withValues(alpha: 0.08),
                border: Border.all(
                  color: selected
                      ? AppPalette.amber.withValues(alpha: 0.55)
                      : AppPalette.purple.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppPalette.amber.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: selected
                          ? AppPalette.amber
                          : AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data.price,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'JetBrainsMono',
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.cadence,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (data.badge != null)
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: selected
                          ? AppPalette.amber
                          : AppPalette.amber.withValues(alpha: 0.20),
                      border: Border.all(
                        color: AppPalette.amber,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      data.badge!,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: selected
                            ? AppPalette.voidBg
                            : AppPalette.amber,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow {
  const _FeatureRow(this.label, {required this.free, required this.pro});
  final String label;
  final Object free; // bool or String
  final Object pro; // bool or String
}

class _FeatureTable extends StatelessWidget {
  const _FeatureTable({required this.rows});
  final List<_FeatureRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppPalette.purple.withValues(alpha: 0.06),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppPalette.purple.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'FEATURE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppPalette.amber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            _FeatureCell(row: rows[i], last: i == rows.length - 1),
        ],
      ),
    );
  }
}

class _FeatureCell extends StatelessWidget {
  const _FeatureCell({required this.row, required this.last});
  final _FeatureRow row;
  final bool last;

  Widget _cell(Object v, {required bool isPro}) {
    final color = isPro ? AppPalette.amber : AppPalette.success;
    if (v is bool) {
      return v
          ? Icon(Icons.check, size: 14, color: color)
          : const Text(
              '—',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim),
            );
    }
    return Text(
      v.toString(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isPro ? AppPalette.amber : AppPalette.textPrimary,
        fontFamily: 'JetBrainsMono',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppPalette.purple.withValues(alpha: 0.10),
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              row.label,
              style: const TextStyle(
                fontSize: 13,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: _cell(row.free, isPro: false)),
          ),
          Expanded(
            flex: 2,
            child: Center(child: _cell(row.pro, isPro: true)),
          ),
        ],
      ),
    );
  }
}

class _ActivateButton extends StatelessWidget {
  const _ActivateButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.amber, AppPalette.amberSoft],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.amber.withValues(alpha: 0.5),
                blurRadius: 24,
              ),
            ],
          ),
          child: Text(
            'ACTIVATE PRO',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppPalette.voidBg,
            ),
          ),
        ),
      ),
    );
  }
}
