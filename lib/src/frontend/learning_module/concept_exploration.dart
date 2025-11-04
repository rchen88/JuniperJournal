import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:fleather/fleather.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../styling/app_colors.dart';
import '../../backend/db/repositories/learning_module_repo.dart';
import '../../backend/storage/storage_service.dart';
import '../../widgets/toolbar.dart';
import 'create_lm_template.dart';
import 'anchoring_phenomenon.dart';
import 'learning_objective.dart';
import '3d_learning.dart';

/// ---------------------------------------------------------------------------
/// CLASS: ConceptExploration
///
/// PURPOSE:
/// The `ConceptExploration` model represents an interactive, multimedia-driven
/// learning section designed to build foundational understanding of a concept
/// through engaging and accessible experiences. It helps students connect
/// prior knowledge with new ideas by integrating rich text, visuals, and
/// interactive media elements in one structured model.
///
/// This class supports the creator’s ability to:
/// - Configure 1–5 short written content blocks (with optional visuals/calculations)
/// - Embed videos, animations, or interactive diagrams
/// - Define glossary terms with clickable pop-up definitions
/// - Create quick polls or surveys to gauge prior knowledge
/// - Add note-taking and reflection prompts (e.g., “What surprised you?”)
///
/// It also defines how users interact with the content:
/// - Reading and exploring multimedia concept blocks
/// - Clicking glossary terms for definitions or examples
/// - Responding to embedded polls and surveys
/// - Entering notes and reflections for comprehension tracking
///
/// USAGE OF FLEATHER:
/// This model uses the [Fleather](https://pub.dev/packages/fleather) package
/// to handle creator-written and user-editable rich text content. Fleather
/// provides a Quill-compatible WYSIWYG editor that supports:
/// - Inline text formatting (bold, italics, lists, headings)
/// - Embedded media (images, videos)
/// - Real-time editing and persistence of rich text fields
///
/// Within the `ConceptExploration` workflow, Fleather is typically used for:
/// - Authoring the short content blocks and explanatory text sections
/// - Allowing users to take in-app notes and reflections directly within
///   a rich text editor, maintaining formatting and embedded visuals.
///
/// EXAMPLE:
/// ```dart
/// final concept = ConceptExploration(
///   title: "The Greenhouse Effect",
///   contentBlocks: [
///     FleatherDocument.fromJson(json1),
///     FleatherDocument.fromJson(json2),
///   ],
///   videos: [VideoEmbed(url: "https://example.com/video.mp4")],
///   glossary: {"Infrared Radiation": "A type of heat energy emitted by objects"},
///   poll: QuickPoll(question: "Have you heard of the greenhouse effect before?"),
/// );
/// ```
///
/// ---------------------------------------------------------------------------

class ConceptExplorationScreen extends StatefulWidget {
  final Map<String, dynamic> module;

  const ConceptExplorationScreen({super.key, required this.module});

  @override
  State<ConceptExplorationScreen> createState() => _ConceptExplorationScreenState();
}

class _ConceptExplorationScreenState extends State<ConceptExplorationScreen> {
  Map<String, dynamic>? _freshModuleData;
  final String _currentSection = 'CONCEPT EXPLORATION';

  FleatherController? _controller;
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    // Auto-save before disposing
    _saveDocument();
    _controller?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Loads the document from database if it exists, otherwise creates empty document
  Future<void> _loadDocument() async {
    try {
      if (widget.module['id'] != null) {
        final repo = LearningModuleRepo();
        final freshData = await repo.getModule(widget.module['id'].toString());

        if (freshData != null) {
          _freshModuleData = freshData;

          // Check if concept_exploration data exists
          final conceptExplorationData = freshData['concept_exploration'];

          if (conceptExplorationData != null && conceptExplorationData is String) {
            // Decode JSON string and load document
            final decodedJson = jsonDecode(conceptExplorationData);
            final doc = ParchmentDocument.fromJson(decodedJson);
            setState(() {
              _controller = FleatherController(document: doc);
              _isLoading = false;
            });
          } else {
            // Create empty document
            setState(() {
              _controller = FleatherController();
              _isLoading = false;
            });
          }
        } else {
          // Create empty document if module not found
          setState(() {
            _controller = FleatherController();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading document: $e');
      // Create empty document on error
      setState(() {
        _controller = FleatherController();
        _isLoading = false;
      });
    }
  }

  /// Saves the current document to the database as JSON
  Future<void> _saveDocument() async {
    if (_controller == null || widget.module['id'] == null) return;

    try {
      // Serialize document to JSON string
      // Parchment documents can be easily serialized to JSON by passing to jsonEncode directly
      final documentJson = jsonEncode(_controller!.document);

      // Save to database
      final repo = LearningModuleRepo();
      final success = await repo.updateConceptExploration(
        id: widget.module['id'].toString(),
        conceptExplorationJson: documentJson,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Document saved successfully!' : 'Failed to save document'),
            backgroundColor: success ? AppColors.primary : AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving document'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) return 'Date not available';

    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final formatter = DateFormat('EEEE, MMMM d');
      return formatter.format(dateTime);
    } catch (e) {
      return 'Date error';
    }
  }

  List<String> _getPerformanceExpectations() {
    final moduleData = _freshModuleData ?? widget.module;
    final perfExpectations = moduleData['performance_expectation'];

    if (perfExpectations == null) return [];

    if (perfExpectations is List) {
      return List<String>.from(perfExpectations);
    } else if (perfExpectations is String && perfExpectations.isNotEmpty) {
      if (perfExpectations.startsWith('[') && perfExpectations.endsWith(']')) {
        try {
          final cleanString = perfExpectations.substring(1, perfExpectations.length - 1);
          return cleanString
              .split(',')
              .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
              .where((s) => s.isNotEmpty)
              .toList();
        } catch (e) {
          return [perfExpectations];
        }
      } else {
        return [perfExpectations];
      }
    }

    return [];
  }

  /// Shows a dialog to let the user choose between camera or gallery
  Future<void> _openCamera() async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Add Image'),
        message: const Text('Choose a source for your image'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickAndUploadImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickAndUploadImage(ImageSource.gallery);
            },
            child: const Text('Choose from Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  /// Picks an image from the specified source, uploads it to Supabase, and inserts it into the document
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      // Pick the image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading image...'),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Upload to Supabase Storage
      final imageUrl = await _storageService.uploadImage(
        image,
        folder: 'concept-exploration',
      );

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Insert image into Fleather document
      _insertImageIntoDocument(imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image added successfully!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Inserts an image embed into the Fleather document at the current cursor position
  void _insertImageIntoDocument(String imageUrl) {
    if (_controller == null) return;

    final index = _controller!.selection.extentOffset;

    // Create the image embed using BlockEmbed
    final embed = BlockEmbed.image(imageUrl);

    // Insert the embed into the document
    _controller!.replaceText(index, 0, embed);

    // Add a newline after the image for better UX
    _controller!.replaceText(index + 1, 0, '\n');

    // Move cursor after the image
    _controller!.updateSelection(
      TextSelection.collapsed(offset: index + 2),
    );
  }

  /// Custom embed builder to render images in the Fleather editor
  Widget _embedBuilder(BuildContext context, EmbedNode node) {
    final embed = node.value;

    // Handle image embeds
    if (embed.type == 'image') {
      final imageUrl = embed.data['source'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading image: $error');
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    // Return empty widget for unknown embed types
    return const SizedBox.shrink();
  }

  void _insertMathEquation() {
    if (_controller == null) return;
    // Insert placeholder for math equation
    final index = _controller!.selection.baseOffset;
    _controller!.replaceText(index, 0, '[Math Equation] ');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Math equation feature coming soon!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final moduleName = widget.module['module_name'] ?? 'Module Name';
    final formattedDate = _formatDate(widget.module['created_at']);
    final performanceExpectations = _getPerformanceExpectations();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content with SafeArea
          SafeArea(
            bottom: false, // Don't apply SafeArea to bottom
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.back, color: AppColors.iconPrimary),
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
                      // Save button with options
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.save, color: AppColors.primary),
                        tooltip: 'Save',
                        offset: const Offset(0, 40),
                        onSelected: (value) async {
                          if (value == 'save') {
                            await _saveDocument();
                          } else if (value == 'save_continue') {
                            final messenger = ScaffoldMessenger.of(context);
                            await _saveDocument();
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Moving to next section...'),
                                  backgroundColor: AppColors.primary,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'save',
                            child: Row(
                              children: [
                                Icon(Icons.save_outlined, size: 20, color: AppColors.darkText),
                                SizedBox(width: 12),
                                Text('Save'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'save_continue',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_forward, size: 20, color: AppColors.primary),
                                SizedBox(width: 12),
                                Text('Save & Continue'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                // Navigation and performance expectation tags - Collapsible
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: _isHeaderCollapsed ? 36 : null,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Navigation dropdown
                          _buildNavigationDropdown(),

                          // Only show tags when not collapsed
                          if (!_isHeaderCollapsed) ...[
                            const SizedBox(height: 12),
                            // Performance expectation tags
                            if (performanceExpectations.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: performanceExpectations.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.tagBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.tagBorder, width: 1),
                                    ),
                                    child: Text(
                                      tag,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.tagText,
                                        fontSize: 10,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Fleather rich text editor with loading state
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            if (notification is ScrollUpdateNotification) {
                              // Update scroll position for header collapse
                              final offset = notification.metrics.pixels;
                              final shouldCollapse = offset > 50;

                              if (shouldCollapse != _isHeaderCollapsed) {
                                setState(() {
                                  _isHeaderCollapsed = shouldCollapse;
                                });
                              }
                            }
                            return false;
                          },
                          child: Container(
                            color: AppColors.white,
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                            child: FleatherEditor(
                              controller: _controller!,
                              focusNode: _focusNode,
                              padding: const EdgeInsets.only(bottom: 120), // Extra space to scroll past toolbar
                              autofocus: false,
                              embedBuilder: _embedBuilder,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Floating toolbar at bottom - outside SafeArea
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: ConceptExplorationToolbar(
              onCamera: _openCamera,
              onInsertMath: _insertMathEquation,
            ),
          ),
        ],
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
          value: _currentSection,
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
          ],
          onChanged: (value) {
            if (value == 'TITLE') {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateTemplateScreen(
                    existingModule: widget.module,
                  ),
                ),
              );
            } else if (value == 'ANCHORING PHENOMENON') {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AnchoringPhenomenon(
                    existingModule: widget.module,
                  ),
                ),
              );
            } else if (value == 'OBJECTIVE') {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LearningObjectiveScreen(
                    module: widget.module,
                  ),
                ),
              );
            } else if (value == 'LEARNING') {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ThreeDLearning(
                    module: widget.module,
                  ),
                ),
              );
            }
            // If CONCEPT EXPLORATION is selected, stay on current page
          },
        ),
      ),
    );
  }
}
