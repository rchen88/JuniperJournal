import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../styling/app_colors.dart';
import '../../backend/db/repositories/projects_repo.dart';
import 'journal_log.dart';

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
  DateTime? _selectedDay;
  final List<Map<String, String>> _timeline = [];
  final _projectsRepo = ProjectsRepo();

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
    await _projectsRepo.updateTimeline(
      id: widget.projectId,
      timeline: _timeline,
    );
  }

  void _addEventDialog() {
    final eventController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Timeline'),
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField('Event (required)', eventController),
              const SizedBox(height: 12),
              _buildTextField('Description (optional)', descriptionController),
              const SizedBox(height: 12),
              _buildTextField('Location', locationController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: AppColors.buttonText,
            ),
            onPressed: () async {
              if (eventController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event name is required')),
                );
                return;
              }
              setState(() {
                _timeline.add({
                  'date': DateFormat('MMM d, yyyy').format(_selectedDay ?? _focusedDay),
                  'event': eventController.text,
                  'description': descriptionController.text,
                  'location': locationController.text,
                });
              });
              await _saveTimeline();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 60),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JournalLogScreen(
                    projectId: widget.projectId,
                    projectName: widget.projectName,
                    tags: widget.tags,
                  ),
                ),
              ),

              // DONE BUTTON
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MaterialsCostPage(
                        projectName: widget.projectName,
                        tags: widget.tags,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Done",
                  style: TextStyle(
                    color: Color(0xFF5DB075),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
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
            const SizedBox(height: 16),

            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.horizontalSwipe,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(color: AppColors.textPrimary),
                weekendTextStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _timeline.isEmpty
                  ? const Center(
                      child: Text(
                        'No timeline events added yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _timeline.length,
                      itemBuilder: (context, index) {
                        final item = _timeline[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderLight),
                          ),
                          child: ListTile(
                            title: Text(
                              item['event']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['date']!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                if (item['description']!.isNotEmpty)
                                  Text(
                                    item['description']!,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                if (item['location']!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16,
                                          color: AppColors.iconSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['location']!,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _addEventDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.buttonText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 24),
                label: const Text(
                  'Add to Timeline',
                  style: TextStyle(
                    fontSize: 16,
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