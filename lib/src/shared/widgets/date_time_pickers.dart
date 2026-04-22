import 'package:flutter/material.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';

/// Shows the same scroll-wheel date picker used in the project timeline.
/// Returns the selected [DateTime] or null if dismissed.
Future<DateTime?> showWheelDatePicker(
    BuildContext context, DateTime initial) async {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  const baseYear = 2020;
  const yearCount = 16;

  int selMonth = initial.month - 1;
  int selDay = initial.day - 1;
  int selYear = (initial.year - baseYear).clamp(0, yearCount - 1);

  final monthCtrl = FixedExtentScrollController(initialItem: selMonth);
  final dayCtrl = FixedExtentScrollController(initialItem: selDay);
  final yearCtrl = FixedExtentScrollController(initialItem: selYear);

  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black26,
    builder: (dCtx) => StatefulBuilder(
      builder: (dCtx, setDState) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(dCtx),
                        child: const Icon(Icons.close,
                            size: 20, color: AppColors.textSecondary),
                      ),
                      const Expanded(
                        child: Text('Select Date',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ListWheelScrollView.useDelegate(
                              controller: monthCtrl,
                              itemExtent: 44,
                              diameterRatio: 4,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setDState(() => selMonth = i),
                              childDelegate: ListWheelChildLoopingListDelegate(
                                children: months
                                    .map((m) => Center(
                                          child: Text(m,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary)),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: ListWheelScrollView.useDelegate(
                              controller: dayCtrl,
                              itemExtent: 44,
                              diameterRatio: 4,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setDState(() => selDay = i),
                              childDelegate: ListWheelChildLoopingListDelegate(
                                children: List.generate(
                                    31,
                                    (i) => Center(
                                          child: Text('${i + 1}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary)),
                                        )),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: ListWheelScrollView.useDelegate(
                              controller: yearCtrl,
                              itemExtent: 44,
                              diameterRatio: 4,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setDState(() => selYear = i),
                              childDelegate: ListWheelChildListDelegate(
                                children: List.generate(
                                    yearCount,
                                    (i) => Center(
                                          child: Text('${baseYear + i}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary)),
                                        )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                TextButton(
                  onPressed: () {
                    final month = (selMonth % 12) + 1;
                    final year = baseYear + selYear;
                    final maxDay = DateUtils.getDaysInMonth(year, month);
                    final day = ((selDay % 31) + 1).clamp(1, maxDay);
                    Navigator.pop(dCtx, DateTime(year, month, day));
                  },
                  child: const Text('Apply',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shows the same scroll-wheel time picker used in the project timeline.
/// Returns `{'hour': int, 'minute': int, 'amPm': String}` or null if dismissed.
Future<Map<String, dynamic>?> showWheelTimePicker(
    BuildContext context, int hour, int minute, String amPm) async {
  int selHour = hour.clamp(1, 12);
  int selMinute = minute.clamp(0, 59);
  String selAmPm = amPm;

  final hourCtrl = FixedExtentScrollController(initialItem: selHour - 1);
  final minuteCtrl = FixedExtentScrollController(initialItem: selMinute);

  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierColor: Colors.black26,
    builder: (dCtx) => StatefulBuilder(
      builder: (dCtx, setDState) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(dCtx),
                        child: const Icon(Icons.close,
                            size: 20, color: AppColors.textSecondary),
                      ),
                      const Expanded(
                        child: Text('Select Time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SizedBox(
                  height: 220,
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 44,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    controller: hourCtrl,
                                    itemExtent: 44,
                                    diameterRatio: 4,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (i) => setDState(
                                        () => selHour = (i % 12) + 1),
                                    childDelegate:
                                        ListWheelChildLoopingListDelegate(
                                      children: List.generate(
                                          12,
                                          (i) => Center(
                                                child: Text(
                                                  (i + 1)
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: AppColors
                                                          .textPrimary),
                                                ),
                                              )),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    controller: minuteCtrl,
                                    itemExtent: 44,
                                    diameterRatio: 4,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (i) =>
                                        setDState(() => selMinute = i % 60),
                                    childDelegate:
                                        ListWheelChildLoopingListDelegate(
                                      children: List.generate(
                                          60,
                                          (i) => Center(
                                                child: Text(
                                                  i.toString().padLeft(2, '0'),
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: AppColors
                                                          .textPrimary),
                                                ),
                                              )),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: WheelAmPmToggle(
                          value: selAmPm,
                          onChanged: (v) => setDState(() => selAmPm = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, {
                    'hour': selHour,
                    'minute': selMinute,
                    'amPm': selAmPm,
                  }),
                  child: const Text('Apply',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class WheelAmPmToggle extends StatelessWidget {
  const WheelAmPmToggle({super.key, required this.value, required this.onChanged});

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
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: isPm ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _pillW,
              height: _height - _pad * 2,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
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
                            ? AppColors.white
                            : AppColors.textSecondary,
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
