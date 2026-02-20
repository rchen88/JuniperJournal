import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';

void main() {
  test('AppColors exposes expected core palette values', () {
    expect(AppColors.primary, const Color(0xFF5DB075));
    expect(AppColors.background, Colors.white);
    expect(AppColors.error, Colors.red);
    expect(AppColors.tagText, const Color(0xFF5DB075));
  });
}
