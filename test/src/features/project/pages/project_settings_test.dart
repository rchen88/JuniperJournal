import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juniper_journal/src/backend/db/models/project.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/features/project/pages/project_settings.dart';

class _FakeProjectsRepo extends ProjectsRepo {
  @override
  Future<Project?> getProjectById(String id) async {
    return Project(
      id: id,
      projectName: 'River Cleanup',
      tags: ['WATER', 'WASTE'],
      problemStatement: 'Too much runoff pollution.',
    );
  }

  @override
  Future<bool> updateProjectMetadata({
    required String id,
    required String projectName,
    required String problemStatement,
    required List<String> tags,
    String? projectImageUrl,
  }) async {
    return true;
  }
}

void main() {
  testWidgets('ProjectSettingsScreen loads and shows existing metadata', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectSettingsScreen(
          projectId: 'project-1',
          projectsRepo: _FakeProjectsRepo(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Project Settings'), findsOneWidget);
    expect(find.text('River Cleanup'), findsOneWidget);
    expect(find.text('Too much runoff pollution.'), findsOneWidget);
    expect(find.text('WATER'), findsOneWidget);
    expect(find.text('WASTE'), findsOneWidget);
    expect(find.text('Save Settings'), findsOneWidget);
  });
}
