// lib/core/models/category_model.dart
import 'package:flutter/material.dart';

class CategoryModel {
  final String label;
  final IconData icon;
  final Color color;

  const CategoryModel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CategoryModel && runtimeType == other.runtimeType && label == other.label;

  @override
  int get hashCode => label.hashCode;
}