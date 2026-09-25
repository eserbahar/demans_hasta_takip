import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show supabase;
import '../../widgets/star_rating.dart';

/// Sıvı Alımı (Fluid) entry dialog — extends the pre-existing
/// type/amount/quick-chip flow with `StarRatingInput` + notes, per the
/// implementation plan ("İdrar Çıkışı"/"Sıvı Alımı" keep their precise
/// fields; rating and notes are added alongside).
Future<void> showFluidEntryDialog(
  BuildContext context, {
  required String patientId,
  required VoidCallback onSaved,
}) async {
  const color = Colors.blue;
  String selectedDrink = 'Su';
  final drinkOptions = ['Su', 'Çay', 'Meyve Suyu', 'Ayran', 'Çorba', 'Süt', 'Diğer'];
  final amountController = TextEditingController(text: '200');
  int rating = 3;
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
                Icon(Icons.local_drink, color: color),
                SizedBox(width: 8),
                Text('Sıvı Girişi Yap', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('İçecek Türü:',
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
                        value: selectedDrink,
                        isExpanded: true,
                        items: drinkOptions
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null) setDialogState(() => selectedDrink = newValue);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Miktar (ml):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffixText: 'ml',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [100, 150, 200, 250].map((ml) {
                      return ActionChip(
                        label: Text('$ml ml', style: const TextStyle(fontSize: 11)),
                        onPressed: () => setDialogState(() => amountController.text = ml.toString()),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
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
                  final amount = int.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    setDialogState(() => errorMessage = 'Lütfen geçerli bir miktar girin.');
                    return;
                  }
                  try {
                    await supabase.from('fluid_entries').insert({
                      'patient_id': patientId,
                      'amount_ml': amount,
                      'type': selectedDrink,
                      'rating': rating,
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
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      );
    },
  );
  amountController.dispose();
  notesController.dispose();
}
