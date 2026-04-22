import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_levels/main.dart';

void main() {
  testWidgets('App boots without error', (tester) async {
    await tester.pumpWidget(const LevelUpApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
