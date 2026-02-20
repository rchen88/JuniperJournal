import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juniper_journal/src/features/project/pages/journal_entry_editor.dart';

void main() {
  testWidgets('JournalEntryEditorScreen renders title and actions', (
    WidgetTester tester,
  ) async {
    final initialDoc =
        jsonDecode(jsonEncode(ParchmentDocument())) as List<dynamic>;

    await tester.pumpWidget(
      MaterialApp(
        home: JournalEntryEditorScreen(
          projectId: 'project-1',
          projectName: 'Test Project',
          tags: const ['WATER'],
          entryId: 'entry-1',
          initialTitle: 'Entry 1',
          initialContent: initialDoc,
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Entry 1'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });
}
