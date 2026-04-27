import 'package:flutter/material.dart';

import '../game/class_catalog.dart';
import '../theme/tokens.dart';

/// Player Class detail sheet — matches design v2 (`screens-progress.jsx`
/// `ClassSheet`). A modal bottom sheet that surfaces the player's class
/// art + class buffs + possible evolutions.
///
/// Caller pattern:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   backgroundColor: Colors.transparent,
///   isScrollControlled: true,
///   builder: (_) => PlayerClassSheet(classDef: state.playerClass),
/// );
/// ```
class PlayerClassSheet extends StatelessWidget {
  const PlayerClassSheet({super.key, required this.classDef});

  final ClassDef classDef;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0F2B), Color(0xFF0A0612)],
          ),
          border: Border.all(
            color: AppPalette.amber.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              // Class art.
              Center(child: _ClassArt()),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  classDef.displayName,
                  style: const TextStyle(
                    fontSize: 38,
                    fontFamily: 'BebasNeue',
                    height: 1,
                    color: AppPalette.amber,
                    shadows: [
                      Shadow(
                        color: Color(0x80F5A623),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  classDef.descriptor,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Buffs section.
              const _SectionLabel(text: 'CLASS BUFFS'),
              const SizedBox(height: 10),
              for (var i = 0; i < classDef.buffs.length; i++)
                _BuffRow(
                  icon: classDef.buffs[i].icon,
                  label: classDef.buffs[i].label,
                  hasDivider: i > 0,
                ),
              if (classDef.evolutions.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionLabel(text: 'POSSIBLE EVOLUTIONS'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < classDef.evolutions.length; i++) ...[
                      Expanded(
                        child: _EvolutionCard(
                          name: classDef.evolutions[i].name,
                          requiredLevel:
                              classDef.evolutions[i].requiredLevel,
                        ),
                      ),
                      if (i < classDef.evolutions.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppPalette.textMuted,
      ),
    );
  }
}

class _ClassArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.amber.withValues(alpha: 0.25),
            AppPalette.purple.withValues(alpha: 0.20),
          ],
        ),
        border: Border.all(
          color: AppPalette.amber.withValues(alpha: 0.50),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.amber.withValues(alpha: 0.40),
            blurRadius: 40,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.fitness_center,
              size: 64,
              color: AppPalette.amber,
            ),
          ),
          // Sparkle accents.
          Positioned(
            top: 12,
            left: 14,
            child: _Sparkle(
              color: Colors.white.withValues(alpha: 0.85),
              size: 16,
            ),
          ),
          Positioned(
            bottom: 16,
            right: 18,
            child: _Sparkle(color: AppPalette.amber, size: 12),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: _Sparkle(
              color: Colors.white.withValues(alpha: 0.85),
              size: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      '✦',
      style: TextStyle(fontSize: size, color: color),
    );
  }
}

class _BuffRow extends StatelessWidget {
  const _BuffRow({
    required this.icon,
    required this.label,
    required this.hasDivider,
  });
  final IconData icon;
  final String label;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: hasDivider
            ? Border(
                top: BorderSide(
                  color: AppPalette.purple.withValues(alpha: 0.10),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppPalette.amber.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 14, color: AppPalette.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({required this.name, required this.requiredLevel});
  final String name;
  final int requiredLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppPalette.purple.withValues(alpha: 0.10),
        border: Border.all(
          color: AppPalette.purple.withValues(alpha: 0.30),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              fontFamily: 'BebasNeue',
              color: AppPalette.purpleSoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'LV $requiredLevel required',
            style: const TextStyle(
              fontSize: 9,
              color: AppPalette.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
