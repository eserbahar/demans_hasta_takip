import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show supabase;
import '../models/patient.dart';
import 'log_today_screen.dart';

class PatientSelectionScreen extends StatefulWidget {
  const PatientSelectionScreen({super.key});

  @override
  State<PatientSelectionScreen> createState() => _PatientSelectionScreenState();
}

class _PatientSelectionScreenState extends State<PatientSelectionScreen> {
  List<RemotePatient> _patients = [];
  String? _errorMessage;
  bool _isLoading = true;

  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final birthDateController = TextEditingController();
    final conditionsController = TextEditingController();
    final emergencyContactController = TextEditingController();
    final caregiverNameController = TextEditingController();
    final notesController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Hasta Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad soyad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: birthDateController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Doğum tarihi (YYYY-AA-GG)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: conditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Rahatsızlıklar (virgülle ayırın)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emergencyContactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Acil iletişim (ad ve telefon)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: caregiverNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bakıcı adı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notlar',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final birthDateText = birthDateController.text.trim();
                    final birthDate = birthDateText.isEmpty
                        ? null
                        : DateTime.tryParse(birthDateText);

                    if (name.isEmpty) {
                      setDialogState(() => errorMessage = 'Ad soyad zorunludur.');
                      return;
                    }
                    if (birthDateText.isNotEmpty && birthDate == null) {
                      setDialogState(() => errorMessage = 'Doğum tarihi YYYY-AA-GG olmalı.');
                      return;
                    }

                    try {
                      final userId = supabase.auth.currentUser!.id;
                      final profile = await supabase
                          .from('profiles')
                          .select('role')
                          .eq('id', userId)
                          .single();
                      final emergencyContact = emergencyContactController.text.trim();
                      final caregiverName = caregiverNameController.text.trim();
                      final notes = notesController.text.trim();
                      final patient = await supabase.from('patients').insert({
                        'full_name': name,
                        'birth_date': birthDate?.toIso8601String().split('T').first,
                        'medical_conditions': conditionsController.text
                            .split(',')
                            .map((condition) => condition.trim())
                            .where((condition) => condition.isNotEmpty)
                            .toList(),
                        'emergency_contact': emergencyContact.isEmpty ? null : emergencyContact,
                        'caregiver_name': caregiverName.isEmpty ? null : caregiverName,
                        'notes': notes.isEmpty ? null : notes,
                        'created_by': userId,
                      }).select('id').single();
                      await supabase.from('patient_access').insert({
                        'patient_id': patient['id'],
                        'user_id': userId,
                        'role': profile['role'],
                        'granted_by': userId,
                      });
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadPatients();
                    } on PostgrestException catch (error) {
                      if (dialogContext.mounted) {
                        setDialogState(() => errorMessage = error.message);
                      }
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      birthDateController.dispose();
      conditionsController.dispose();
      emergencyContactController.dispose();
      caregiverNameController.dispose();
      notesController.dispose();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rows = await supabase
          .from('patients')
          .select(
            'id, full_name, birth_date, medical_conditions, emergency_contact, caregiver_name, notes',
          )
          .order('full_name');
      if (mounted) {
        setState(() {
          _patients = rows.map((row) => RemotePatient.fromMap(row)).toList();
          _isLoading = false;
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _isLoading = false;
        });
      }
    }
  }

  void _selectPatient(RemotePatient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogTodayScreen(selectedPatient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasta Seçimi'),
        actions: [
          IconButton(
            tooltip: 'Hasta ekle',
            onPressed: _showAddPatientDialog,
            icon: const Icon(Icons.person_add),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loadPatients,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Çıkış yap',
            onPressed: () => supabase.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Hastalar yüklenemedi: $_errorMessage'))
              : _patients.isEmpty
                  ? const Center(
                      child: Text('Bu kullanıcıya atanmış hasta bulunmuyor.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _patients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final patient = _patients[index];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              patient.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              [
                                patient.birthDate == null
                                    ? 'Doğum tarihi belirtilmedi'
                                    : 'Doğum: ${patient.birthDate!.day}.${patient.birthDate!.month}.${patient.birthDate!.year}',
                                if (patient.caregiverName != null &&
                                    patient.caregiverName!.isNotEmpty)
                                  'Bakıcı: ${patient.caregiverName}',
                              ].join(' • '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _selectPatient(patient),
                          ),
                        );
                      },
                    ),
    );
  }
}
