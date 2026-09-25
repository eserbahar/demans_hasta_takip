import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show supabase;
import '../../widgets/star_rating.dart';

/// Ateş/Nabız/Tansiyon (Vitals) entry dialog.
/// Fields: star rating (same treatment as every other category) + four
/// optional numeric fields (°C, bpm, sistolik, diyastolik) + notes; at
/// least one numeric field must be filled before save.
/// *(exact UI TBD from user per the implementation plan — placeholder.)*
Future<void> showVitalsEntryDialog(
  BuildContext context, {
  required String patientId,
  required VoidCallback onSaved,
}) async {
  const color = Color(0xFFC1483F);
  int rating = 3;
  final tempController = TextEditingController();
  final pulseController = TextEditingController();
  final systolicController = TextEditingController();
  final diastolicController = TextEditingController();
  final notesController = TextEditingController();
  String? errorMessage;

  await showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.favorite, color: color),
                SizedBox(width: 8),
                Text('Ateş / Nabız / Tansiyon', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Genel durum:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  StarRatingInput(
                    value: rating,
                    color: color,
                    onChanged: (value) => setDialogState(() => rating = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tempController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Ateş',
                            suffixText: '°C',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: pulseController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nabız',
                            suffixText: 'bpm',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: systolicController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tansiyon (büyük)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: diastolicController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tansiyon (küçük)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notlar (opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                onPressed: () async {
                  final temperature = double.tryParse(tempController.text.replaceAll(',', '.'));
                  final pulse = int.tryParse(pulseController.text);
                  final systolic = int.tryParse(systolicController.text);
                  final diastolic = int.tryParse(diastolicController.text);

                  if (temperature == null && pulse == null && systolic == null && diastolic == null) {
                    setDialogState(
                      () => errorMessage = 'En az bir ölçüm (ateş, nabız veya tansiyon) girin.',
                    );
                    return;
                  }

                  try {
                    await supabase.from('vitals_entries').insert({
                      'patient_id': patientId,
                      'rating': rating,
                      'temperature_c': temperature,
                      'pulse_bpm': pulse,
                      'bp_systolic': systolic,
                      'bp_diastolic': diastolic,
                      'notes': notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      'logged_by': supabase.auth.currentUser!.id,
                    });
                    if (!dialogCtx.mounted) return;
                    Navigator.pop(dialogCtx);
                    onSaved();
                  } on PostgrestException catch (error) {
                    setDialogState(() => errorMessage = error.message);
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      );
    },
  );
  tempController.dispose();
  pulseController.dispose();
  systolicController.dispose();
  diastolicController.dispose();
  notesController.dispose();
}
