import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/screen_base.dart';
import '../widgets/system_header.dart';

/// PRD §8 Screen 21 — Paywall.
/// Pure UI in Phase 1.5; IAP wiring lands in Phase 2.6.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  static const _tiers = [
    _TierData(
      key: 'weekly',
      label: 'WEEKLY',
      price: '₹1,050',
      cadence: '/ week',
    ),
    _TierData(
      key: 'best',
      label: 'BEST VALUE',
      price: '₹3,200',
      cadence: '/ 3 months',
      badge: 'SAVE 64%',
    ),
    _TierData(
      key: 'annual',
      label: 'ANNUAL',
      price: '₹8,800',
      cadence: '/ year',
      badge: '7-DAY TRIAL',
    ),
  ];

  String _selected = 'best';

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.obsidian,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.s6),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SystemHeader(
                          kicker: 'ACTIVATE PRO',
                          color: AppPalette.xpGold,
                        ),
                        GhostButton(
                          label: 'SKIP',
                          color: AppPalette.textMuted,
                          onTap: () => context.go('/loader-pre-home'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s6),
                    Text(
                      'TURN YOUR\nWORKOUTS\nINTO A GAME',
                      style: AppType.displayXL(color: AppPalette.textPrimary)
                          .copyWith(height: 44 / 40),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      'Unlock weekly + boss quests, advanced analytics, cosmetic rank skins, and unlimited workout logging.',
                      style: AppType.bodyMD(color: AppPalette.textSecondary),
                    ),
                    const SizedBox(height: AppSpace.s6),
                    ..._tiers.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s3),
                        child: _TierCard(
                          data: t,
                          selected: _selected == t.key,
                          onTap: () => setState(() => _selected = t.key),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpace.s5),
                    PrimaryButton(
                      label: 'ACTIVATE PRO',
                      // IAP wiring lands in Phase 2.6. For now just advance.
                      onTap: () => context.go('/loader-pre-home'),
                      glow: GlowColor.xp,
                      background: AppPalette.xpGold,
                    ),
                    const SizedBox(height: AppSpace.s3),
                    Text(
                      'Cancel any time · Purchase validated by the store.',
                      textAlign: TextAlign.center,
                      style: AppType.bodySM(color: AppPalette.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
    this.badge,
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s5),
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.xpGold.withValues(alpha: 0.1)
                : AppPalette.carbon,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppPalette.xpGold : AppPalette.strokeSubtle,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppPalette.xpGold.withValues(alpha: 0.4),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: AppSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.label,
                          style: AppType.label(
                            color: selected
                                ? AppPalette.xpGold
                                : AppPalette.textPrimary,
                          ),
                        ),
                        if (data.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.xpGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppPalette.xpGold),
                            ),
                            child: Text(
                              data.badge!,
                              style: AppType.label(color: AppPalette.xpGold)
                                  .copyWith(fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          data.price,
                          style: AppType.monoLG(color: AppPalette.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.cadence,
                          style: AppType.bodySM(color: AppPalette.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppPalette.xpGold : AppPalette.strokeSubtle,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.xpGold,
                ),
              ),
            )
          : null,
    );
  }
}
