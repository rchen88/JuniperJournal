import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';
import 'submission_metrics.dart';
import 'dart:math';

class MaterialsCostPage extends StatefulWidget {
  final String projectName;
  final List<String> tags;

  const MaterialsCostPage({
    super.key,
    required this.projectName,
    required this.tags,
  });

  @override
  State<MaterialsCostPage> createState() => _MaterialsCostPageState();
}

class _MaterialsCostPageState extends State<MaterialsCostPage> {
  final List<Map<String, dynamic>> _materials = [];

  void _addMaterialDialog() {
    final nameController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Material"),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("Item name", nameController, false),
              const SizedBox(height: 12),
              _buildTextField("Cost (\$)", costController, true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: AppColors.buttonText,
            ),
            onPressed: () {
              final name = nameController.text.trim();
              final cost = double.tryParse(costController.text.trim()) ?? 0.0;
              if (name.isEmpty || cost <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter valid item and cost.")),
                );
                return;
              }
              setState(() {
                _materials.add({
                  "id": Random().nextInt(9999),
                  "name": name,
                  "cost": cost,
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isNumber) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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

  double get _totalCost => _materials.fold(0.0, (sum, item) => sum + item["cost"]);

  // Green = < $20, Yellow = $20–99.99, Red = $100+
  Color get _totalColor {
    if (_totalCost < 19.99) return const Color(0xFF5DB075); // Green (Low)
    if (_totalCost < 100) return const Color(0xFFFFC93D); // Yellow (Medium)
    return Colors.red; // High
  }

  String get _costRangeLabel {
    if (_totalCost < 19.99) return "Low cost project";
    if (_totalCost < 100) return "Medium cost project";
    return "High cost project";
  }

  // ✅ Fix for individual item indicators too
  Color _getIndicatorColor(double cost) {
    if (cost < 19.99) return const Color(0xFF5DB075); // Green
    if (cost < 100) return const Color(0xFFFFC93D); // Yellow
    return Colors.red; // Red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
  backgroundColor: AppColors.primary,
  title: Text(
    widget.projectName,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  centerTitle: true,
  actions: [
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MetricsPage(
              projectName: widget.projectName,
              tags: widget.tags,
            ),
          ),
        );
      },
      child: const Text(
        'Done',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
  ],
),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Project Header with Tags
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

            // 🔹 Total Cost Circle (Bigger)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _totalCost),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _totalColor.withOpacity(0.15),
                      border: Border.all(color: _totalColor, width: 6),
                    ),
                    child: Center(
                      child: Text(
                        "\$${value.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 40,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: _totalColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Range Container (styled like your button)
            Center(
              child: Container(
                width: 251,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: ShapeDecoration(
                  color: _totalColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    _costRangeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Materials List
            Expanded(
              child: _materials.isEmpty
                  ? const Center(
                      child: Text(
                        "No materials added yet.",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _materials.length,
                      itemBuilder: (context, index) {
                        final material = _materials[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderLight),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getIndicatorColor(material["cost"]),
                              radius: 8,
                            ),
                            title: Text(
                              material["name"],
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              "\$${material["cost"].toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // 🔹 Add Item Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _addMaterialDialog,
                icon: const Icon(Icons.add, size: 26),
                label: const Text(
                  "Add Item",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.buttonText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
