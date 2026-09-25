import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show supabase;
import '../../widgets/star_rating.dart';

/// Dışkılama (Bowel) entry dialog.
/// Fields: star rating + consistency dropdown + notes.
/// *(exact UI TBD from user per the implementation plan — placeholder.)*
Future<void> showBowelEntryDialog(
  BuildContext context, {
  required String patientId,
  required VoidCallback onSaved,
}) async {
  const color = Color(0xFF8B6449);
  int rating = 3;
  String consistency = 'Normal';
  final consistencyOptions = ['Sert', 'Normal', 'Yumuşak', 'Sulu'];
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
                Icon(Icons.hourglass_bottom, color: color),
                SizedBox(width: 8),
                Text('Dışkılama Girişi', style: TextStyle(fontSize: 18)),
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
                    color: color,
                    onChanged: (value) => setDialogState(() => rating = value),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kıvam:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: consistency,
                        isExpanded: true,
                        items: consistencyOptions
                            .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => consistency = value);
                        },
                      ),
                    ),
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
                  try {
                    await supabase.from('bowel_entries').insert({
                      'patient_id': patientId,
                      'rating': rating,
                      'consistency': consistency,
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
