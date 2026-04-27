import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ranks_hype_screen.dart';

/// Legacy route — design v2 collapsed the two intro hype slides into a
/// single swipeable screen. We forward into [RanksHypeScreen] so the
/// `/hype/progression` deep-link still works.
class ProgressionHypeScreen extends StatefulWidget {
  const ProgressionHypeScreen({super.key});

  @override
  State<ProgressionHypeScreen> createState() => _ProgressionHypeScreenState();
}

class _ProgressionHypeScreenState extends State<ProgressionHypeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/hype/ranks');
    });
  }

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Color(0xFF0A0612));
}
