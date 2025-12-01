import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:juniper_journal/src/backend/db/repositories/learning_module_repo.dart';
import 'package:juniper_journal/src/frontend/learning_module/learning_objective.dart';
import 'package:juniper_journal/src/styling/app_colors.dart';
import 'package:juniper_journal/src/frontend/learning_module/create_lm_template.dart';
import 'package:juniper_journal/src/frontend/learning_module/anchoring_phenomenon.dart';
import 'package:juniper_journal/src/frontend/learning_module/3d_learning.dart';
import 'package:juniper_journal/src/frontend/learning_module/concept_exploration.dart';
import 'package:juniper_journal/src/frontend/learning_module/activity.dart';
import 'package:juniper_journal/src/frontend/learning_module/assessment.dart';
import 'package:juniper_journal/src/frontend/learning_module/call_to_action.dart';

class Summary extends StatefulWidget {
  final Map<String, dynamic>? module;

  const Summary({super.key, this.module});

  @override
  State<Summary> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<Summary> {
  String _selectedNavigation = 'SUMMARY';
  String _generatedSummary = '';
  Map<String, dynamic>? _moduleData;

  String? _subjectDomain;
  String? _learningObjective;
  String? _dci;
  String? _sep;
  String? _ccc;
  String? _pes;
  String? _anchoringPhenomenon;

  bool _isLoading = true;
  bool _hasGenerated = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  String? _stringFromListOrSingle(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final cleaned = value
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .map((e) => e.toString().trim())
          .toList();
      if (cleaned.isEmpty) return null;
      return cleaned.join(', ');
    }
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  void _loadExistingData() async {
    final module = widget.module;
    if (module == null || module['id'] == null) {
      setState(() => _isLoading = false);
      return;
    }

    final repo = LearningModuleRepo();
    final freshModuleData = await repo.getModule(module['id'].toString());

    if (!mounted) return;

    final merged = {
      ...module,
      if (freshModuleData != null) ...freshModuleData,
    };

    setState(() {
      _moduleData = merged;

      _subjectDomain = _stringFromListOrSingle(
            merged['subject_domain'] ?? merged['domains'],
          ) ??
          'Subject domain(s) not set';

      _learningObjective = _stringFromListOrSingle(
            merged['learning_objective'] ?? merged['learning_objectives'],
          ) ??
          'Learning objective not set';

      _dci = _stringFromListOrSingle(merged['dci'] ?? merged['dcis']) ??
          'DCIs not set';

      _sep = _stringFromListOrSingle(merged['sep'] ?? merged['seps']) ??
          'SEPs not set';

      _ccc = _stringFromListOrSingle(merged['ccc'] ?? merged['cccs']) ??
          'CCCs not set';

      _pes = _stringFromListOrSingle(
            merged['performance_expectation'],
          ) ??
          'NGSS PEs not set';

      _anchoringPhenomenon = _stringFromListOrSingle(
            merged['inquiry'],
          ) ??
          'Anchoring phenomenon not set';

      _isLoading = false;
    });
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

  void _generateSummary() {
    final module = _moduleData ?? widget.module ?? {};
    final lessonTitle =
        (module['module_name'] ?? 'this learning lesson').toString();

    final lo =
        _learningObjective ?? 'support the selected learning objective';
    final domain = _subjectDomain ?? 'the selected subject domain(s)';
    final pes = _pes ?? 'selected NGSS Performance Expectations';
    final dci = _dci ?? 'the key disciplinary core ideas';
    final sep = _sep ?? 'relevant Science and Engineering Practices';
    final ccc = _ccc ?? 'important Crosscutting Concepts';
    final anch = _anchoringPhenomenon ??
        'the core anchoring phenomenon or problem for this lesson';

    final summary = '''
“The “$lessonTitle” learning lesson is designed to $lo within the domain(s) of $domain, directly supporting NGSS Performance Expectations: $pes. It emphasizes key disciplinary ideas including $dci, engages students in critical Science and Engineering Practices such as $sep, and explores essential Crosscutting Concepts like $ccc.

By focusing on the anchoring phenomenon "$anch", this lesson encourages learners to connect real-world issues with scientific understanding, fostering deeper exploration and practical problem-solving skills.”''';

    setState(() {
      _generatedSummary = summary.trim();
      _hasGenerated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final widgetModule = _moduleData ?? widget.module ?? {};
    final moduleName = widgetModule['module_name'] ?? 'Module Name';
    final formattedDate = _formatDate(widgetModule['created_at']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar – matches AnchoringPhenomenon
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.back,
                            color: AppColors.buttonPrimary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Back',
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                moduleName.toString(),
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
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Navigation dropdown styled like AnchoringPhenomenon
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildNavigationDropdown(widgetModule),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Generate button disappears after click
                    if (!_hasGenerated)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: AppColors.buttonText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _generateSummary,
                          child:
                              const Text('Generate Summary Report'),
                        ),
                      ),
                    
                      const SizedBox(height: 10),
                      ...[
                      const Text(
                        'Standards Summary:',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Standards Summary card – accent background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _generatedSummary,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Selected Components',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 10),
                  
                      // Tags side-by-side, using tag colors, answers only
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20), 
                        ),
                        child: Wrap(
                          spacing: 16,  
                          runSpacing: 10,
                          children: [
                            _buildChip(_subjectDomain),
                            _buildChip(_learningObjective),
                            _buildChip(_pes),
                            _buildChip(_dci),
                            _buildChip(_sep),
                            _buildChip(_ccc),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: AppColors.buttonText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CallToAction( existingModule: widgetModule ,),
                              ),
                            );
                          },
                          child: const Text('Complete'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  /// Navigation dropdown – same visual style as AnchoringPhenomenon
  Widget _buildNavigationDropdown(Map<String, dynamic> module) {
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
          size: 20,
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
            value: 'ANCHORING PHENOMENON',
            child: Text(
              'ANCHORING PHENOMENON',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'OBJECTIVE',
            child: Text(
              'OBJECTIVE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'LEARNING',
            child: Text(
              'LEARNING',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'CONCEPT EXPLORATION',
            child: Text(
              'CONCEPT EXPLORATION',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'ACTIVITY',
            child: Text(
              'ACTIVITY',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'ASSESSMENT',
            child: Text(
              'ASSESSMENT',
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

          // Update selected state
          setState(() {
            _selectedNavigation = value;
          });

          if (value == 'TITLE') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreateTemplateScreen(
                  existingModule: module,
                ),
              ),
            );
          } else if (value == 'ANCHORING PHENOMENON') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AnchoringPhenomenon(
                  existingModule: module,
                ),
              ),
            );
          } else if (value == 'OBJECTIVE') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LearningObjectiveScreen(
                  module: module,
                ),
              ),
            );
          } else if (value == 'LEARNING') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ThreeDLearning(
                  module: module,
                ),
              ),
            );
          } else if (value == 'CONCEPT EXPLORATION') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ConceptExplorationScreen(
                  module: module,
                ),
              ),
            );
          } else if (value == 'ACTIVITY') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ActivityScreen(
                  module: module,
                ),
              ),
            );
          } else if (value == 'ASSESSMENT') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Assessment(
                  module: module,
                ),
              ),
            );
          }
          // If SUMMARY is selected, stay on this page
        },
      ),
    ),
  );
}


  /// Tag-style chip with tag colors, showing only the value
  Widget _buildChip(String? value) {
  final content = (value ?? '').trim();
  final textToShow = content.isEmpty ? 'Not set' : content;

  return Container(
    margin: const EdgeInsets.only(right: 4, bottom: 4), 
    padding: const EdgeInsets.symmetric(
      horizontal: 18,  // 🔹 wider pill
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: AppColors.tagBackground,
      borderRadius: BorderRadius.circular(20), 
    ),
    child: Text(
      textToShow,
      style: const TextStyle(
        color: AppColors.tagText,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );


  }
}