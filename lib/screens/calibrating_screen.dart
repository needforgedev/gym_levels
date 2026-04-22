import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/progress_bar.dart';
import '../widgets/screen_base.dart';

class CalibratingScreen extends StatefulWidget {
  const CalibratingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<CalibratingScreen> createState() => _CalibratingScreenState();
}

class _CalibratingScreenState extends State<CalibratingScreen> {
  double _pct = 0;
  final _dots = {'SYS': false, 'NET': false, 'DB': false, 'GPU': false};
  Timer? _progressTimer;
  final List<Timer> _dotTimers = [];
  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;
      setState(() => _pct = (_pct + 3).clamp(0, 100));
    });
    const keys = ['SYS', 'NET', 'DB', 'GPU'];
    for (var i = 0; i < keys.length; i++) {
      _dotTimers.add(
        Timer(Duration(milliseconds: 250 + i * 220), () {
          if (!mounted) return;
          setState(() => _dots[keys[i]] = true);
        }),
      );
    }
    _doneTimer = Timer(const Duration(milliseconds: 1400), widget.onDone);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    for (final t in _dotTimers) {
      t.cancel();
    }
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      background: AppPalette.obsidian,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppPalette.teal),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.teal.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  'ANALYSIS',
                  style: AppType.label(color: AppPalette.teal),
                ),
              ),
              const SizedBox(height: AppSpace.s6),
              Text(
                'CALIBRATING\nSYSTEM',
                textAlign: TextAlign.center,
                style: AppType.displayLG(color: AppPalette.textPrimary),
              ),
              const SizedBox(height: AppSpace.s6),
              SizedBox(
                width: 260,
                child: Column(
                  children: [
                    Bar(percent: _pct, color: AppPalette.teal, height: 4),
                    const SizedBox(height: 10),
                    Text(
                      '${_pct.round()}%',
                      textAlign: TextAlign.center,
                      style: AppType.monoMD(color: AppPalette.teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _dots.entries.map((e) {
                  final on = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: on
                                ? AppPalette.green
                                : AppPalette.textDisabled,
                            shape: BoxShape.circle,
                            boxShadow: on
                                ? [
                                    BoxShadow(
                                      color: AppPalette.green,
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e.key,
                          style: AppType.label(
                            color: on
                                ? AppPalette.green
                                : AppPalette.textMuted,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpace.s4),
              Text(
                '…binding neural interface to player profile.',
                textAlign: TextAlign.center,
                style: AppType.system(color: AppPalette.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
