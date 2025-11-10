import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';
import 'create_timeline.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';

class CreateProblemStatementScreen extends StatefulWidget {
  final String projectId; 
  final String projectName;
  final List<String> tags;

  const CreateProblemStatementScreen({
    super.key,
    required this.projectId, 
    required this.projectName,
    required this.tags,
  });

  @override
  State<CreateProblemStatementScreen> createState() =>
      _CreateProblemStatementScreenState();
}

class _CreateProblemStatementScreenState
    extends State<CreateProblemStatementScreen> {
  final _problemController = TextEditingController();

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Problem Statement',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show tags dynamically
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                      color: Color(0xFF5DB075),
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Problem statement input
            TextFormField(
              controller: _problemController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your problem statement...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF5DB075)),
                ),
              ),
            ),
            const Spacer(),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final text = _problemController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Please write a problem statement.')));
                    return;
                  }

                  final ok = await ProjectsRepo().updateProblemStatement(
                    id: widget.projectId,
                    problemStatement: text,
                  );

                  if (!ok) {
                    ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Failed to save problem statement.')));
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectTimelineScreen(
                        projectId: widget.projectId,          // keep carrying it forward
                        projectName: widget.projectName,
                        projectDate: "Saturday, May 24",
                        tags: widget.tags,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DB075),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
