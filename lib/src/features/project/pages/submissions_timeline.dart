import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import '../../../backend/db/repositories/projects_repo.dart';

class InteractiveTimelinePage extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> tags;

  const InteractiveTimelinePage({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.tags,
  });

  @override
  State<InteractiveTimelinePage> createState() => _InteractiveTimelinePageState();
}

class _InteractiveTimelinePageState extends State<InteractiveTimelinePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final List<Map<String, String>> _timeline = [];
  final _projectsRepo = ProjectsRepo();

  bool _isSaving = false;
  DateTime? _lastSavedAt;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final timeline = await _projectsRepo.getTimeline(widget.projectId);
    if (timeline != null && mounted) {
      setState(() {
        _timeline.clear();
        _timeline.addAll(timeline);
      });
    }
  }

  Future<void> _saveTimeline() async {
    setState(() => _isSaving = true);
    await _projectsRepo.updateTimeline(
      id: widget.projectId,
      timeline: _timeline,
    );
    if (!mounted) return;
    setState(() {
      _lastSavedAt = DateTime.now();
      _isSaving = false;
    });
  }

  String? get _savedLabel {
    if (_lastSavedAt == null) return null;
    final h = _lastSavedAt!.hour % 12 == 0 ? 12 : _lastSavedAt!.hour % 12;
    final m = _lastSavedAt!.minute.toString().padLeft(2, '0');
    final ampm = _lastSavedAt!.hour < 12 ? 'AM' : 'PM';
    return 'Saved $h:$m $ampm';
  }

  // Parses a stored date string (ISO yyyy-MM-dd or legacy "MMM d, yyyy")
  // and returns a short "M/d" label.
  String _shortDate(String raw) {
    DateTime? dt = DateTime.tryParse(raw);
    dt ??= DateFormat('MMM d, yyyy').tryParseStrict(raw);
    if (dt == null) return raw;
    return '${dt.month}/${dt.day}';
  }

  // Returns the time string as-is (user types it directly).
  String _displayTime(String? raw) => raw ?? '';

  List<Map<String, String>> get _sortedTimeline {
    final sorted = List<Map<String, String>>.from(_timeline);
    sorted.sort((a, b) {
      DateTime? da = DateTime.tryParse(a['date'] ?? '');
      da ??= DateFormat('MMM d, yyyy').tryParseStrict(a['date'] ?? '');
      DateTime? db = DateTime.tryParse(b['date'] ?? '');
      db ??= DateFormat('MMM d, yyyy').tryParseStrict(b['date'] ?? '');
      if (da == null || db == null) return 0;
      return _sortAscending ? da.compareTo(db) : db.compareTo(da);
    });
    return sorted;
  }

  void _showEventSheet({Map<String, String>? existing, int? editIndex}) {
    final isEditing = existing != null;
    final selectedDate = _selectedDay;

    final eventCtrl = TextEditingController(text: existing?['event'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final locationCtrl = TextEditingController(text: existing?['location'] ?? '');

    // Parse stored time (e.g. "2:30 PM" or "All Day") back into parts.
    final stored = existing?['time'] ?? '';
    bool allDay = stored.toLowerCase() == 'all day';
    String amPm = stored.toUpperCase().contains('PM') ? 'PM' : 'AM';
    final timeDigits = stored.replaceAll(RegExp(r'[^0-9:]'), '').trim();
    final timeCtrl = TextEditingController(text: allDay ? '' : timeDigits);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isEditing ? 'Edit Event' : 'New Event',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                _sheetField(eventCtrl, 'Event name',
                    autofocus: !isEditing),
                const SizedBox(height: 14),
                _sheetField(descCtrl, 'Description', optional: true),
                const SizedBox(height: 14),
                _sheetField(locationCtrl, 'Location', optional: true),
                const SizedBox(height: 14),

                // All Day toggle
                Row(
                  children: [
                    const Text(
                      'All Day',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: allDay,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) =>
                          setSheetState(() => allDay = v),
                    ),
                  ],
                ),

                // Time row — hidden when All Day is on
                if (!allDay) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _sheetField(
                          timeCtrl,
                          'Time',
                          optional: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_TimeInputFormatter()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // AM / PM toggle
                      _AmPmToggle(
                        value: amPm,
                        onChanged: (v) =>
                            setSheetState(() => amPm = v),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      if (eventCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Event name is required')),
                        );
                        return;
                      }
                      final navigator = Navigator.of(sheetContext);
                      String storedTime = '';
                      if (allDay) {
                        storedTime = 'All Day';
                      } else if (timeCtrl.text.trim().isNotEmpty) {
                        storedTime = '${timeCtrl.text.trim()} $amPm';
                      }
                      final entry = {
                        'date': existing?['date'] ??
                            DateFormat('yyyy-MM-dd').format(selectedDate),
                        'time': storedTime,
                        'event': eventCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'location': locationCtrl.text.trim(),
                      };
                      setState(() {
                        if (isEditing && editIndex != null) {
                          _timeline[editIndex] = entry;
                        } else {
                          _timeline.add(entry);
                        }
                      });
                      await _saveTimeline();
                      navigator.pop();
                    },
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add Event',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(sheetContext);
                        setState(() => _timeline.removeAt(editIndex!));
                        await _saveTimeline();
                        navigator.pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Delete Event',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController controller,
    String label, {
    bool optional = false,
    bool autofocus = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final displayLabel = optional ? '$label (optional)' : label;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: displayLabel,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildEventRow(Map<String, String> item, bool isHighlighted, int originalIndex) {
    final cardBg = isHighlighted ? AppColors.primary : const Color(0xFFF2F2F7);
    final titleColor = isHighlighted ? Colors.white : Colors.black87;
    final subColor = isHighlighted ? Colors.white70 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: time + date
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _displayTime(item['time']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _shortDate(item['date'] ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item['event'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: titleColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEventSheet(
                          existing: item,
                          editIndex: originalIndex,
                        ),
                        child: Icon(Icons.more_vert, size: 18, color: subColor),
                      ),
                    ],
                  ),
                  if ((item['description'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['description']!,
                      style: TextStyle(fontSize: 14, color: subColor),
                    ),
                  ],
                  if ((item['location'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: subColor),
                        const SizedBox(width: 4),
                        Text(item['location']!,
                            style: TextStyle(fontSize: 13, color: subColor)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedTimeline;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final navigator = Navigator.of(context);
          await _saveTimeline();
          if (mounted) navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _saveTimeline();
              if (mounted) navigator.pop();
            },
          ),
          title: const Text(
            'Project Timeline',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_savedLabel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    _savedLabel!,
                    style: const TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ── Weekly calendar strip ──────────────────────────────────────
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              availableGestures: AvailableGestures.horizontalSwipe,
              pageAnimationEnabled: true,
              pageAnimationDuration: const Duration(milliseconds: 350),
              pageAnimationCurve: Curves.easeInOutCubic,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: AppColors.textPrimary),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: AppColors.textPrimary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                weekendStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              // All non-builder decorations must be rectangle (not circle) so
              // that AnimatedContainer never tweens circle ↔ borderRadius.
              calendarStyle: const CalendarStyle(
                defaultDecoration: BoxDecoration(),
                weekendDecoration: BoxDecoration(),
                outsideDecoration: BoxDecoration(),
                disabledDecoration: BoxDecoration(),
                todayDecoration: BoxDecoration(),
                selectedDecoration: BoxDecoration(),
                defaultTextStyle: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
                weekendTextStyle: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders(
                // Today: light green circle (uses borderRadius: 999 to avoid
                // the circle-shape / borderRadius conflict).
                todayBuilder: (context, day, focusedDay) => Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Selected: scale-bounce animation into a green rounded rect.
                selectedBuilder: (context, day, focusedDay) =>
                    TweenAnimationBuilder<double>(
                  key: ValueKey(day),
                  tween: Tween(begin: 0.65, end: 1.0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, _) => Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E5EA)),

            // ── Column header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 52,
                    child: Text(
                      'DATE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Action Item',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _sortAscending = !_sortAscending),
                    child: Icon(
                      _sortAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E5EA)),

            // ── Timeline list ──────────────────────────────────────────────
            Expanded(
              child: sorted.isEmpty
                  ? const Center(
                      child: Text(
                        'No timeline events yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final item = sorted[index];
                        final originalIndex = _timeline.indexOf(item);
                        return _buildEventRow(
                            item, index == 0, originalIndex);
                      },
                    ),
            ),

            // ── Add button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: GestureDetector(
                onTap: () => _showEventSheet(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add to timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Sliding AM / PM segmented control.
class _AmPmToggle extends StatelessWidget {
  const _AmPmToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _pillW = 46.0;
  static const _height = 50.0;
  static const _pad = 4.0;

  @override
  Widget build(BuildContext context) {
    final isPm = value == 'PM';
    return Container(
      height: _height,
      width: _pillW * 2 + _pad * 2,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Sliding green pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment:
                isPm ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _pillW,
              height: _height - _pad * 2,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Labels on top
          Row(
            children: ['AM', 'PM'].map((label) {
              final selected = value == label;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(label),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Accepts only digits, auto-inserts a colon, and enforces valid 12-hour
/// times (no leading zero required): hours 1–12, minutes 00–59.
///
/// Hour boundary rules:
///   • First digit 2–9  → hour is that single digit; remaining digits are minutes.
///   • First digit 1    → wait for second digit:
///       - 10 / 11 / 12 → 2-digit hour, remaining digits are minutes.
///       - 13–19         → hour is "1", the second digit becomes minute-tens.
///   • First digit 0    → rejected (no leading zeros).
class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final first = int.parse(digits[0]);

    // Reject 0 as the first digit (no "0X" hours in 12-hour format)
    if (first == 0) return oldValue;

    // ── Determine hour / minute split ─────────────────────────────────────
    String hourPart;
    String minDigits;

    if (first == 1 && digits.length >= 2) {
      final twoDigit = int.parse(digits.substring(0, 2));
      if (twoDigit <= 12) {
        // Valid 2-digit hour (10 / 11 / 12)
        hourPart = digits.substring(0, 2);
        minDigits = digits.substring(2);
      } else {
        // 13–19: treat first digit as complete hour
        hourPart = digits[0];
        minDigits = digits.substring(1);
      }
    } else {
      // First digit 1 alone, or 2–9: single-digit hour
      hourPart = digits[0];
      minDigits = digits.isNotEmpty && digits.length > 1 ? digits.substring(1) : '';
    }

    // ── Validate minute digits ────────────────────────────────────────────
    if (minDigits.length > 2) return oldValue;
    if (minDigits.isNotEmpty && int.parse(minDigits[0]) > 5) return oldValue;
    if (minDigits.length == 2 && int.parse(minDigits) > 59) return oldValue;

    // ── Format ────────────────────────────────────────────────────────────
    final formatted =
        minDigits.isEmpty ? hourPart : '$hourPart:$minDigits';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
