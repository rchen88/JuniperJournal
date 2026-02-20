import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juniper_journal/src/features/project/pages/project_dashboard.dart';

void main() {
  testWidgets('ProjectDashboard renders main sections and settings gear', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProjectDashboard(
          projectId: 'project-1',
          projectName: 'Test Project',
          tags: ['WATER', 'WASTE'],
        ),
      ),
    );

    expect(find.text('Test Project'), findsOneWidget);
    expect(find.text('Manage Project'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Materials & Cost'), findsOneWidget);
    expect(find.text('Journal Log'), findsOneWidget);
    expect(find.text('Impact'), findsOneWidget);
  });
}
