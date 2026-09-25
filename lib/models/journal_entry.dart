import 'package:flutter/material.dart';

import '../config/activity_categories.dart';

/// Display projection used by the Journal screen — one row per real
/// Supabase entry, mapped from any of the 7 backing tables.
class JournalEntry {
  final DateTime time;
  final String title;
  final String? detailText;
  final int? rating;
  final String? notes;
  final ActivityCategoryId categoryId;
  final Color color;
  final IconData icon;

  const JournalEntry({
    required this.time,
    required this.title,
    this.detailText,
    this.rating,
    this.notes,
    required this.categoryId,
    required this.color,
    required this.icon,
  });

  String get formattedTime =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
