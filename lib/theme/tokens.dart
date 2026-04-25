import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Level Up IRL — design tokens
/// Ported from DesignSystem_LevelUpIRL.md and the React prototype.
class AppPalette {
  AppPalette._();

  // Backgrounds
  static const obsidian = Color(0xFF05090C);
  static const voidBg = Color(0xFF0A0612); // page bg per design v2
  static const bgPage = Color(0xFF07050F); // outer page wash (design v2)
  static const carbon = Color(0xFF0C131A);
  static const slate = Color(0xFF111923);
  static const bgCard = Color(0xFF120A1F); // primary card surface (design v2)
  static const bgCard2 = Color(0xFF1A0F2B); // raised card surface (design v2)

  // Accents
  static const teal = Color(0xFF19E3E3);
  static const tealDim = Color(0xFF0F7A7A);
  static const purple = Color(0xFF8B5CF6);
  static const purpleSoft = Color(0xFFA78BFA); // hover / soft text on dark
  static const purpleDeep = Color(0xFF5B21B6); // deep gradient stop
  static const purpleDim = Color(0xFF4C2D99);
  static const yellow = Color(0xFFF5D742);
  static const yellowDim = Color(0xFF8A7614);
  static const green = Color(0xFF22E06B);
  static const greenDim = Color(0xFF126B34);
  static const white = Color(0xFFECE9F5);

  // Signal
  static const xpGold = Color(0xFFF5A623); // == amber in design v2
  static const amber = Color(0xFFF5A623);
  static const amberSoft = Color(0xFFFBBF24);
  static const flame = Color(0xFFFF6B35);
  static const streak = Color(0xFFFF6B35); // alias for clarity
  static const success = Color(0xFF22E06B);
  static const danger = Color(0xFFE04444);

  // Text
  static const textPrimary = Color(0xFFECE9F5); // design v2 text
  static const textSecondary = Color(0xFFA8A0BA);
  static const textMuted = Color(0xFF8A809B); // design v2 muted
  static const textDim = Color(0xFF5A5169); // design v2 dim
  static const textDisabled = Color(0xFF3A4450);

  // Strokes
  static const strokeHairline = Color(0x14E6EEF5); // 0.08 alpha of #E6EEF5
  static const strokeSubtle = Color(0x24E6EEF5); // 0.14 alpha
  // Design-v2 violet borders used on every card.
  static const borderViolet = Color(0x2E8B5CF6); // ~0.18 alpha
  static const borderVioletGlow = Color(0x738B5CF6); // ~0.45 alpha

  // Rank ladder colors
  static const bronzeA = Color(0xFFC47A3D);
  static const bronzeB = Color(0xFF7A3E14);
  static const silverA = Color(0xFFC9D3E0);
  static const silverB = Color(0xFF6A7785);
  static const goldA = Color(0xFFF5D742);
  static const goldB = Color(0xFF8A7614);
  static const platinumA = Color(0xFF19E3E3);
  static const platinumB = Color(0xFF0F7A7A);
  static const diamondA = Color(0xFFA7E8FF);
  static const diamondB = Color(0xFF3FA7D6);
  static const masterA = Color(0xFF8B5CF6);
  static const masterB = Color(0xFF4C2D99);
  static const grandmasterA = Color(0xFFFF6B35);
  static const grandmasterB = Color(0xFFE04444);
}

/// 8-point spacing grid (+ half steps).
class AppSpace {
  AppSpace._();
  static const double s0 = 0;
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 8;
  static const double s4 = 12;
  static const double s5 = 16;
  static const double s6 = 20;
  static const double s7 = 24;
  static const double s8 = 32;
  static const double s9 = 40;
  static const double s10 = 48;
  static const double s11 = 56;
  static const double s12 = 64;
}

class AppRadius {
  AppRadius._();
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

/// Typography (Bebas Neue / Inter / JetBrains Mono).
///
/// Display copy is set in **Bebas Neue** per the design-v2 handoff
/// (`design/v2/index.html` — `.display-font` rule). Bebas Neue is a single
/// weight (regular) condensed display face — `letterSpacing` carries the
/// "weight" feel. Body type is Inter; numeric readouts use JetBrains Mono.
class AppType {
  AppType._();

  /// Display face (Bebas Neue). The font is single-weight; weight params
  /// passed in are honored by GoogleFonts but in practice the rendered
  /// glyph is always the regular cut — letterSpacing + size do the work.
  static TextStyle _bebas({
    required double size,
    required double line,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    bool italic = false,
    Color? color,
  }) {
    return GoogleFonts.bebasNeue(
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
    );
  }


  static TextStyle _inter({
    required double size,
    required double line,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _mono({
    required double size,
    required double line,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      color: color,
    );
  }

  // Display (Bebas Neue — condensed all-caps display face per design v2)
  static TextStyle displayXL({Color? color}) => _bebas(
        size: 40,
        line: 44,
        letterSpacing: 1.6, // ~0.04em at 40px
        color: color,
      );
  static TextStyle displayLG({Color? color}) => _bebas(
        size: 32,
        line: 36,
        letterSpacing: 1.3,
        color: color,
      );
  static TextStyle displayMD({Color? color}) => _bebas(
        size: 24,
        line: 28,
        letterSpacing: 1.0,
        color: color,
      );
  static TextStyle displaySM({Color? color}) => _bebas(
        size: 18,
        line: 22,
        letterSpacing: 1.5,
        color: color,
      );

  // Body (Inter)
  static TextStyle bodyLG({Color? color}) =>
      _inter(size: 17, line: 24, weight: FontWeight.w500, color: color);
  static TextStyle bodyMD({Color? color}) =>
      _inter(size: 15, line: 22, weight: FontWeight.w400, color: color);
  static TextStyle bodySM({Color? color}) =>
      _inter(size: 13, line: 18, weight: FontWeight.w400, color: color);
  static TextStyle label({Color? color}) => _inter(
        size: 12,
        line: 16,
        weight: FontWeight.w600,
        letterSpacing: 0.8,
        color: color,
      );

  // Mono (numeric readouts)
  static TextStyle monoXL({Color? color}) =>
      _mono(size: 48, line: 52, weight: FontWeight.w500, color: color);
  static TextStyle monoLG({Color? color}) =>
      _mono(size: 24, line: 28, weight: FontWeight.w500, color: color);
  static TextStyle monoMD({Color? color}) =>
      _mono(size: 15, line: 20, weight: FontWeight.w500, color: color);

  // Italic "System voice" subtitle — used for the in-fiction
  // `[System] …` rationale lines per the design v2 chat transcript.
  static TextStyle system({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        height: 18 / 12,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: color,
      );
}

/// Glow colors used by [NeonCard], pills, and buttons.
enum GlowColor { teal, purple, yellow, green, xp, flame, none }

class AppGlow {
  AppGlow._();

  static Color border(GlowColor g) {
    switch (g) {
      case GlowColor.teal:
        return AppPalette.teal;
      case GlowColor.purple:
        return AppPalette.purple;
      case GlowColor.yellow:
        return AppPalette.yellow;
      case GlowColor.green:
        return AppPalette.green;
      case GlowColor.xp:
        return AppPalette.xpGold;
      case GlowColor.flame:
        return AppPalette.flame;
      case GlowColor.none:
        return AppPalette.strokeSubtle;
    }
  }

  /// Returns a list of [BoxShadow] mimicking the `0 0 Npx rgba(c, a)` pattern.
  /// [intensity] in [0, 1.6]. [alpha] baseline 0.0–0.9. [blur] base in px.
  static List<BoxShadow> shadow(
    GlowColor g, {
    double intensity = 1,
    double alpha = 0.45,
    double blur = 16,
  }) {
    if (g == GlowColor.none) return const [];
    final color = border(g);
    final a = (alpha * intensity).clamp(0.0, 0.9);
    final b = (blur * (0.6 + intensity * 0.6)).clamp(2.0, 64.0);
    return [
      BoxShadow(
        color: color.withValues(alpha: a),
        blurRadius: b,
        spreadRadius: 0,
      ),
    ];
  }
}

/// Uppercase utility — display type is rendered uppercase in the design system.
extension UpperText on String {
  String get up => toUpperCase();
}
