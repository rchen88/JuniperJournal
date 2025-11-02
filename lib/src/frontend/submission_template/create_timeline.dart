import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';

class ProjectTimelineScreen extends StatelessWidget {
  final int projectId;    
  final String projectName;
  final String projectDate;
  final List<String> tags;
  final List<TimelineEvent> events;

  const ProjectTimelineScreen({
    super.key,
    required this.projectId,  
    required this.projectName,
    required this.projectDate,
    required this.tags,
    this.events = const [],
  });

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
        title: Text(
          projectName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Done",
              style: TextStyle(
                color: Color(0xFF5DB075),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Date
            Text(
              projectDate,
              style: const TextStyle(
                color: Color(0xFF868686),
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),

            // Tags Row
            if (tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5DB075),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 30),

            // Calendar Row (empty by default)
            const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  "Calendar will appear here",
                  style: TextStyle(
                    color: Color(0xFFBCC1CD),
                    fontFamily: 'Inter',
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(color: Color(0xFFFAF9F9)),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "DATE",
                  style: TextStyle(
                    color: Color(0xFFBCC1CD),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Action Item",
                  style: TextStyle(
                    color: Color(0xFFBCC1CD),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Timeline events
            Expanded(
              child: events.isEmpty
                  ? const Center(
                      child: Text(
                        "No timeline events added yet",
                        style: TextStyle(
                          color: Color(0xFFBCC1CD),
                          fontFamily: 'Inter',
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _TimelineCard(event: event);
                      },
                    ),
            ),

            // Add to timeline button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5DB075)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5DB075),
                    shape: BoxShape.circle,
                  ),
                ),
                label: const Text(
                  "Add to timeline",
                  style: TextStyle(
                    color: Color(0xFF1F2024),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
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

class TimelineEvent {
  final String time;
  final String date;
  final String title;
  final String description;
  final String? person;
  final Color? color;
  final Color? textColor;

  TimelineEvent({
    required this.time,
    required this.date,
    required this.title,
    required this.description,
    this.person,
    this.color,
    this.textColor,
  });
}

class _TimelineCard extends StatelessWidget {
  final TimelineEvent event;

  const _TimelineCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                event.time,
                style: const TextStyle(
                  color: Color(0xFF202525),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                event.date,
                style: const TextStyle(
                  color: Color(0xFFBCC1CD),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: event.color ?? const Color(0xFFF6F6F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    color: event.textColor ?? const Color(0xFF202525),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(
                    color: (event.textColor ?? const Color(0xFF202525))
                        .withOpacity(0.9),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (event.person != null)
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 8,
                        backgroundImage:
                            NetworkImage("https://placehold.co/16x16"),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.person!,
                        style: TextStyle(
                          color: event.textColor ?? const Color(0xFF202525),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
