import 'package:flutter/material.dart';

import '../models/entries.dart';

/// Single source-of-truth identifier for each of the 9 daily-tracking
/// categories shown on the "Bugünü Kaydet" grid and in the Journal.
enum ActivityCategoryId {
  medication,
  vitals,
  nutrition,
  fluid,
  urine,
  bowel,
  physical,
  mental,
  social,
}

/// Descriptor for one category tile: label, icon, accent color and the
/// Supabase table it is backed by. `activityDbCategory` is only set for the
/// three categories that share the `activity_entries` table
/// (Fiziksel/Zihinsel/Sosyal), distinguished by the `category` enum column.
class ActivityCategoryDescriptor {
  final ActivityCategoryId id;
  final String label;
  final IconData icon;
  final Color color;
  final Color tint;
  final String tableName;
  final ActivityCategory? activityDbCategory;

  const ActivityCategoryDescriptor({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.tint,
    required this.tableName,
    this.activityDbCategory,
  });
}

/// Fixed 3x3 grid order per the approved design preview:
/// row1: İlaç, Ateş/Nabız/Tansiyon, Beslenme
/// row2: Sıvı Alımı, İdrar Çıkışı, Dışkılama
/// row3: Fiziksel Aktivite, Zihinsel Aktivite, Sosyal Aktivite
const List<ActivityCategoryDescriptor> activityCategories = [
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.medication,
    label: 'İlaç',
    icon: Icons.medication,
    color: Color(0xFF4C8C6B),
    tint: Color(0xFFEAF2ED),
    tableName: 'medication_logs',
  ),
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.vitals,
    label: 'Ateş/Nabız/Tansiyon',
    icon: Icons.favorite,
    color: Color(0xFFC1483F),
    tint: Color(0xFFFBEBE9),
    tableName: 'vitals_entries',
  ),
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.nutrition,
    label: 'Beslenme',
    icon: Icons.restaurant,
    color: Color(0xFFC97B4A),
    tint: Color(0xFFFBF0E8),
    tableName: 'nutrition_entries',
  ),
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.fluid,
    label: 'Sıvı Alımı',
    icon: Icons.water_drop,
    color: Color(0xFF3E7CB1),
    tint: Color(0xFFE9F1F8),
    tableName: 'fluid_entries',
  ),
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.urine,
    label: 'İdrar Çıkışı',
    icon: Icons.wc,
    color: Color(0xFFD98E3F),
    tint: Color(0xFFFBF1E4),
    tableName: 'urine_entries',
  ),
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.bowel,
    label: 'Dışkılama',
    icon: Icons.hourglass_bottom,
    color: Color(0xFF8B6449),
    tint: Color(0xFFF1EAE5),
    tableName: 'bowel_entries',
  ),
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.physical,
    label: 'Fiziksel Aktivite',
    icon: Icons.directions_walk,
    color: Color(0xFF2E8B8B),
    tint: Color(0xFFE7F2F2),
    tableName: 'activity_entries',
    activityDbCategory: ActivityCategory.physical,
  ),
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.mental,
    label: 'Zihinsel Aktivite',
    icon: Icons.psychology,
    color: Color(0xFF7C5CA8),
    tint: Color(0xFFEFEAF6),
    tableName: 'activity_entries',
    activityDbCategory: ActivityCategory.mental,
  ),
  ActivityCategoryDescriptor(
    id: ActivityCategoryId.social,
    label: 'Sosyal Aktivite',
    icon: Icons.groups,
    color: Color(0xFFC15B7C),
    tint: Color(0xFFF7EAEE),
    tableName: 'activity_entries',
    activityDbCategory: ActivityCategory.social,
  ),
];
