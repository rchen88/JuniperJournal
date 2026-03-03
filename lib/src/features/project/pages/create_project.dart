import 'package:flutter/material.dart';
import 'package:juniper_journal/src/features/project/project.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import 'package:juniper_journal/src/shared/widgets/widgets.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  
  // TODO: should eventually come from constant file/allow for new tags
  final List<String> _availableTags = [
    'EDUCATIONAL IMPACT',
    'WATER',
    'WASTE',
    'CARBON EMISSIONS',
  ];
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          // TODO: are you sure you want to exit?
          icon: const Icon(Icons.close, color: AppColors.border),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Project',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.6)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('Project Name', fontSize: 18),
              const SizedBox(height: 10),
              _buildNameInput(),
              
              const SizedBox(height: 40),
              _buildSectionLabel('Tags', fontSize: 14),
              const SizedBox(height: 16),
              _buildTagSelector(),
              
              const SizedBox(height: 60),
              
              SubmitButton(
                label: 'Continue',
                isLoading: false,
                backgroundColor: const Color(0xFF5DB075),
                onPressed: _handleCreateProject,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI Helpers 

  Widget _buildSectionLabel(String text, {required double fontSize}) {
    return Text(text,
      style: TextStyle(color: Colors.black, fontSize: fontSize, fontWeight: FontWeight.w500));
  }

  Widget _buildNameInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF5DB075), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _projectNameController,
        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w400),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.only(top: 8, bottom: 4),
          errorStyle: TextStyle(color: Colors.red, fontSize: 12, height: 1.2),
        ),
        validator: (value) => (value == null || value.trim().isEmpty) 
            ? 'Project name must be completed' : null,
      ),
    );
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _availableTags.map((tag) {
        final bool isSelected = _selectedTags.contains(tag);
        return GestureDetector(
          onTap: () => setState(() {
            isSelected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD2E2DA),
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: const Color(0xFF5DB075), width: 1) : null,
            ),
            child: Text(tag,
              style: const TextStyle(color: Color(0xFF5DB075), fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  // Logic Helper

  // TODO: require tags?
  void _handleCreateProject() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DefineProblemStatementScreen(
          projectName: _projectNameController.text.trim(),
          tags: List<String>.from(_selectedTags),
          isNewProject: true,
        ),
      ),
    );
  }
}