import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AssessmentType {
  numeric(
    storageValue: 'numeric',
    title: 'Numeric Response',
    selectorTitle: 'Numeric Response',
    description: 'Collect a number or measurement from students.',
    iconAsset: 'assets/learning_module/assessment_numeric.svg',
  ),
  matching(
    storageValue: 'matching',
    title: 'Matching',
    selectorTitle: 'Matching',
    description: 'Match related terms, concepts, or images together.',
    iconAsset: 'assets/learning_module/assessment_matching_multi.svg',
  ),
  trueFalse(
    storageValue: 'true_false',
    title: 'True/False',
    selectorTitle: 'True/False',
    description: 'Choose whether a statement is true or false.',
    iconAsset: 'assets/learning_module/assessment_true_false1.svg',
  ),
  paragraph(
    storageValue: 'paragraph',
    title: 'Paragraph',
    selectorTitle: 'Paragraph',
    description: 'Write a detailed explanation or reflection.',
    iconAsset: 'assets/learning_module/assessment_paragraph.svg',
  ),
  multipleChoice(
    storageValue: 'multiple_choice',
    title: 'Multiple Choice',
    selectorTitle: 'Multiple Choice',
    description: 'Select the best answer from multiple options.',
    iconAsset: 'assets/learning_module/assessment_matching_multi.svg',
  );

  final String storageValue;
  final String title;
  final String selectorTitle;
  final String description;
  final String iconAsset;

  const AssessmentType({
    required this.storageValue,
    required this.title,
    required this.selectorTitle,
    required this.description,
    required this.iconAsset,
  });

  static AssessmentType? fromStorage(String? value) {
    for (final type in values) {
      if (type.storageValue == value || type.title == value) return type;
    }
    return null;
  }
}

class AssessmentBlockData {
  final AssessmentType? type;
  final Map<String, dynamic> data;

  const AssessmentBlockData({this.type, this.data = const {}});

  bool get isEmpty => type == null && data.isEmpty;

  bool get hasDraft {
    if (type == null) return false;
    return _hasMeaningfulValue(data);
  }

  bool get isValid {
    final selectedType = type;
    if (selectedType == null) return true;
    switch (selectedType) {
      case AssessmentType.numeric:
        final answer = num.tryParse(_string('correct_answer'));
        final minimum = num.tryParse(_string('min_value'));
        final maximum = num.tryParse(_string('max_value'));
        return _string('question').isNotEmpty &&
            answer != null &&
            minimum != null &&
            maximum != null &&
            minimum <= maximum &&
            answer >= minimum &&
            answer <= maximum;
      case AssessmentType.matching:
        final top = _stringList('top_items');
        final bottom = _stringList('bottom_items');
        return top.length >= 2 &&
            top.length == bottom.length &&
            top.every((item) => item.trim().isNotEmpty) &&
            bottom.every((item) => item.trim().isNotEmpty);
      case AssessmentType.trueFalse:
        final questions = _maps('questions');
        return questions.length >= 2 &&
            questions.every(
              (question) =>
                  (question['text'] ?? '').toString().trim().isNotEmpty &&
                  question['correct_answer'] is bool,
            );
      case AssessmentType.paragraph:
        return _string('question').isNotEmpty &&
            ['short', 'medium', 'long'].contains(_string('response_length'));
      case AssessmentType.multipleChoice:
        final options = _options;
        final correctIndex = data['correct_index'];
        return _string('question').isNotEmpty &&
            options.length >= 2 &&
            options.every((option) => option.trim().isNotEmpty) &&
            correctIndex is int &&
            correctIndex >= 0 &&
            correctIndex < options.length;
    }
  }

  Map<String, dynamic> toJson() {
    final selectedType = type;
    if (selectedType == null) return <String, dynamic>{};
    return {
      'type': selectedType.storageValue,
      'data': data,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  bool contentEquals(AssessmentBlockData other) {
    return type == other.type && _canonical(data) == _canonical(other.data);
  }

  factory AssessmentBlockData.fromJson(dynamic raw) {
    if (raw is! Map || raw.isEmpty) return const AssessmentBlockData();
    final json = Map<String, dynamic>.from(raw);
    final type = AssessmentType.fromStorage(json['type']?.toString());
    final rawData = json['data'];
    return AssessmentBlockData(
      type: type,
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : {},
    );
  }

  String _string(String key) => data[key]?.toString().trim() ?? '';

  List<Map<String, dynamic>> _maps(String key) {
    final raw = data[key];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  List<String> _stringList(String key) {
    final raw = data[key];
    if (raw is! List) return const [];
    return [for (final item in raw) item.toString()];
  }

  List<String> get _options {
    final raw = data['options'];
    if (raw is! List) return const [];
    return [for (final item in raw) item.toString()];
  }

  static bool _hasMeaningfulValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is bool || value is num) return true;
    if (value is List) return value.any(_hasMeaningfulValue);
    if (value is Map) return value.values.any(_hasMeaningfulValue);
    return true;
  }

  static String _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '$key:${_canonical(value[key])}').join(',')}}';
    }
    if (value is List) return '[${value.map(_canonical).join(',')}]';
    return value?.toString() ?? '';
  }
}

class AssessmentBlockSection extends StatefulWidget {
  final AssessmentBlockData value;
  final ValueChanged<AssessmentBlockData> onChanged;
  final bool showValidation;

  const AssessmentBlockSection({
    super.key,
    required this.value,
    required this.onChanged,
    this.showValidation = false,
  });

  @override
  State<AssessmentBlockSection> createState() => _AssessmentBlockSectionState();
}

class _AssessmentBlockSectionState extends State<AssessmentBlockSection> {
  static const _green = Color(0xFF5DB075);
  static const _text = Color(0xFF141414);
  static const _muted = Color(0xFFCECECE);
  static const _error = Color(0xFFD12E2E);
  static const _purpleTile = Color(0x339027BD);

  AssessmentType? _type;
  late TextEditingController _questionController;
  late TextEditingController _numericAnswerController;
  late TextEditingController _numericMinController;
  late TextEditingController _numericMaxController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _matchingTopControllers;
  late List<TextEditingController> _matchingBottomControllers;
  late List<int> _matchingBottomOrder;
  late List<TextEditingController> _trueFalseQuestionControllers;
  late List<bool?> _trueFalseAnswers;
  late List<TextEditingController> _optionControllers;
  String _paragraphLength = 'short';
  int? _correctOptionIndex;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.value);
  }

  @override
  void didUpdateWidget(covariant AssessmentBlockSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.value.contentEquals(_buildData())) {
      _disposeDynamicControllers();
      _hydrate(widget.value);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _numericAnswerController.dispose();
    _numericMinController.dispose();
    _numericMaxController.dispose();
    _explanationController.dispose();
    _disposeDynamicControllers();
    super.dispose();
  }

  void _hydrate(AssessmentBlockData value) {
    _type = value.type;
    final data = value.data;
    _questionController = TextEditingController(
      text: data['question']?.toString() ?? '',
    )..addListener(_emit);
    _numericAnswerController = TextEditingController(
      text: data['correct_answer']?.toString() ?? '',
    )..addListener(_emit);
    _numericMinController = TextEditingController(
      text: data['min_value']?.toString() ?? '',
    )..addListener(_emit);
    _numericMaxController = TextEditingController(
      text: data['max_value']?.toString() ?? '',
    )..addListener(_emit);
    _explanationController = TextEditingController(
      text: data['explanation']?.toString() ?? '',
    )..addListener(_emit);
    _paragraphLength =
        [
          'short',
          'medium',
          'long',
        ].contains(data['response_length']?.toString())
        ? data['response_length'].toString()
        : 'short';
    final oldPairs = data['pairs'] is List ? data['pairs'] as List : const [];
    final topItems = data['top_items'] is List
        ? List<String>.from(data['top_items'])
        : [
            for (final pair in oldPairs)
              if (pair is Map) '${pair['left'] ?? ''}',
          ];
    final bottomItems = data['bottom_items'] is List
        ? List<String>.from(data['bottom_items'])
        : [
            for (final pair in oldPairs)
              if (pair is Map) '${pair['right'] ?? ''}',
          ];
    while (topItems.length < 2) {
      topItems.add('');
    }
    while (bottomItems.length < topItems.length) {
      bottomItems.add('');
    }
    _matchingTopControllers = [
      for (final item in topItems)
        TextEditingController(text: item)..addListener(_emit),
    ];
    _matchingBottomControllers = [
      for (final item in bottomItems.take(topItems.length))
        TextEditingController(text: item)..addListener(_emit),
    ];
    _matchingBottomOrder = [
      for (var index = 0; index < _matchingTopControllers.length; index++)
        index,
    ];
    final rawQuestions = data['questions'] is List
        ? data['questions'] as List
        : const [];
    final normalizedQuestions = rawQuestions.isNotEmpty
        ? rawQuestions
        : [
            {
              'text': data['question']?.toString() ?? '',
              'correct_answer': data['correct_answer'],
            },
            {'text': '', 'correct_answer': null},
          ];
    _trueFalseQuestionControllers = [
      for (final item in normalizedQuestions)
        TextEditingController(
          text: item is Map ? item['text']?.toString() ?? '' : '',
        )..addListener(_emit),
    ];
    _trueFalseAnswers = [
      for (final item in normalizedQuestions)
        item is Map && item['correct_answer'] is bool
            ? item['correct_answer'] as bool
            : null,
    ];
    final options = data['options'] is List
        ? data['options'] as List
        : const [];
    final normalizedOptions = options.isEmpty ? const ['', ''] : options;
    _optionControllers = [
      for (final option in normalizedOptions)
        TextEditingController(text: option.toString())..addListener(_emit),
    ];
    _correctOptionIndex = data['correct_index'] is int
        ? data['correct_index'] as int
        : null;
  }

  void _disposeDynamicControllers() {
    for (final controller in _matchingTopControllers) {
      controller.dispose();
    }
    for (final controller in _matchingBottomControllers) {
      controller.dispose();
    }
    for (final controller in _trueFalseQuestionControllers) {
      controller.dispose();
    }
    for (final controller in _optionControllers) {
      controller.dispose();
    }
  }

  Future<void> _selectType(AssessmentType type) async {
    if (_type == type) return;
    final current = _buildData();
    if (current.hasDraft) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change assessment type?'),
          content: const Text(
            'Changing the assessment type will clear the current assessment inputs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Change'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {
      _type = type;
      _questionController.clear();
      _numericAnswerController.clear();
      _numericMinController.clear();
      _numericMaxController.clear();
      _explanationController.clear();
      _paragraphLength = 'short';
      _correctOptionIndex = null;
      for (final controller in _matchingTopControllers) {
        controller.dispose();
      }
      for (final controller in _matchingBottomControllers) {
        controller.dispose();
      }
      for (final controller in _trueFalseQuestionControllers) {
        controller.dispose();
      }
      for (final controller in _optionControllers) {
        controller.dispose();
      }
      _matchingTopControllers = List.generate(
        2,
        (_) => TextEditingController()..addListener(_emit),
      );
      _matchingBottomControllers = List.generate(
        2,
        (_) => TextEditingController()..addListener(_emit),
      );
      _matchingBottomOrder = [0, 1];
      _trueFalseQuestionControllers = List.generate(
        2,
        (_) => TextEditingController()..addListener(_emit),
      );
      _trueFalseAnswers = [null, null];
      _optionControllers = [
        TextEditingController()..addListener(_emit),
        TextEditingController()..addListener(_emit),
      ];
    });
    _emit();
  }

  Future<void> _openAssessmentSelector() async {
    final selected = await showModalBottomSheet<AssessmentType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) => const _AssessmentSelectorSheet(),
    );
    if (selected != null) {
      await _selectType(selected);
    }
  }

  AssessmentBlockData _buildData() {
    final selectedType = _type;
    if (selectedType == null) return const AssessmentBlockData();
    final data = switch (selectedType) {
      AssessmentType.numeric => {
        'question': _questionController.text.trim(),
        'correct_answer': _numericAnswerController.text.trim(),
        'min_value': _numericMinController.text.trim(),
        'max_value': _numericMaxController.text.trim(),
        'explanation': _explanationController.text.trim(),
      },
      AssessmentType.matching => {
        'top_items': [
          for (final item in _matchingTopControllers) item.text.trim(),
        ],
        'bottom_items': [
          for (final item in _matchingBottomControllers) item.text.trim(),
        ],
        'correct_mapping': {
          for (var index = 0; index < _matchingTopControllers.length; index++)
            String.fromCharCode(65 + index): String.fromCharCode(65 + index),
        },
      },
      AssessmentType.trueFalse => {
        'questions': [
          for (
            var index = 0;
            index < _trueFalseQuestionControllers.length;
            index++
          )
            {
              'text': _trueFalseQuestionControllers[index].text.trim(),
              'correct_answer': _trueFalseAnswers[index],
            },
        ],
      },
      AssessmentType.paragraph => {
        'question': _questionController.text.trim(),
        'response_length': _paragraphLength,
        'max_characters': _paragraphLimit(_paragraphLength),
      },
      AssessmentType.multipleChoice => {
        'question': _questionController.text.trim(),
        'options': [
          for (final controller in _optionControllers) controller.text.trim(),
        ],
        'correct_index': _correctOptionIndex,
        'explanation': _explanationController.text.trim(),
      },
    };
    return AssessmentBlockData(type: selectedType, data: data);
  }

  void _emit() {
    if (!mounted) return;
    widget.onChanged(_buildData());
  }

  void _addTrueFalseQuestion() {
    setState(() {
      _trueFalseQuestionControllers.add(
        TextEditingController()..addListener(_emit),
      );
      _trueFalseAnswers.add(null);
    });
    _emit();
  }

  void _removeTrueFalseQuestion(int index) {
    if (_trueFalseQuestionControllers.length <= 2) return;
    setState(() {
      _trueFalseQuestionControllers.removeAt(index).dispose();
      _trueFalseAnswers.removeAt(index);
    });
    _emit();
  }

  void _addOption() {
    if (_optionControllers.length >= 4) return;
    setState(() {
      _optionControllers.add(TextEditingController()..addListener(_emit));
    });
    _emit();
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(index).dispose();
      if (_correctOptionIndex == index) {
        _correctOptionIndex = null;
      } else if (_correctOptionIndex != null && _correctOptionIndex! > index) {
        _correctOptionIndex = _correctOptionIndex! - 1;
      }
    });
    _emit();
  }

  void _addMatchingRow() {
    setState(() {
      final index = _matchingTopControllers.length;
      _matchingTopControllers.add(TextEditingController()..addListener(_emit));
      _matchingBottomControllers.add(
        TextEditingController()..addListener(_emit),
      );
      _matchingBottomOrder.add(index);
    });
    _emit();
  }

  void _removeMatchingRow(int index) {
    if (_matchingTopControllers.length <= 2) return;
    setState(() {
      _matchingTopControllers.removeAt(index).dispose();
      _matchingBottomControllers.removeAt(index).dispose();
      _matchingBottomOrder = [
        for (var next = 0; next < _matchingTopControllers.length; next++) next,
      ];
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _buildData();
    final showError = widget.showValidation && !currentData.isValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openAssessmentSelector,
          child: _AssessmentSelectorShell(type: _type, showError: showError),
        ),
        if (_type != null) ...[
          const SizedBox(height: 16),
          _AssessmentFormCard(
            showError: showError,
            child: switch (_type!) {
              AssessmentType.numeric => _NumericForm(
                questionController: _questionController,
                answerController: _numericAnswerController,
                minController: _numericMinController,
                maxController: _numericMaxController,
                explanationController: _explanationController,
                showError: showError,
              ),
              AssessmentType.matching => _MatchingForm(
                topControllers: _matchingTopControllers,
                bottomControllers: _matchingBottomControllers,
                bottomOrder: _matchingBottomOrder,
                showError: showError,
                onAddRow: _addMatchingRow,
                onRemoveRow: _removeMatchingRow,
              ),
              AssessmentType.trueFalse => _TrueFalseForm(
                questionControllers: _trueFalseQuestionControllers,
                selectedAnswers: _trueFalseAnswers,
                showError: showError,
                onAddQuestion: _addTrueFalseQuestion,
                onRemoveQuestion: _removeTrueFalseQuestion,
                onAnswerChanged: (index, value) {
                  setState(() => _trueFalseAnswers[index] = value);
                  _emit();
                },
              ),
              AssessmentType.paragraph => _ParagraphForm(
                questionController: _questionController,
                responseLength: _paragraphLength,
                showError: showError,
                onLengthChanged: (value) {
                  final limit = _paragraphLimit(value);
                  setState(() {
                    _paragraphLength = value;
                    if (_questionController.text.length > limit) {
                      _questionController.text = _questionController.text
                          .substring(0, limit);
                      _questionController.selection = TextSelection.collapsed(
                        offset: limit,
                      );
                    }
                  });
                  _emit();
                },
              ),
              AssessmentType.multipleChoice => _MultipleChoiceForm(
                questionController: _questionController,
                optionControllers: _optionControllers,
                explanationController: _explanationController,
                correctIndex: _correctOptionIndex,
                showError: showError,
                onAddOption: _addOption,
                onRemoveOption: _removeOption,
                onCorrectChanged: (index) {
                  setState(() => _correctOptionIndex = index);
                  _emit();
                },
              ),
            },
          ),
          if (showError) ...[
            const SizedBox(height: 8),
            const Text(
              'Complete the selected assessment before saving this block.',
              style: TextStyle(
                color: _error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ],
    );
  }

  static int _paragraphLimit(String length) => switch (length) {
    'medium' => 300,
    'long' => 450,
    _ => 150,
  };
}

class _AssessmentSelectorSheet extends StatelessWidget {
  const _AssessmentSelectorSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 0, 13, 24),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 367),
            child: Container(
              height: 307,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < AssessmentType.values.length;
                    index++
                  )
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _SelectorPanelRow(
                              type: AssessmentType.values[index],
                              onTap: () => Navigator.of(
                                context,
                              ).pop(AssessmentType.values[index]),
                            ),
                          ),
                          if (index != AssessmentType.values.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE6E6E6),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentSelectorShell extends StatelessWidget {
  final AssessmentType? type;
  final bool showError;

  const _AssessmentSelectorShell({required this.type, required this.showError});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: showError
              ? _AssessmentBlockSectionState._error
              : _AssessmentBlockSectionState._green,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          if (type != null) ...[
            _AssessmentIcon(type: type!, size: 31),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              type?.title ?? 'Select Assessment Type',
              style: const TextStyle(
                color: _AssessmentBlockSectionState._text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SvgPicture.asset(
            'assets/learning_module/text_block_chevron.svg',
            width: 13,
            height: 13,
            colorFilter: const ColorFilter.mode(
              Color(0xFF8BD5A0),
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorPanelRow extends StatelessWidget {
  final AssessmentType type;
  final VoidCallback onTap;

  const _SelectorPanelRow({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 10, 0),
          child: Row(
            children: [
              _AssessmentIcon(type: type, size: 33),
              const SizedBox(width: 21),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      type.selectorTitle,
                      style: const TextStyle(
                        color: _AssessmentBlockSectionState._text,
                        fontSize: 14,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Transform.rotate(
                    angle: -1.5708,
                    child: SvgPicture.asset(
                      'assets/learning_module/text_block_chevron.svg',
                      width: 13,
                      height: 13,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF141414),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssessmentIcon extends StatelessWidget {
  final AssessmentType type;
  final double size;

  const _AssessmentIcon({required this.type, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _AssessmentBlockSectionState._purpleTile,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: type == AssessmentType.trueFalse
          ? Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/learning_module/assessment_true_false1.svg',
                  width: size * 0.45,
                  height: size * 0.45,
                ),
                Positioned(
                  right: size * 0.2,
                  bottom: size * 0.2,
                  child: SvgPicture.asset(
                    'assets/learning_module/assessment_true_false2.svg',
                    width: size * 0.25,
                    height: size * 0.2,
                  ),
                ),
              ],
            )
          : SvgPicture.asset(
              type.iconAsset,
              width: size * 0.5,
              height: size * 0.5,
            ),
    );
  }
}

class _AssessmentFormCard extends StatelessWidget {
  final Widget child;
  final bool showError;

  const _AssessmentFormCard({required this.child, required this.showError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: showError
              ? _AssessmentBlockSectionState._error
              : const Color(0xFFD8D0D0),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _NumericForm extends StatelessWidget {
  final TextEditingController questionController;
  final TextEditingController answerController;
  final TextEditingController minController;
  final TextEditingController maxController;
  final TextEditingController explanationController;
  final bool showError;

  const _NumericForm({
    required this.questionController,
    required this.answerController,
    required this.minController,
    required this.maxController,
    required this.explanationController,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssessmentInput(
          label: 'Question',
          helper: 'Enter a numeric response question.',
          controller: questionController,
          maxLength: 300,
          height: 76,
          maxLines: 3,
          error: showError && questionController.text.trim().isEmpty,
        ),
        const SizedBox(height: 12),
        _AssessmentInput(
          label: 'Correct Answer',
          controller: answerController,
          maxLength: 80,
          height: 42,
          keyboardType: TextInputType.number,
          error:
              showError && num.tryParse(answerController.text.trim()) == null,
        ),
        const SizedBox(height: 12),
        const _SmallLabel('Acceptable Range'),
        const SizedBox(height: 4),
        const Text(
          'Set the minimum and maximum accepted values.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CompactTextField(
                controller: minController,
                hintText: 'Min',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                error: showError && !_validMinimum(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('to', style: TextStyle(fontSize: 13)),
            ),
            Expanded(
              child: _CompactTextField(
                controller: maxController,
                hintText: 'Max',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                error: showError && !_validMaximum(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AssessmentInput(
          label: 'Explanation',
          optional: true,
          controller: explanationController,
          maxLength: 300,
          height: 76,
          maxLines: 3,
        ),
      ],
    );
  }

  bool _validMinimum() {
    final minimum = num.tryParse(minController.text.trim());
    final maximum = num.tryParse(maxController.text.trim());
    final answer = num.tryParse(answerController.text.trim());
    return minimum != null &&
        maximum != null &&
        answer != null &&
        minimum <= maximum &&
        answer >= minimum;
  }

  bool _validMaximum() {
    final minimum = num.tryParse(minController.text.trim());
    final maximum = num.tryParse(maxController.text.trim());
    final answer = num.tryParse(answerController.text.trim());
    return minimum != null &&
        maximum != null &&
        answer != null &&
        minimum <= maximum &&
        answer <= maximum;
  }
}

class _MatchingForm extends StatelessWidget {
  final List<TextEditingController> topControllers;
  final List<TextEditingController> bottomControllers;
  final List<int> bottomOrder;
  final bool showError;
  final VoidCallback onAddRow;
  final ValueChanged<int> onRemoveRow;

  const _MatchingForm({
    required this.topControllers,
    required this.bottomControllers,
    required this.bottomOrder,
    required this.showError,
    required this.onAddRow,
    required this.onRemoveRow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SmallLabel('Left Column (Terms)'),
        const SizedBox(height: 4),
        const Text(
          'What users will match from.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 11),
        ),
        const SizedBox(height: 8),
        _MatchingGroup(
          controllers: topControllers,
          badgeColor: _AssessmentBlockSectionState._green,
          showError: showError,
          onDelete: onRemoveRow,
        ),
        const SizedBox(height: 16),
        const _SmallLabel('Right Column (Definitions)'),
        const SizedBox(height: 4),
        const Text(
          'What users will match to.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 11),
        ),
        const SizedBox(height: 8),
        _MatchingGroup(
          controllers: bottomControllers,
          labels: bottomOrder,
          badgeColor: const Color(0xFF5B8DEF),
          showError: showError,
          onDelete: onRemoveRow,
        ),
        const SizedBox(height: 10),
        _MiniOutlineButton(label: '+ Add Rows', onTap: onAddRow),
      ],
    );
  }
}

class _MatchingGroup extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<int>? labels;
  final Color badgeColor;
  final bool showError;
  final ValueChanged<int>? onDelete;

  const _MatchingGroup({
    required this.controllers,
    required this.badgeColor,
    required this.showError,
    this.labels,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final children = List.generate(
      controllers.length,
      (index) => _MatchingItemRow(
        key: ValueKey(controllers[index]),
        index: index,
        controller: controllers[index],
        letterIndex: labels?[index] ?? index,
        badgeColor: badgeColor,
        showError: showError,
        canDelete: controllers.length > 2,
        onDelete: onDelete == null ? null : () => onDelete!(index),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8D0D0)),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _MatchingItemRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final int letterIndex;
  final Color badgeColor;
  final bool showError;
  final bool canDelete;
  final VoidCallback? onDelete;

  const _MatchingItemRow({
    super.key,
    required this.index,
    required this.controller,
    required this.letterIndex,
    required this.badgeColor,
    required this.showError,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 8),
          const SizedBox(width: 15),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              String.fromCharCode(65 + letterIndex.clamp(0, 25)),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _CompactTextField(
              controller: controller,
              hintText: 'Enter item',
              error: showError && controller.text.trim().isEmpty,
            ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: canDelete ? 1 : 0.35,
            child: GestureDetector(
              onTap: canDelete ? onDelete : null,
              child: SvgPicture.asset(
                'assets/learning_module/learning_objective_trash.svg',
                width: 13,
                height: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TrueFalseForm extends StatelessWidget {
  final List<TextEditingController> questionControllers;
  final List<bool?> selectedAnswers;
  final bool showError;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onRemoveQuestion;
  final void Function(int index, bool value) onAnswerChanged;

  const _TrueFalseForm({
    required this.questionControllers,
    required this.selectedAnswers,
    required this.showError,
    required this.onAddQuestion,
    required this.onRemoveQuestion,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SmallLabel('Question and Answer'),
        const SizedBox(height: 4),
        const Text(
          'Add statements and select whether each is true or false.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 11),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD8D0D0)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            children: [
              for (
                var index = 0;
                index < questionControllers.length;
                index++
              ) ...[
                _TrueFalseQuestionRow(
                  controller: questionControllers[index],
                  selectedAnswer: selectedAnswers[index],
                  showError: showError,
                  canDelete: questionControllers.length > 2,
                  onDelete: () => onRemoveQuestion(index),
                  onAnswerChanged: (value) => onAnswerChanged(index, value),
                ),
                if (index != questionControllers.length - 1)
                  const Divider(height: 1, color: Color(0xFFE6E6E6)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _MiniOutlineButton(label: '+ Add Question', onTap: onAddQuestion),
      ],
    );
  }
}

class _TrueFalseQuestionRow extends StatelessWidget {
  final TextEditingController controller;
  final bool? selectedAnswer;
  final bool showError;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<bool> onAnswerChanged;

  const _TrueFalseQuestionRow({
    required this.controller,
    required this.selectedAnswer,
    required this.showError,
    required this.canDelete,
    required this.onDelete,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _CompactTextField(
              controller: controller,
              hintText: 'Enter question',
              error: showError && controller.text.trim().isEmpty,
            ),
          ),
          const SizedBox(width: 8),
          _TinyChoice(
            label: 'T',
            selected: selectedAnswer == true,
            onTap: () => onAnswerChanged(true),
          ),
          _TinyChoice(
            label: 'F',
            selected: selectedAnswer == false,
            onTap: () => onAnswerChanged(false),
          ),
          const SizedBox(width: 6),
          Opacity(
            opacity: canDelete ? 1 : 0.3,
            child: GestureDetector(
              onTap: canDelete ? onDelete : null,
              child: SvgPicture.asset(
                'assets/learning_module/learning_objective_trash.svg',
                width: 14,
                height: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TinyChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 31,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0x245DB075) : Colors.white,
          border: Border.all(
            color: selected
                ? _AssessmentBlockSectionState._green
                : const Color(0xFFD8D0D0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? _AssessmentBlockSectionState._green
                : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ParagraphForm extends StatelessWidget {
  final TextEditingController questionController;
  final String responseLength;
  final bool showError;
  final ValueChanged<String> onLengthChanged;

  const _ParagraphForm({
    required this.questionController,
    required this.responseLength,
    required this.showError,
    required this.onLengthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SmallLabel('Response Type'),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          initialValue: responseLength,
          onSelected: onLengthChanged,
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'short',
              child: _LengthOption(title: 'Short', subtitle: '150 characters'),
            ),
            PopupMenuItem(
              value: 'medium',
              child: _LengthOption(title: 'Medium', subtitle: '300 characters'),
            ),
            PopupMenuItem(
              value: 'long',
              child: _LengthOption(title: 'Long', subtitle: '450 characters'),
            ),
          ],
          child: _DropdownLikeBox(label: _lengthLabel(responseLength)),
        ),
        const SizedBox(height: 12),
        _AssessmentInput(
          label: 'Question',
          controller: questionController,
          maxLength: _AssessmentBlockSectionState._paragraphLimit(
            responseLength,
          ),
          height: 76,
          maxLines: 3,
          error: showError && questionController.text.trim().isEmpty,
        ),
      ],
    );
  }

  static String _lengthLabel(String value) => switch (value) {
    'medium' => 'Medium',
    'long' => 'Long',
    _ => 'Short',
  };
}

class _MultipleChoiceForm extends StatelessWidget {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final TextEditingController explanationController;
  final int? correctIndex;
  final bool showError;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final ValueChanged<int> onCorrectChanged;

  const _MultipleChoiceForm({
    required this.questionController,
    required this.optionControllers,
    required this.explanationController,
    required this.correctIndex,
    required this.showError,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onCorrectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssessmentInput(
          label: 'Question',
          controller: questionController,
          maxLength: 300,
          height: 76,
          maxLines: 3,
          error: showError && questionController.text.trim().isEmpty,
        ),
        const SizedBox(height: 12),
        const _SmallLabel('Answer Options'),
        const SizedBox(height: 8),
        for (var index = 0; index < optionControllers.length; index++) ...[
          _OptionRow(
            index: index,
            controller: optionControllers[index],
            selected: correctIndex == index,
            canDelete: optionControllers.length > 2,
            showError: showError,
            onSelected: () => onCorrectChanged(index),
            onDelete: () => onRemoveOption(index),
          ),
          if (index != optionControllers.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 10),
        _MiniOutlineButton(
          label: '+ Add Option',
          onTap: optionControllers.length >= 4 ? null : onAddOption,
        ),
        if (showError && correctIndex == null) ...[
          const SizedBox(height: 8),
          const Text(
            'Select the correct answer.',
            style: TextStyle(
              color: _AssessmentBlockSectionState._error,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _AssessmentInput(
          label: 'Explanation',
          optional: true,
          controller: explanationController,
          maxLength: 300,
          height: 76,
          maxLines: 3,
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final bool selected;
  final bool canDelete;
  final bool showError;
  final VoidCallback onSelected;
  final VoidCallback onDelete;

  const _OptionRow({
    required this.index,
    required this.controller,
    required this.selected,
    required this.canDelete,
    required this.showError,
    required this.onSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onSelected,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selected
                  ? _AssessmentBlockSectionState._green
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? _AssessmentBlockSectionState._green
                    : const Color(0xFFD8D0D0),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              String.fromCharCode(65 + index),
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF777777),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactTextField(
            controller: controller,
            hintText: 'Option ${String.fromCharCode(65 + index)}',
            error: showError && controller.text.trim().isEmpty,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canDelete ? onDelete : null,
          child: Opacity(
            opacity: canDelete ? 1 : 0.35,
            child: SvgPicture.asset(
              'assets/learning_module/learning_objective_trash.svg',
              width: 14,
              height: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssessmentInput extends StatelessWidget {
  final String label;
  final String? helper;
  final bool optional;
  final TextEditingController controller;
  final int maxLength;
  final double height;
  final int maxLines;
  final bool error;
  final TextInputType? keyboardType;

  const _AssessmentInput({
    required this.label,
    this.helper,
    required this.controller,
    required this.maxLength,
    required this.height,
    this.optional = false,
    this.maxLines = 1,
    this.error = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallLabel(label, optional: optional),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: height + 13,
          child: Stack(
            children: [
              SizedBox(
                height: height,
                child: TextField(
                  controller: controller,
                  maxLength: maxLength,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                        color: error
                            ? _AssessmentBlockSectionState._error
                            : _AssessmentBlockSectionState._green,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                        color: error
                            ? _AssessmentBlockSectionState._error
                            : _AssessmentBlockSectionState._green,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 0,
                child: Text(
                  '${controller.text.length}/$maxLength',
                  style: const TextStyle(color: Color(0xFF565656), fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool error;
  final TextInputType? keyboardType;

  const _CompactTextField({
    required this.controller,
    required this.hintText,
    required this.error,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFBEBEBE), fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 7,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
              color: error
                  ? _AssessmentBlockSectionState._error
                  : _AssessmentBlockSectionState._green,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
              color: error
                  ? _AssessmentBlockSectionState._error
                  : _AssessmentBlockSectionState._green,
            ),
          ),
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final String label;
  final bool optional;

  const _SmallLabel(this.label, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          color: _AssessmentBlockSectionState._text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        children: [
          if (optional)
            const TextSpan(
              text: ' (optional)',
              style: TextStyle(
                color: _AssessmentBlockSectionState._muted,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _MiniOutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: _AssessmentBlockSectionState._text,
          disabledForegroundColor: const Color(0xFF9A9A9A),
          side: const BorderSide(color: Color(0xFFD8D0D0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DropdownLikeBox extends StatelessWidget {
  final String label;

  const _DropdownLikeBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _AssessmentBlockSectionState._green),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          SvgPicture.asset(
            'assets/learning_module/text_block_chevron.svg',
            width: 13,
            height: 13,
            colorFilter: const ColorFilter.mode(
              Color(0xFF8BD5A0),
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}

class _LengthOption extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LengthOption({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
        ),
      ],
    );
  }
}
