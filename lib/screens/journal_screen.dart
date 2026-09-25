import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/activity_categories.dart';
import '../config/app_colors.dart';
import '../main.dart' show supabase;
import '../models/entries.dart';
import '../models/journal_entry.dart';
import '../models/patient.dart';
import '../widgets/star_rating.dart';
import 'log_today_screen.dart' show formatTurkishDate;

/// Günlük (Journal) — Supabase-backed, all 9 categories, same tile order
/// as "Bugünü Kaydet". Replaces the old in-memory `_logs`/`ActivityLog`
/// list, which never persisted across reloads.
class JournalScreen extends StatefulWidget {
  final RemotePatient? selectedPatient;

  const JournalScreen({super.key, this.selectedPatient});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _selectedDay = DateTime.now();
  Map<ActivityCategoryId, List<JournalEntry>> _entriesByCategory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournalEntries(_selectedDay);
  }

  String? get _patientId => widget.selectedPatient?.id;

  void _changeDay(int deltaDays) {
    setState(() => _selectedDay = _selectedDay.add(Duration(days: deltaDays)));
    _loadJournalEntries(_selectedDay);
  }

  Future<void> _loadJournalEntries(DateTime day) async {
    final patientId = _patientId;
    if (patientId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    final startOfDay = DateTime(day.year, day.month, day.day).toUtc().toIso8601String();
    final startOfNextDay =
        DateTime(day.year, day.month, day.day + 1).toUtc().toIso8601String();

    final result = <ActivityCategoryId, List<JournalEntry>>{};

    Future<List<Map<String, dynamic>>> rowsFor(String table, String columns) async {
      try {
        final rows = await supabase
            .from(table)
            .select(columns)
            .eq('patient_id', patientId)
            .gte('logged_at', startOfDay)
            .lt('logged_at', startOfNextDay)
            .order('logged_at', ascending: false);
        return List<Map<String, dynamic>>.from(rows);
      } on PostgrestException catch (error) {
        debugPrint('$table için günlük kayıtlar yüklenemedi: ${error.message}');
        return const [];
      }
    }

    final medDescriptor = activityCategories.firstWhere((d) => d.id == ActivityCategoryId.medication);
    final medRows = await rowsFor(
      'medication_logs',
      'status, rating, notes, logged_at, medications(name, dosage)',
    );
    result[ActivityCategoryId.medication] = medRows
        .where((row) => row['status'] == 'taken')
        .map((row) {
      final med = row['medications'] as Map<String, dynamic>?;
      final title = med != null ? '${med['name']} ${med['dosage']}' : 'İlaç verildi';
      return JournalEntry(
        time: DateTime.parse(row['logged_at'] as String).toLocal(),
        title: title,
        rating: row['rating'] as int?,
        notes: row['notes'] as String?,
        categoryId: ActivityCategoryId.medication,
        color: medDescriptor.color,
        icon: medDescriptor.icon,
      );
    }).toList();

    final fluidDescriptor = activityCategories.firstWhere((d) => d.id == ActivityCategoryId.fluid);
    final fluidRows = await rowsFor('fluid_entries', 'amount_ml, type, rating, notes, logged_at');
    result[ActivityCategoryId.fluid] = fluidRows.map((row) {
      return JournalEntry(
        time: DateTime.parse(row['logged_at'] as String).toLocal(),
        title: '+${row['amount_ml']} ml ${row['type']}',
        rating: row['rating'] as int?,
        notes: row['notes'] as String?,
        categoryId: ActivityCategoryId.fluid,
        color: fluidDescriptor.color,
        icon: fluidDescriptor.icon,
      );
    }).toList();

    final urineDescriptor = activityCategories.firstWhere((d) => d.id == ActivityCategoryId.urine);
    final urineRows = await rowsFor('urine_entries', 'amount_ml, status, rating, notes, logged_at');
    result[ActivityCategoryId.urine] = urineRows.map((row) {
      return JournalEntry(
        time: DateTime.parse(row['logged_at'] as String).toLocal(),
        title: 'İdrar Çıkışı (${row['status']}) - ${row['amount_ml']} ml',
        rating: row['rating'] as int?,
        notes: row['notes'] as String?,
        categoryId: ActivityCategoryId.urine,
        color: urineDescriptor.color,
        icon: urineDescriptor.icon,
      );
    }).toList();

    final nutritionDescriptor =
        activityCategories.firstWhere((d) => d.id == ActivityCategoryId.nutrition);
    final nutritionRows =
        await rowsFor('nutrition_entries', 'rating, meal_type, portion_percent, notes, logged_at');
    result[ActivityCategoryId.nutrition] = nutritionRows.map((row) {
      final entry = NutritionEntry.fromMap({...row, 'id': ''});
      final detail = [
        if (entry.mealType != null) entry.mealType,
        if (entry.portionPercent != null) '%${entry.portionPercent}',
      ].join(' · ');
      return JournalEntry(
        time: entry.loggedAt ?? DateTime.now(),
        title: detail.isEmpty ? 'Beslenme kaydı' : detail,
        rating: entry.rating,
        notes: entry.notes,
        categoryId: ActivityCategoryId.nutrition,
        color: nutritionDescriptor.color,
        icon: nutritionDescriptor.icon,
      );
    }).toList();

    final bowelDescriptor = activityCategories.firstWhere((d) => d.id == ActivityCategoryId.bowel);
    final bowelRows = await rowsFor('bowel_entries', 'rating, consistency, notes, logged_at');
    result[ActivityCategoryId.bowel] = bowelRows.map((row) {
      final entry = BowelEntry.fromMap({...row, 'id': ''});
      return JournalEntry(
        time: entry.loggedAt ?? DateTime.now(),
        title: entry.consistency ?? 'Dışkılama kaydı',
        rating: entry.rating,
        notes: entry.notes,
        categoryId: ActivityCategoryId.bowel,
        color: bowelDescriptor.color,
        icon: bowelDescriptor.icon,
      );
    }).toList();

    final vitalsDescriptor = activityCategories.firstWhere((d) => d.id == ActivityCategoryId.vitals);
    final vitalsRows = await rowsFor(
      'vitals_entries',
      'rating, temperature_c, pulse_bpm, bp_systolic, bp_diastolic, notes, logged_at',
    );
    result[ActivityCategoryId.vitals] = vitalsRows.map((row) {
      final entry = VitalsEntry.fromMap({...row, 'id': ''});
      return JournalEntry(
        time: entry.loggedAt ?? DateTime.now(),
        title: entry.summary.isEmpty ? 'Vital ölçüm' : entry.summary,
        rating: entry.rating,
        notes: entry.notes,
        categoryId: ActivityCategoryId.vitals,
        color: vitalsDescriptor.color,
        icon: vitalsDescriptor.icon,
      );
    }).toList();

    final activityRows =
        await rowsFor('activity_entries', 'category, rating, duration_minutes, notes, logged_at');
    for (final categoryId in [
      ActivityCategoryId.physical,
      ActivityCategoryId.mental,
      ActivityCategoryId.social,
    ]) {
      final descriptor = activityCategories.firstWhere((d) => d.id == categoryId);
      final dbCategory = descriptor.activityDbCategory!;
      result[categoryId] = activityRows
          .where((row) => row['category'] == dbCategory.dbValue)
          .map((row) {
        final entry = ActivityEntry.fromMap({...row, 'id': ''});
        return JournalEntry(
          time: entry.loggedAt ?? DateTime.now(),
          title: entry.durationMinutes != null ? '${entry.durationMinutes} dk' : descriptor.label,
          rating: entry.rating,
          notes: entry.notes,
          categoryId: categoryId,
          color: descriptor.color,
          icon: descriptor.icon,
        );
      }).toList();
    }

    if (mounted) {
      setState(() {
        _entriesByCategory = result;
        _isLoading = false;
      });
    }
  }

  Widget _buildCategorySection(ActivityCategoryDescriptor descriptor) {
    final entries = _entriesByCategory[descriptor.id] ?? const [];
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(descriptor.icon, color: descriptor.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  descriptor.label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: descriptor.color),
                ),
              ],
            ),
            const Divider(height: 18),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Text(
                  'Bu kategoride bugün için kayıt yok.',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
              )
            else
              Column(
                children: entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            entry.formattedTime,
                            style: const TextStyle(
                                color: AppColors.mutedText, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.title,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              const SizedBox(height: 2),
                              StarRatingDisplay(rating: entry.rating, size: 13, color: descriptor.color),
                              if (entry.notes != null && entry.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    entry.notes!,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.mutedText, fontStyle: FontStyle.italic),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label: Yakında')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.bodyText,
        title: Text(
          widget.selectedPatient?.fullName ?? 'Günlük',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bodyText),
        ),
        actions: [
          IconButton(
            tooltip: 'Geçmiş / Raporlar',
            icon: const Icon(Icons.history),
            onPressed: () => _showComingSoon('Raporlar'),
          ),
          IconButton(
            tooltip: 'PDF dışa aktar',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _showComingSoon('PDF dışa aktar'),
          ),
          IconButton(
            tooltip: 'Doktorla paylaş',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showComingSoon('Doktorla paylaş'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDay(-1),
                ),
                Text(
                  formatTurkishDate(_selectedDay),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.bodyText),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeDay(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: activityCategories.map(_buildCategorySection).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
