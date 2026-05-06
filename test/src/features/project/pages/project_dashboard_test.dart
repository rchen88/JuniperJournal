import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juniper_journal/src/backend/db/models/challenge_participant.dart';
import 'package:juniper_journal/src/backend/db/models/design_challenge.dart';
import 'package:juniper_journal/src/backend/db/models/project.dart';
import 'package:juniper_journal/src/backend/db/repositories/challenges_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/features/project/pages/project_dashboard.dart';

class _FakeProjectsRepo extends ProjectsRepo {
  String? updatedImageUrl;

  @override
  Future<Project?> getProjectById(String id) async {
    return Project(
      id: id,
      projectName: 'Test Project',
      tags: const ['WATER', 'WASTE'],
      imageUrl: 'https://example.com/project-cover.jpg',
      problemStatement: 'A river restoration project.',
    );
  }

  @override
  Future<bool> updateProjectImage({
    required String id,
    String? projectImageUrl,
  }) async {
    updatedImageUrl = projectImageUrl;
    return true;
  }
}

class _FakeChallengesRepo extends ChallengesRepo {
  @override
  Future<ChallengeParticipant?> getParticipationByProjectId(
    String projectId,
  ) async {
    return null;
  }

  @override
  Future<DesignChallenge?> getChallengeById(String id) async {
    return null;
  }
}

void main() {
  testWidgets(
    'ProjectDashboard renders main sections and owner cover control',
    (WidgetTester tester) async {
      final projectsRepo = _FakeProjectsRepo();

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDashboard(
            projectId: 'project-1',
            projectName: 'Test Project',
            tags: const ['WATER', 'WASTE'],
            projectsRepo: projectsRepo,
            challengesRepo: _FakeChallengesRepo(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Project'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);

      expect(find.text('Impact Entry'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Materials & Cost'), findsOneWidget);
      expect(find.text('Journal Entry'), findsOneWidget);
    },
  );

  testWidgets('owner can remove the cover image from the dashboard', (
    WidgetTester tester,
  ) async {
    final projectsRepo = _FakeProjectsRepo();

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectDashboard(
          projectId: 'project-1',
          projectName: 'Test Project',
          tags: const ['WATER', 'WASTE'],
          projectsRepo: projectsRepo,
          challengesRepo: _FakeChallengesRepo(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.camera_alt_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Cover Image'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(projectsRepo.updatedImageUrl, isNull);
    expect(find.byIcon(Icons.landscape_outlined), findsOneWidget);
  });

  testWidgets('non-owner cannot change the dashboard cover image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectDashboard(
          projectId: 'project-1',
          projectName: 'Test Project',
          tags: const ['WATER', 'WASTE'],
          isOwner: false,
          projectsRepo: _FakeProjectsRepo(),
          challengesRepo: _FakeChallengesRepo(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });
}
