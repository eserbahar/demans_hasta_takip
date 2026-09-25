import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/activity_categories.dart';
import '../../main.dart' show supabase;
import '../../models/entries.dart';
import '../../widgets/star_rating.dart';

/// Shared dialog for Fiziksel / Zihinsel / Sosyal Aktivite — one
/// `activity_entries` row parameterized by [descriptor]'s
/// `activityDbCategory`. Fields: star rating + duration quick-chips + notes.
/// *(exact UI TBD from user per the implementation plan — placeholder.)*
Future<void> showActivityEntryDialog(
  BuildContext context, {
  required String patientId,
  required ActivityCategoryDescriptor descriptor,
  required VoidCallback onSaved,
}) async {
  assert(descriptor.activityDbCategory != null);

  int rating = 3;
  int? durationMinutes;
  final notesController = TextEditingController();
  String? errorMessage;

  await showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(descriptor.icon, color: descriptor.color),
                const SizedBox(width: 8),
                Text('${descriptor.label} Girişi', style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nasıl geçti?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  StarRatingInput(
                    value: rating,
                    color: descriptor.color,
                    onChanged: (value) => setDialogState(() => rating = value),
                  ),
                  const SizedBox(height: 16),
                  const Text('Süre:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [10, 20, 30, 60].map((minutes) {
                      final selected = durationMinutes == minutes;
                      return ChoiceChip(
                        label: Text('$minutes dk'),
                        selected: selected,
                        selectedColor: descriptor.color.withValues(alpha: 0.2),
                        onSelected: (_) => setDialogState(() => durationMinutes = minutes),
                      );
                    }).toList(),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: descriptor.color,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    await supabase.from('activity_entries').insert({
                      'patient_id': patientId,
                      'category': descriptor.activityDbCategory!.dbValue,
                      'rating': rating,
                      'duration_minutes': durationMinutes,
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
  notesController.dispose();
}
