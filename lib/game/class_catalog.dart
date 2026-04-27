import 'package:flutter/material.dart';

/// PRD §9A.7 — player class catalog.
///
/// Each class defines its display name, system-voice descriptor, the
/// gameplay buffs the class confers (rendered on the Profile Player Class
/// sheet), and the evolutions it can grow into. Class derivation logic
/// (the matrix that maps onboarding answers → class) lands with the full
/// §9A.7 work; for now this catalog is the single source of truth read by
/// every screen that displays class info.
class ClassDef {
  const ClassDef({
    required this.key,
    required this.displayName,
    required this.descriptor,
    required this.buffs,
    required this.evolutions,
  });

  final String key;
  final String displayName;
  final String descriptor;
  final List<ClassBuff> buffs;
  final List<ClassEvolution> evolutions;
}

class ClassBuff {
  const ClassBuff({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class ClassEvolution {
  const ClassEvolution({required this.name, required this.requiredLevel});
  final String name;
  final int requiredLevel;
}

const String defaultClassKey = 'mass_builder';

/// Canonical catalog. New classes plug in as additional map entries; the
/// derivation matrix in §9A.7 just picks a key.
const Map<String, ClassDef> classCatalog = {
  'mass_builder': ClassDef(
    key: 'mass_builder',
    displayName: 'MASS BUILDER',
    descriptor: 'Building size through volume and dedication.',
    buffs: [
      ClassBuff(icon: Icons.bolt, label: '+15% XP on compound lifts'),
      ClassBuff(
        icon: Icons.gps_fixed,
        label: 'Volume quests 2× more frequent',
      ),
      ClassBuff(
        icon: Icons.star,
        label: 'Unlock exclusive hypertrophy boss challenges',
      ),
    ],
    evolutions: [
      ClassEvolution(name: 'Iron Titan', requiredLevel: 25),
      ClassEvolution(name: 'Colossus', requiredLevel: 25),
    ],
  ),
  'powerhouse': ClassDef(
    key: 'powerhouse',
    displayName: 'POWERHOUSE',
    descriptor: 'Pure strength — heavy weight, low reps, maximum force.',
    buffs: [
      ClassBuff(icon: Icons.bolt, label: '+20% XP on PR sets'),
      ClassBuff(
        icon: Icons.gps_fixed,
        label: 'PR-driven quests appear 2× more often',
      ),
      ClassBuff(
        icon: Icons.shield_outlined,
        label: 'Unlock exclusive max-strength boss challenges',
      ),
    ],
    evolutions: [
      ClassEvolution(name: 'Juggernaut', requiredLevel: 25),
      ClassEvolution(name: 'Warlord', requiredLevel: 25),
    ],
  ),
  'shredder': ClassDef(
    key: 'shredder',
    displayName: 'SHREDDER',
    descriptor: 'Lean, athletic, conditioned — composition over mass.',
    buffs: [
      ClassBuff(icon: Icons.bolt, label: '+15% XP on high-rep sets (12+)'),
      ClassBuff(
        icon: Icons.gps_fixed,
        label: 'Volume + cardio quests 2× more frequent',
      ),
      ClassBuff(
        icon: Icons.local_fire_department_outlined,
        label: 'Unlock exclusive conditioning boss challenges',
      ),
    ],
    evolutions: [
      ClassEvolution(name: 'Phantom', requiredLevel: 25),
      ClassEvolution(name: 'Reaver', requiredLevel: 25),
    ],
  ),
  'all_rounder': ClassDef(
    key: 'all_rounder',
    displayName: 'ALL ROUNDER',
    descriptor: 'Balanced gains across strength, size, and conditioning.',
    buffs: [
      ClassBuff(icon: Icons.bolt, label: '+10% XP on every set'),
      ClassBuff(
        icon: Icons.gps_fixed,
        label: 'Wider quest pool — daily variety',
      ),
      ClassBuff(
        icon: Icons.star,
        label: 'Unlock exclusive hybrid boss challenges',
      ),
    ],
    evolutions: [
      ClassEvolution(name: 'Sentinel', requiredLevel: 25),
      ClassEvolution(name: 'Vanguard', requiredLevel: 25),
    ],
  ),
};

ClassDef classFor(String? key) {
  if (key == null) return classCatalog[defaultClassKey]!;
  return classCatalog[key] ?? classCatalog[defaultClassKey]!;
}
