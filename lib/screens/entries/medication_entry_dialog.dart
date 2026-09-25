import 'package:flutter/material.dart';

import '../../config/activity_categories.dart';
import '../../models/medication.dart';
import '../../widgets/star_rating.dart';

/// İlaç (Medication) tile dialog. Extends the existing taken/missed/
/// cancelled logic (`_toggleMedication` in the pre-split `main.dart`) by
/// showing a small star+notes step before marking a dose taken — the
/// medication_logs insert itself stays owned by the caller so it can keep
/// updating the shared `Medication` list / today-status in one place.
/// *(exact UI TBD from user per the implementation plan — placeholder.)*
Future<void> showMedicationEntryDialog(
  BuildContext context, {
  required List<Medication> medications,
  required Future<void> Function(Medication medication, int rating, String? notes) onMarkTaken,
  required Future<void> Function(Medication medication) onCancelTaken,
  required VoidCallback onManageMedications,
}) async {
  const descriptor = ActivityCategoryDescriptor(
    id: ActivityCategoryId.medication,
    label: 'İlaç',
    icon: Icons.medication,
    color: Color(0xFF4C8C6B),
    tint: Color(0xFFEAF2ED),
    tableName: 'medication_logs',
  );

  await showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final pending = medications.where((m) => !m.isTaken).toList();
          final taken = medications.where((m) => m.isTaken).toList();

          return AlertDialog(
            title: Row(
              children: [
                Icon(descriptor.icon, color: descriptor.color),
                const SizedBox(width: 8),
                const Text('İlaç Takibi', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (medications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Tanımlı ilaç yok. Aşağıdan ekleyebilirsiniz.',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    if (pending.isNotEmpty) ...[
                      const Text('Bekleyen:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      ...pending.map((med) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: Icon(Icons.medication, color: descriptor.color),
                              title: Text('${med.name} ${med.dosage}'),
                              subtitle: Text('${med.timeSlot} - ${med.plannedTime}'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: descriptor.color,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final result = await _showRatingStep(context, med, descriptor.color);
                                  if (result == null) return;
                                  await onMarkTaken(med, result.$1, result.$2);
                                  if (dialogCtx.mounted) setDialogState(() {});
                                },
                                child: const Text('Ver'),
                              ),
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                    if (taken.isNotEmpty) ...[
                      const Text('Verildi:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      ...taken.map((med) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: const Icon(Icons.check_circle, color: Colors.green),
                              title: Text(
                                '${med.name} ${med.dosage}',
                                style: const TextStyle(decoration: TextDecoration.lineThrough),
                              ),
                              subtitle: Text(
                                med.takenTime != null ? 'Verildi: ${med.takenTime}' : 'Verildi',
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  final confirmed = await _showCancelConfirmation(context, med);
                                  if (confirmed != true) return;
                                  await onCancelTaken(med);
                                  if (dialogCtx.mounted) setDialogState(() {});
                                },
                                child: const Text('İptal Et'),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  onManageMedications();
                },
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('İlaçları Yönet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<(int, String?)?> _showRatingStep(
  BuildContext context,
  Medication medication,
  Color color,
) async {
  int rating = 3;
  final notesController = TextEditingController();

  final result = await showDialog<(int, String?)>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('${medication.name} ${medication.dosage}', style: const TextStyle(fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nasıl geçti?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                StarRatingInput(
                  value: rating,
                  color: color,
                  onChanged: (value) => setDialogState(() => rating = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notlar (opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                onPressed: () {
                  final notes = notesController.text.trim();
                  Navigator.pop(dialogCtx, (rating, notes.isEmpty ? null : notes));
                },
                child: const Text('Verildi Olarak Kaydet'),
              ),
            ],
          );
        },
      );
    },
  );
  notesController.dispose();
  return result;
}

Future<bool?> _showCancelConfirmation(BuildContext context, Medication medication) {
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('İlaç İptal Onayı', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          '${medication.name} (${medication.dosage}) ilacı verildi olarak işaretlenmişti.\n\n'
          'Bu kaydı iptal edip verilmedi olarak değiştirmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Evet, İptal Et'),
          ),
        ],
      );
    },
  );
}
