import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/activity_categories.dart';
import '../config/app_colors.dart';
import '../main.dart' show supabase;
import '../models/entries.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../widgets/star_rating.dart';
import 'entries/activity_entry_dialog.dart';
import 'entries/bowel_entry_dialog.dart';
import 'entries/fluid_entry_dialog.dart';
import 'entries/medication_entry_dialog.dart';
import 'entries/nutrition_entry_dialog.dart';
import 'entries/urine_entry_dialog.dart';
import 'entries/vitals_entry_dialog.dart';
import 'journal_screen.dart';
import 'patient_selection_screen.dart';

const _monthNames = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String formatTurkishDate(DateTime date) => '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// Status of a single category tile for "today" — a pure read-time filter
/// over `logged_at`, per the implementation plan. `rating == null` means
/// nothing was logged today (the tile's default/empty rendering).
class CategoryTodayStatus {
  final int? rating;
  final String? detail;

  const CategoryTodayStatus({this.rating, this.detail});

  bool get hasEntry => rating != null;
}

/// "Bugünü Kaydet" — the app's sole landing screen after patient selection.
/// Absorbs what used to be a separate Home screen; no bottom navigation.
class LogTodayScreen extends StatefulWidget {
  final RemotePatient? selectedPatient;

  const LogTodayScreen({super.key, this.selectedPatient});

  @override
  State<LogTodayScreen> createState() => _LogTodayScreenState();
}

class _LogTodayScreenState extends State<LogTodayScreen> {
  late PatientProfile _patient;
  List<Medication> _medications = [];
  Map<ActivityCategoryId, CategoryTodayStatus> _todayStatus = {};
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    final selectedPatient = widget.selectedPatient;
    _patient = PatientProfile(
      name: selectedPatient?.fullName ?? 'Ayşe Turan',
      birthDate: selectedPatient?.birthDate ?? DateTime(1948, 5, 14),
      medicalConditions:
          selectedPatient?.medicalConditions ?? ['Alzheimer / Demans', 'Hipertansiyon'],
    );
    _loadMedications().then((_) => _loadTodayCategoryStatus());
  }

  String? get _patientId => widget.selectedPatient?.id;

  Future<void> _loadMedications() async {
    final patientId = _patientId;
    if (patientId == null) return;
    try {
      final rows = await supabase
          .from('medications')
          .select('id, name, dosage, time_slot, scheduled_time')
          .eq('patient_id', patientId)
          .eq('is_active', true)
          .order('scheduled_time');
      if (mounted) {
        setState(() {
          _medications = rows.map((row) {
            final scheduledTime = row['scheduled_time'] as String;
            return Medication(
              id: row['id'] as String,
              name: row['name'] as String,
              dosage: row['dosage'] as String,
              timeSlot: row['time_slot'] as String,
              plannedTime: scheduledTime.substring(0, 5),
            );
          }).toList();
        });
      }
    } on PostgrestException catch (error) {
      debugPrint('İlaçlar yüklenemedi: ${error.message}');
    }
  }

  /// One read-time query per backing table, filtered to
  /// `[start of today, start of tomorrow)` in local time — nothing is ever
  /// overwritten, so history stays intact; only "today" status resets.
  Future<void> _loadTodayCategoryStatus() async {
    final patientId = _patientId;
    if (patientId == null) {
      setState(() => _isLoadingStatus = false);
      return;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final startOfTomorrow =
        DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String();

    final status = <ActivityCategoryId, CategoryTodayStatus>{};

    Future<List<Map<String, dynamic>>> latestRow(
      String table,
      String columns, {
      String? equalsColumn,
      String? equalsValue,
    }) async {
      try {
        var query = supabase
            .from(table)
            .select(columns)
            .eq('patient_id', patientId)
            .gte('logged_at', startOfDay)
            .lt('logged_at', startOfTomorrow);
        if (equalsColumn != null && equalsValue != null) {
          query = query.eq(equalsColumn, equalsValue);
        }
        final rows = await query.order('logged_at', ascending: false);
        return List<Map<String, dynamic>>.from(rows);
      } on PostgrestException catch (error) {
        debugPrint('$table için bugünkü durum yüklenemedi: ${error.message}');
        return const [];
      }
    }

    final medRows = await latestRow('medication_logs', 'rating, logged_at',
        equalsColumn: 'status', equalsValue: 'taken');
    if (medRows.isNotEmpty && medRows.first['rating'] != null) {
      status[ActivityCategoryId.medication] =
          CategoryTodayStatus(rating: medRows.first['rating'] as int?);
    }

    final fluidRows = await latestRow('fluid_entries', 'rating, logged_at');
    if (fluidRows.isNotEmpty && fluidRows.first['rating'] != null) {
      status[ActivityCategoryId.fluid] =
          CategoryTodayStatus(rating: fluidRows.first['rating'] as int?);
    }

    final urineRows = await latestRow('urine_entries', 'rating, logged_at');
    if (urineRows.isNotEmpty && urineRows.first['rating'] != null) {
      status[ActivityCategoryId.urine] =
          CategoryTodayStatus(rating: urineRows.first['rating'] as int?);
    }

    final nutritionRows = await latestRow('nutrition_entries', 'rating, logged_at');
    if (nutritionRows.isNotEmpty) {
      status[ActivityCategoryId.nutrition] =
          CategoryTodayStatus(rating: nutritionRows.first['rating'] as int?);
    }

    final bowelRows = await latestRow('bowel_entries', 'rating, logged_at');
    if (bowelRows.isNotEmpty) {
      status[ActivityCategoryId.bowel] =
          CategoryTodayStatus(rating: bowelRows.first['rating'] as int?);
    }

    final vitalsRows = await latestRow(
      'vitals_entries',
      'rating, temperature_c, pulse_bpm, bp_systolic, bp_diastolic, logged_at',
    );
    if (vitalsRows.isNotEmpty) {
      final entry = VitalsEntry.fromMap(vitalsRows.first);
      status[ActivityCategoryId.vitals] =
          CategoryTodayStatus(rating: entry.rating, detail: entry.summary);
    }

    final activityRows = await latestRow('activity_entries', 'category, rating, logged_at');
    for (final category in ActivityCategory.values) {
      final rows = activityRows.where((row) => row['category'] == category.dbValue).toList();
      if (rows.isEmpty) continue;
      final id = switch (category) {
        ActivityCategory.physical => ActivityCategoryId.physical,
        ActivityCategory.mental => ActivityCategoryId.mental,
        ActivityCategory.social => ActivityCategoryId.social,
      };
      status[id] = CategoryTodayStatus(rating: rows.first['rating'] as int?);
    }

    if (mounted) {
      setState(() {
        _todayStatus = status;
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _markMedicationTaken(Medication medication, int rating, String? notes) async {
    final patientId = _patientId;
    if (patientId == null) return;
    try {
      await supabase.from('medication_logs').insert({
        'patient_id': patientId,
        'medication_id': medication.id,
        'status': 'taken',
        'rating': rating,
        'notes': notes,
        'logged_at': DateTime.now().toUtc().toIso8601String(),
        'logged_by': supabase.auth.currentUser!.id,
      });
      final now = TimeOfDay.now();
      if (mounted) {
        setState(() {
          medication.isTaken = true;
          medication.takenTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        });
      }
      await _loadTodayCategoryStatus();
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _cancelMedicationTaken(Medication medication) async {
    final patientId = _patientId;
    if (patientId == null) return;
    try {
      await supabase.from('medication_logs').insert({
        'patient_id': patientId,
        'medication_id': medication.id,
        'status': 'cancelled',
        'logged_at': DateTime.now().toUtc().toIso8601String(),
        'logged_by': supabase.auth.currentUser!.id,
      });
      if (mounted) {
        setState(() {
          medication.isTaken = false;
          medication.takenTime = null;
        });
      }
      await _loadTodayCategoryStatus();
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _showMedicationManagerDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final timeController = TextEditingController(text: '09:00');
    String selectedTimeSlot = 'Sabah';
    final timeSlots = ['Sabah', 'Öğle', 'Akşam', 'Gece'];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medication_liquid, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('İlaç Yönetimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Mevcut İlaçlar:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Container(
                        height: 130,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _medications.isEmpty
                            ? const Center(
                                child: Text('Tanımlı ilaç yok', style: TextStyle(fontSize: 12, color: Colors.grey)))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _medications.length,
                                itemBuilder: (ctx, index) {
                                  final med = _medications[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text('${med.name} (${med.dosage})',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${med.timeSlot} - ${med.plannedTime}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() => _medications.removeAt(index));
                                        setDialogState(() {});
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 24),
                      const Text('Yeni İlaç Ekle:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'İlaç Adı',
                          hintText: 'Örn: Coraspin',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dosageController,
                              decoration: const InputDecoration(
                                labelText: 'Dozaj',
                                hintText: 'Örn: 100mg',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: timeController,
                              decoration: const InputDecoration(
                                labelText: 'Saat',
                                hintText: 'Örn: 09:00',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTimeSlot,
                        decoration: const InputDecoration(
                          labelText: 'Öğün / Zaman',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: timeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text(slot))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedTimeSlot = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Kapat'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            onPressed: () async {
                              final patientId = _patientId;
                              final name = nameController.text.trim();
                              final dosage =
                                  dosageController.text.trim().isEmpty ? '1 Doz' : dosageController.text.trim();
                              final plannedTime =
                                  timeController.text.trim().isEmpty ? '09:00' : timeController.text.trim();

                              if (patientId == null || name.isEmpty) return;
                              try {
                                await supabase.from('medications').insert({
                                  'patient_id': patientId,
                                  'name': name,
                                  'dosage': dosage,
                                  'time_slot': selectedTimeSlot,
                                  'scheduled_time': plannedTime,
                                  'created_by': supabase.auth.currentUser!.id,
                                });
                                await _loadMedications();
                                if (dialogCtx.mounted) {
                                  nameController.clear();
                                  dosageController.clear();
                                  setDialogState(() {});
                                }
                              } on PostgrestException catch (error) {
                                if (dialogCtx.mounted) {
                                  ScaffoldMessenger.of(dialogCtx)
                                      .showSnackBar(SnackBar(content: Text(error.message)));
                                }
                              }
                            },
                            child: const Text('İlacı Kaydet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCategoryDialog(ActivityCategoryDescriptor descriptor) async {
    final patientId = _patientId;
    if (patientId == null) return;

    switch (descriptor.id) {
      case ActivityCategoryId.medication:
        await showMedicationEntryDialog(
          context,
          medications: _medications,
          onMarkTaken: _markMedicationTaken,
          onCancelTaken: _cancelMedicationTaken,
          onManageMedications: _showMedicationManagerDialog,
        );
        break;
      case ActivityCategoryId.vitals:
        await showVitalsEntryDialog(
          context,
          patientId: patientId,
          onSaved: _loadTodayCategoryStatus,
        );
        break;
      case ActivityCategoryId.nutrition:
        await showNutritionEntryDialog(
          context,
          patientId: patientId,
          onSaved: _loadTodayCategoryStatus,
        );
        break;
      case ActivityCategoryId.fluid:
        await showFluidEntryDialog(
          context,
          patientId: patientId,
          onSaved: _loadTodayCategoryStatus,
        );
        break;
      case ActivityCategoryId.urine:
        await showUrineEntryDialog(
          context,
          patientId: patientId,
          onSaved: _loadTodayCategoryStatus,
        );
        break;
      case ActivityCategoryId.bowel:
        await showBowelEntryDialog(
          context,
          patientId: patientId,
          onSaved: _loadTodayCategoryStatus,
        );
        break;
      case ActivityCategoryId.physical:
      case ActivityCategoryId.mental:
      case ActivityCategoryId.social:
        await showActivityEntryDialog(
          context,
          patientId: patientId,
          descriptor: descriptor,
          onSaved: _loadTodayCategoryStatus,
        );
        break;
    }
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label: Yakında')),
    );
  }

  Widget _buildCategoryTile(ActivityCategoryDescriptor descriptor) {
    final status = _todayStatus[descriptor.id];
    final hasEntry = status?.hasEntry ?? false;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCategoryDialog(descriptor),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: descriptor.tint, shape: BoxShape.circle),
                      child: Icon(descriptor.icon, color: descriptor.color, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descriptor.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  StarRatingDisplay(rating: status?.rating, size: 14, color: descriptor.color),
                  const SizedBox(height: 3),
                  if (hasEntry)
                    Text(
                      (status?.detail?.isNotEmpty ?? false) ? status!.detail! : ' ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9.5, color: descriptor.color, fontWeight: FontWeight.bold),
                    )
                  else
                    const Text(
                      'Günlük veri girişi yapılmadı',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9.5, color: AppColors.mutedText),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.bodyText,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _patient.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.bodyText,
                  ),
            ),
            Text(
              formatTurkishDate(DateTime.now()),
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Geçmiş / Raporlar',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalScreen(selectedPatient: widget.selectedPatient),
                ),
              );
            },
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
          IconButton(
            tooltip: 'Hasta değiştir',
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PatientSelectionScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.56,
                ),
                itemCount: activityCategories.length,
                itemBuilder: (context, index) => _buildCategoryTile(activityCategories[index]),
              ),
            ),
    );
  }
}
