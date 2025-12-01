import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';
import 'submissions_timeline.dart';

class CreateProblemStatementScreen extends StatefulWidget {
  final String projectName;
  final List<String> tags;

  const CreateProblemStatementScreen({
    super.key,
    required this.projectName,
    required this.tags,
  });

  @override
  State<CreateProblemStatementScreen> createState() =>
      _CreateProblemStatementScreenState();
}

class _CreateProblemStatementScreenState
    extends State<CreateProblemStatementScreen> {
  final TextEditingController _problemController = TextEditingController();

  final List<String> difficultyLevels = [
    "Basic",
    "Intermediate",
    "Advanced",
  ];

  final List<String> subjectDomains = [
    "Environment & Sustainability",
    "Engineering & Design",
    "Energy & Systems",
    "Community & The Built Environment",
  ];

  String? _selectedDifficulty;
  String? _selectedDomain;

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 44,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          size: 18, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text(
                      "Problem Statement",
                      style: TextStyle(
                        color: Color(0xFF1F2024),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.projectName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: widget.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF7E4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            const Text(
              "Write Problem Statement",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _problemController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Describe the challenge your project aims to address...",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              "Subject Domain",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedDomain,
              isExpanded: true,
              decoration: _dropdownDecoration(),
              items: subjectDomains
                  .map(
                    (domain) => DropdownMenuItem<String>(
                      value: domain,
                      child: Text(domain),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDomain = val;
                });
              },
            ),

            const SizedBox(height: 32),

            const Text(
              "Difficulty Level",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              isExpanded: true,
              decoration: _dropdownDecoration(),
              items: difficultyLevels
                  .map(
                    (level) => DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDifficulty = val;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedDomain == null ||
                      _selectedDifficulty == null ||
                      _problemController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please complete all fields.")),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InteractiveTimelinePage(
                        projectName: widget.projectName,
                        tags: widget.tags,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
