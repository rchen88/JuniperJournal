import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';

/// Repository class responsible for handling all database interactions
/// related to the `learning_module` table in Supabase.
///
/// This class provides an abstraction layer between the Flutter UI
/// and the Supabase backend, ensuring that database operations are
/// centralized, reusable, and isolated from presentation logic.
///
/// **Responsibilities:**
/// - Inserts new learning module records into the database.
/// - (Future) Can be extended to support reading, updating, and deleting modules.
/// - Converts UI-level data into structured Supabase API calls.
///
class LearningModuleRepo {
  static const table = 'learning_module';
  final _client = SupabaseDatabase.instance.client;

  Future<Map<String, dynamic>?> createModule({
    required String moduleName,
    required String difficulty,
    required int ecoPoints,
  }) async {
    try {
      final response = await _client
          .from(table)
          .insert({
            'module_name': moduleName,
            'difficulty': difficulty,
            'eco_points': ecoPoints,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateModule({
    required String id,
    required String moduleName,
    required String difficulty,
    required int ecoPoints,
  }) async {
    try {
      // First check if the record exists
      final existingRecord = await _client
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (existingRecord == null) {
        debugPrint('No record found with id: $id');
        return false;
      }

      // Try the update without select first
      await _client
          .from(table)
          .update({
            'module_name': moduleName,
            'difficulty': difficulty,
            'eco_points': ecoPoints,
          })
          .eq('id', id);

      // Then verify the update worked by fetching the record again
      final updatedRecord = await _client
          .from(table)
          .select()
          .eq('id', id)
          .single();

      debugPrint('Updated record: $updatedRecord');

      // Check if the values were actually updated
      final isUpdated = updatedRecord['module_name'] == moduleName &&
                       updatedRecord['difficulty'] == difficulty &&
                       updatedRecord['eco_points'] == ecoPoints;

      debugPrint('Update successful: $isUpdated');
      return isUpdated;
    } catch (e) {
      debugPrint('Error updating module: $e');
      return false;
    }
  }

  Future<bool> updateLearningObjectives({
    required String id,
    required List<String> learningObjectives,
  }) async {
    try {
      debugPrint('Updating learning objectives for module id: $id');
      debugPrint('Learning objectives: $learningObjectives');

      // Filter out null/empty values
      final filteredObjectives = learningObjectives.where((obj) => obj.isNotEmpty).toList();

      await _client
          .from(table)
          .update({
            'learning_objectives': filteredObjectives,
          })
          .eq('id', id);

      debugPrint('Learning objectives updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating learning objectives: $e');
      return false;
    }
  }

  Future<bool> updateSubjectDomains({
    required String id,
    required List<String> subjectDomains,
  }) async {
    try {
      debugPrint('Updating subject domains for module id: $id');
      debugPrint('Subject domains: $subjectDomains');

      // Filter out null/empty values
      final filteredDomains = subjectDomains.where((domain) => domain.isNotEmpty).toList();

      await _client
          .from(table)
          .update({
            'subject_domain': filteredDomains,
          })
          .eq('id', id);

      debugPrint('Subject domains updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating subject domains: $e');
      return false;
    }
  }

  Future<bool> updateAnchoringPhenomenon({
    required String id,
    required String creatorAction,
    required List<String> inquiry,
  }) async {
    try {
      debugPrint('Updating anchoring phenomenon for module id: $id');
      debugPrint('Creator action: $creatorAction');
      debugPrint('Inquiry: $inquiry');

      // Filter out empty strings
      final filteredInquiry = inquiry.where((text) => text.isNotEmpty).toList();

      await _client
          .from(table)
          .update({
            'creator_action': creatorAction,
            'inquiry': filteredInquiry,
          })
          .eq('id', id);

      debugPrint('Anchoring phenomenon updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating anchoring phenomenon: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getModule(String id) async {
    try {
      debugPrint('Fetching module with id: $id');

      final response = await _client
          .from(table)
          .select()
          .eq('id', id)
          .single();

      debugPrint('Fetched module: $response');
      return response;
    } catch (e) {
      debugPrint('Error fetching module: $e');
      return null;
    }
  }

  Future<bool> updatePerformanceExpectations({
    required String id,
    required List<String> performanceExpectations,
  }) async {
    try {
      debugPrint('Updating performance expectations for module id: $id');
      debugPrint('Performance expectations: $performanceExpectations');

      // Filter out empty strings
      final filteredExpectations = performanceExpectations.where((exp) => exp.isNotEmpty).toList();

      await _client
          .from(table)
          .update({
            'performance_expectation': filteredExpectations,
          })
          .eq('id', id);

      debugPrint('Performance expectations updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating performance expectations: $e');
      return false;
    }
  }

  Future<bool> updateDCI({
    required String id,
    required List<String> dci,
  }) async {
    try {
      // Filter out empty strings
      final filteredDCI = dci.where((item) => item.isNotEmpty).toList();

      await _client
          .from(table)
          .update({
            'dci': filteredDCI,
          })
          .eq('id', id);

      debugPrint('DCI updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating DCI: $e');
      return false;
    }
  }

  Future<bool> updateSEP({
    required String id,
    required List<String> sep,
  }) async {
    try {
      // Filter out empty strings
      final filteredSEP = sep.where((item) => item.isNotEmpty).toList();

      await _client
          .from(table)
          .update({
            'sep': filteredSEP,
          })
          .eq('id', id);

      debugPrint('SEP updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating SEP: $e');
      return false;
    }
  }

  Future<bool> updateCCC({
    required String id,
    required List<String> ccc,
  }) async {
    try {
      // Filter out empty strings
      final filteredCCC = ccc.where((item) => item.isNotEmpty).toList();

      await _client
          .from(table)
          .update({
            'ccc': filteredCCC,
          })
          .eq('id', id);

      debugPrint('CCC updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating CCC: $e');
      return false;
    }
  }

  Future<bool> updateConceptExploration({
    required String id,
    required String conceptExplorationJson,
  }) async {
    try {
      debugPrint('Updating concept exploration for module id: $id');

      await _client
          .from(table)
          .update({
            'concept_exploration': conceptExplorationJson,
          })
          .eq('id', id);

      debugPrint('Concept exploration updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating concept exploration: $e');
      return false;
    }
  }

  Future<bool> updateActivity({
    required String id,
    required String activityJson,
  }) async {
    try {
      debugPrint('Updating activity for module id: $id');

      await _client
          .from(table)
          .update({
            'activity': activityJson,
          })
          .eq('id', id);

      debugPrint('Activity updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating activity: $e');
      return false;
    }
  }

  Future<bool> updateAssessment({
    required String id,
    required Map<String, dynamic> assessmentData,
  }) async {
    try {
      debugPrint('Updating assessment for module id: $id');

      await _client
          .from(table)
          .update({
            'assessment': assessmentData,
          })
          .eq('id', id);

      debugPrint('Assessment updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating assessment: $e');
      return false;
    }
  }


Future<bool> updateCallToAction({
  required String id,
  required List<String> callToAction,
  String? projectUrl,
}) async {
  debugPrint('Updating call to action for module id: $id');
  debugPrint('Call to action: $callToAction');
  debugPrint('Project URL: $projectUrl');

  // Filter out empty strings
  final filteredCTA =
      callToAction.where((text) => text.trim().isNotEmpty).toList();

  // This assumes `call_to_action` is type text[] in Supabase
  final response = await _client
      .from(table)
      .update({
        'call_to_action': filteredCTA,
        'project_url': projectUrl,
      })
      .eq('id', id);

  debugPrint('Supabase response for call_to_action: $response');

  // If no exception was thrown, consider it success for now
  return true;
}

}