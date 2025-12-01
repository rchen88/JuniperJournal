import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juniper_journal/src/styling/app_colors.dart';
import 'package:juniper_journal/src/backend/db/repositories/learning_module_repo.dart';
import 'package:juniper_journal/src/frontend/learning_module/call_to_action.dart';
import 'package:intl/intl.dart';

class Summary extends StatefulWidget {
  final Map<String, dynamic>? existingModule;

  const Summary({super.key, this.existingModule});

  @override
  State<Summary> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<Summary> {
  String _selectedNavigation = 'SUMMARY';
  String _generatedSummary = '';
  Map<String, dynamic>? _moduleData;

  @override
  void initState() {
    super.initState();
    _loadModuleData();
  }

  void _loadModuleData() async {
    final module = widget.existingModule;
    debugPrint('existingModule: $module');

    if (module != null) {
      // Use existing module data as fallback
      setState(() {
        _moduleData = module;
      });

      // Try to fetch fresh data if we have an ID
      if (module['id'] != null) {
        debugPrint('Fetching module with ID: ${module['id']}');
        final repo = LearningModuleRepo();
        final freshModuleData = await repo.getModule(module['id'].toString());

        debugPrint('Fresh module data: $freshModuleData');

        if (freshModuleData != null && mounted) {
          setState(() {
            _moduleData = freshModuleData;
          });
        }
      }
    } else {
      debugPrint('No existing module data provided');
    }
  }

  String _generateSummary() {
    if (_moduleData == null) {
      debugPrint('Module data is null');
      return 'Unable to generate summary - module data not loaded';
    }

    debugPrint('Module data: $_moduleData');

    // Get lesson title
    final lessonTitle = _moduleData!['module_name'] ?? 'Untitled Lesson';

    // Get learning objectives (it's an array, take first or join all)
    final learningObjectivesList = _moduleData!['learning_objectives'];
    String learningObjective = 'explore key concepts';
    if (learningObjectivesList != null && learningObjectivesList is List && learningObjectivesList.isNotEmpty) {
      learningObjective = learningObjectivesList.join(', ');
    }

    // Get anchoring phenomenon (stored as inquiry array)
    final inquiryList = _moduleData!['inquiry'];
    String anchoringPhenomenon = 'a relevant real-world issue';
    if (inquiryList != null && inquiryList is List && inquiryList.isNotEmpty) {
      anchoringPhenomenon = inquiryList.join(' ');
    }

    // Get domains
    final domainsList = _moduleData!['subject_domain'];
    String domains = 'various domains';
    if (domainsList != null && domainsList is List && domainsList.isNotEmpty) {
      domains = domainsList.join(', ');
    }

    // Get performance expectations
    final pesList = _moduleData!['performance_expectation'];
    String performanceExpectations = 'NGSS standards';
    if (pesList != null && pesList is List && pesList.isNotEmpty) {
      performanceExpectations = pesList.join(', ');
    }

    // Get DCIs (Disciplinary Core Ideas)
    final dcisList = _moduleData!['dci'];
    String disciplinaryCoreIdeas = 'fundamental concepts';
    if (dcisList != null && dcisList is List && dcisList.isNotEmpty) {
      disciplinaryCoreIdeas = dcisList.join(', ');
    }

    // Get SEPs (Science and Engineering Practices)
    final sepsList = _moduleData!['sep'];
    String sciencePractices = 'scientific inquiry';
    if (sepsList != null && sepsList is List && sepsList.isNotEmpty) {
      sciencePractices = sepsList.join(', ');
    }

    // Get CCCs (Crosscutting Concepts)
    final cccsList = _moduleData!['ccc'];
    String crosscuttingConcepts = 'interconnected ideas';
    if (cccsList != null && cccsList is List && cccsList.isNotEmpty) {
      crosscuttingConcepts = cccsList.join(', ');
    }

    return 'The "$lessonTitle" learning lesson is designed to $learningObjective within the domain(s) of $domains, directly supporting NGSS Performance Expectations: $performanceExpectations. It emphasizes key disciplinary ideas including $disciplinaryCoreIdeas, engages students in critical Science and Engineering Practices such as $sciencePractices, and explores essential Crosscutting Concepts like $crosscuttingConcepts. By focusing on the anchoring phenomenon "$anchoringPhenomenon", this lesson encourages learners to connect real-world issues with scientific understanding, fostering deeper exploration and practical problem-solving skills.';
  }

  Future<void> _saveSummaryAndNavigate() async {
    if (_generatedSummary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a summary first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final module = widget.existingModule;
    if (module != null && module['id'] != null) {
      final repo = LearningModuleRepo();
      final success = await repo.updateSummary(
        id: module['id'].toString(),
        summary: _generatedSummary,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CallToAction(
              existingModule: module,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save summary'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) {
      return DateFormat('EEEE, MMMM d').format(DateTime.now());
    }

    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      return DateFormat('EEEE, MMMM d').format(dateTime);
    } catch (e) {
      return 'Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetModule = widget.existingModule ?? {};
    final moduleName = widgetModule['module_name'] ?? 'Module Name';
    final formattedDate = _formatDate(widgetModule['created_at']);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.back,
                      color: AppColors.iconPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moduleName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveSummaryAndNavigate,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary navigation
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildNavigationDropdown()
                ],
              ),
              const SizedBox(height: 24),

              // Display generated summary if available
              if (_generatedSummary.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _generatedSummary,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Generate Summary Report button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _generatedSummary = _generateSummary();
                    });
                  },
                  child: const Text('Generate Summary Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationDropdown() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNavigation,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Colors.green,
          ),
          style: const TextStyle(
            color: Colors.green,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          dropdownColor: Colors.green[50],
          items: const [
            DropdownMenuItem(
              value: 'TITLE',
              child: Text(
                'TITLE',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'SUMMARY',
              child: Text(
                'SUMMARY',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            if (value == 'TITLE') {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _selectedNavigation = value;
              });
            }
          },
        ),
      ),
    );
  }

}
