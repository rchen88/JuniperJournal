import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';

class MetricsPage extends StatefulWidget {
  final String projectName;
  final List<String> tags;

  const MetricsPage({
    super.key,
    required this.projectName,
    required this.tags,
  });

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {

  // -------------------------------------------------------------------
  // METRIC OPTIONS + THRESHOLDS (From Appendix B)
  // -------------------------------------------------------------------
  final List<Map<String, dynamic>> metricOptions = [
    {
      "name": "Educational",
      "unit": "People",
      "circleLabel": "People Reached",
      "thresholds": {"low": 20, "medium": 200},
    },
    {
      "name": "BioGrowth",
      "unit": "Sq Ft",
      "circleLabel": "Habitat Restored",
      "thresholds": {"low": 50, "medium": 500},
    },
    {
      "name": "Water",
      "unit": "Gallons",
      "circleLabel": "Gallons Saved",
      "thresholds": {"low": 1000, "medium": 10000},
    },
    {
      "name": "Energy",
      "unit": "kWh",
      "circleLabel": "Energy Saved",
      "thresholds": {"low": 500, "medium": 5000},
    },
    {
      "name": "CO₂",
      "unit": "lbs CO₂",
      "circleLabel": "CO₂ Avoided",
      "thresholds": {"low": 500, "medium": 5000},
    },
    {
      "name": "Waste",
      "unit": "lbs",
      "circleLabel": "Waste Diverted",
      "thresholds": {"low": 100, "medium": 1000},
    },
  ];

  Map<String, dynamic>? selectedMetric;

  // User inputs
  final baselineCtrl = TextEditingController();
  final postCtrl = TextEditingController();
  final scaleCtrl = TextEditingController(text: "1");
  final durationCtrl = TextEditingController(text: "1");

  // Calculated values
  double? impactValue;
  String impactLabel = "LOW IMPACT";
  Color impactColor = Colors.green;

  // -------------------------------------------------------------------
  // Automatically recalc whenever the user types
  // -------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    baselineCtrl.addListener(calculateImpact);
    postCtrl.addListener(calculateImpact);
    scaleCtrl.addListener(calculateImpact);
    durationCtrl.addListener(calculateImpact);
  }

  // -------------------------------------------------------------------
  // IMPACT CALCULATION
  // -------------------------------------------------------------------
  void calculateImpact() {
    if (selectedMetric == null) return;

    double baseline = double.tryParse(baselineCtrl.text) ?? 0;
    double post = double.tryParse(postCtrl.text) ?? 0;
    double scale = double.tryParse(scaleCtrl.text) ?? 1;
    double duration = double.tryParse(durationCtrl.text) ?? 1;

    // formula:
    // Impact = (Baseline - Post).abs() × Scale × Duration
    double value = (baseline - post).abs() * scale * duration;

    final thresholds = selectedMetric!["thresholds"];
    double low = thresholds["low"];
    double med = thresholds["medium"];

    if (value > med) {
      impactLabel = "HIGH IMPACT";
      impactColor = Colors.orange[700]!;
    } else if (value > low) {
      impactLabel = "MEDIUM IMPACT";
      impactColor = Colors.blue;
    } else {
      impactLabel = "LOW IMPACT";
      impactColor = Colors.green;
    }

    setState(() {
      impactValue = value;
    });
  }

  // -------------------------------------------------------------------
  // INPUT FIELD BUILDER
  // -------------------------------------------------------------------
  Widget buildInputRow(String label, TextEditingController ctrl, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF323639),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE8EBEC)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "0",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE8EBEC)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Center(
                child: Text(unit,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // IMPACT CIRCLE
  // -------------------------------------------------------------------
  Widget buildImpactCircle(String label) {
    if (impactValue == null) {
      return const SizedBox(height: 180);
    }

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE7E7E7), width: 3),
              ),
            ),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF585462),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  impactValue!.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Net Impact",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // MAIN UI
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    String? unit = selectedMetric?["unit"];
    String? circleLabel = selectedMetric?["circleLabel"];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.projectName),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              "Done",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            // Tags from first page
            Wrap(
              spacing: 8,
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // SELECT METRIC
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedMetric,
              decoration: InputDecoration(
                labelText: "Select Impact Metric",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: metricOptions.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt["name"]),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedMetric = value);
                calculateImpact();
              },
            ),

            const SizedBox(height: 20),

            if (selectedMetric != null)
              Column(
                children: [
                  buildInputRow("Baseline", baselineCtrl, unit!),
                  const SizedBox(height: 20),

                  buildInputRow("Post", postCtrl, unit),
                  const SizedBox(height: 20),

                  buildInputRow("Scale", scaleCtrl, "×"),
                  const SizedBox(height: 20),

                  buildInputRow("Duration", durationCtrl, "yrs"),
                  const SizedBox(height: 30),

                  if (circleLabel != null) buildImpactCircle(circleLabel),

                  const SizedBox(height: 20),

                  // Impact level
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: impactColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      impactLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
