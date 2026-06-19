import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  /// Computes a scale factor based on screen width.
  /// Baseline design width is 380px.
  /// Scaled values are clamped between 0.75 and 1.25.
  double get scaleFactor => (MediaQuery.of(this).size.width / 380).clamp(0.75, 1.25);

  /// Scales a numeric [value] by the current screen's scale factor.
  double scale(double value) => value * scaleFactor;
}
