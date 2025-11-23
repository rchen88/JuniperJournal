import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';
import '../../backend/db/repositories/projects_repo.dart';
import 'submissions_timeline.dart';

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
  final _projectsRepo = ProjectsRepo();
  bool _isLoading = false;

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
  padding: const EdgeInsets.all(16),
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
        runSpacing: 8,
        children: widget.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCF7E4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: AppColors.primary,
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

            // Next button - updates problem statement in Supabase
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);

                        final success = await _projectsRepo.updateProblemStatement(
                          id: widget.projectId,
                          problemStatement: _problemController.text.trim(),
                        );

                        if (!mounted) return;
                        setState(() => _isLoading = false);

                        if (success) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InteractiveTimelinePage(
                                projectId: widget.projectId,
                                projectName: widget.projectName,
                                tags: widget.tags,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save problem statement. Please try again.'),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DB075),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
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