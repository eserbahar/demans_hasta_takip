import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
);

const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'YOUR_PUBLISHABLE_KEY',
);

final supabase = Supabase.instance.client;
String supabaseConnectionStatus = 'Kontrol ediliyor...';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const Demans1App());
}

class Demans1App extends StatelessWidget {
  const Demans1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demans 1 - Bakım Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0288D1),
          primary: const Color(0xFF0288D1),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession == null) {
          return const LoginScreen();
        }
        return const PatientSelectionScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'E-posta ve şifre zorunludur.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.health_and_safety, size: 48, color: Color(0xFF0288D1)),
                  const SizedBox(height: 12),
                  const Text(
                    'Demans Hasta Takip',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onSubmitted: (_) => _signIn(),
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Giriş Yap'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Hasta Veri Modeli
class PatientProfile {
  String name;
  DateTime birthDate;
  List<String> medicalConditions;

  PatientProfile({
    required this.name,
    required this.birthDate,
    required this.medicalConditions,
  });

  int get age {
    final today = DateTime.now();
    int calculatedAge = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }
}

class RemotePatient {
  final String id;
  final String fullName;
  final DateTime? birthDate;
  final List<String> medicalConditions;
  final String? emergencyContact;
  final String? caregiverName;
  final String? notes;

  const RemotePatient({
    required this.id,
    required this.fullName,
    required this.birthDate,
    required this.medicalConditions,
    this.emergencyContact,
    this.caregiverName,
    this.notes,
  });

  factory RemotePatient.fromMap(Map<String, dynamic> map) {
    return RemotePatient(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      birthDate: map['birth_date'] == null
          ? null
          : DateTime.tryParse(map['birth_date'] as String),
      medicalConditions: (map['medical_conditions'] as List<dynamic>? ?? [])
          .map((condition) => condition.toString())
          .toList(),
      emergencyContact: map['emergency_contact'] as String?,
      caregiverName: map['caregiver_name'] as String?,
      notes: map['notes'] as String?,
    );
  }
}

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String timeSlot;
  final String plannedTime;
  bool isTaken;
  String? takenTime;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timeSlot,
    required this.plannedTime,
    this.isTaken = false,
    this.takenTime,
  });
}

class ActivityLog {
  final String time;
  final String title;
  final String category;
  final Color color;
  final IconData icon;

  ActivityLog({
    required this.time,
    required this.title,
    required this.category,
    required this.color,
    required this.icon,
  });
}

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
        builder: (_) => DashboardScreen(selectedPatient: patient),
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

class DashboardScreen extends StatefulWidget {
  final RemotePatient? selectedPatient;

  const DashboardScreen({super.key, this.selectedPatient});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final selectedPatient = widget.selectedPatient;
    _patient = PatientProfile(
      name: selectedPatient?.fullName ?? 'Ayşe Turan',
      birthDate: selectedPatient?.birthDate ?? DateTime(1948, 5, 14),
      medicalConditions: selectedPatient?.medicalConditions ??
          ['Alzheimer / Demans', 'Hipertansiyon'],
    );
    _loadProfileConnectionStatus();
    _loadMedications().then((_) => _loadDailyTracking());
  }

  Future<void> _loadMedications() async {
    final patientId = widget.selectedPatient?.id;
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

  Future<void> _loadDailyTracking() async {
    final patientId = widget.selectedPatient?.id;
    if (patientId == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1)
        .toUtc()
        .toIso8601String();

    try {
      final fluidRows = await supabase
          .from('fluid_entries')
          .select('amount_ml')
          .eq('patient_id', patientId)
          .gte('logged_at', startOfDay)
          .lt('logged_at', startOfTomorrow);
      final urineRows = await supabase
          .from('urine_entries')
          .select('amount_ml, status, logged_at')
          .eq('patient_id', patientId)
          .gte('logged_at', startOfDay)
          .lt('logged_at', startOfTomorrow)
          .order('logged_at', ascending: false);
      final medicationRows = await supabase
          .from('medication_logs')
          .select('medication_id, status, logged_at')
          .eq('patient_id', patientId)
          .gte('logged_at', startOfDay)
          .lt('logged_at', startOfTomorrow)
          .order('logged_at', ascending: false);

      final fluidTotal = fluidRows.fold<int>(
        0,
        (total, row) => total + (row['amount_ml'] as int),
      );
      final urineTotal = urineRows.fold<int>(
        0,
        (total, row) => total + (row['amount_ml'] as int),
      );
      final latestUrine = urineRows.isEmpty ? null : urineRows.first;
      final takenMedicationIds = medicationRows
          .where((row) => row['status'] == 'taken')
          .map((row) => row['medication_id'] as String)
          .toSet();

      if (mounted) {
        setState(() {
          _currentFluidMl = fluidTotal;
          _currentUrineMl = urineTotal;
          _showFluidWarning = fluidTotal == 0;
          if (latestUrine != null) {
            final loggedAt = DateTime.parse(latestUrine['logged_at'] as String)
                .toLocal();
            _lastUrineTime =
                '${loggedAt.hour.toString().padLeft(2, '0')}:${loggedAt.minute.toString().padLeft(2, '0')} (${latestUrine['status']})';
          }
          for (final medication in _medications) {
            medication.isTaken = takenMedicationIds.contains(medication.id);
          }
        });
      }
    } on PostgrestException catch (error) {
      debugPrint('Günlük takip verileri yüklenemedi: ${error.message}');
    }
  }

  Future<void> _loadProfileConnectionStatus() async {
    try {
      final profiles = await supabase
          .from('profiles')
          .select('id')
          .eq('id', supabase.auth.currentUser!.id)
          .limit(1);
      if (mounted) {
        setState(() {
          supabaseConnectionStatus =
              'Bağlantı başarılı: ${profiles.length} profil bulundu.';
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          supabaseConnectionStatus = 'Bağlantı hatası: ${error.message}';
        });
      }
    }
  }

  // 👤 Hasta Profil Bilgileri
  late PatientProfile _patient;

  int _targetFluidMl = 2000;
  int _targetUrineMl = 1500;

  int _currentFluidMl = 1200;
  int _currentUrineMl = 200;
  String _lastUrineTime = '10:15 (Normal)';
  bool _showFluidWarning = true;

  List<Medication> _medications = [];

  final List<ActivityLog> _logs = [
    ActivityLog(
      time: '08:00',
      title: 'Donepezil 10mg İlacı Verildi',
      category: 'medication',
      color: Colors.green,
      icon: Icons.medication,
    ),
    ActivityLog(
      time: '08:30',
      title: '+200 ml Su İçildi',
      category: 'fluid',
      color: Colors.blue,
      icon: Icons.water_drop,
    ),
    ActivityLog(
      time: '10:15',
      title: 'İdrar Çıkışı (Normal) - 200 ml',
      category: 'toilet',
      color: Colors.orange,
      icon: Icons.wc,
    ),
  ];

  void _addLog(String title, String category, Color color, IconData icon) {
    final now = TimeOfDay.now();
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    setState(() {
      _logs.add(
        ActivityLog(
          time: formattedTime,
          title: title,
          category: category,
          color: color,
          icon: icon,
        ),
      );
    });
  }

  // 👤 SAĞ ÜST İKONDAN ERİŞİLEN HASTA PROFİL DÜZENLEME PENCERESİ
  void _showPatientProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: _patient.name);
    final TextEditingController conditionController = TextEditingController();
    DateTime selectedDate = _patient.birthDate;
    List<String> tempConditions = List.from(_patient.medicalConditions);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final today = DateTime.now();
            int calculatedAge = today.year - selectedDate.year;
            if (today.month < selectedDate.month ||
                (today.month == selectedDate.month && today.day < selectedDate.day)) {
              calculatedAge--;
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person_pin, color: Color(0xFF0288D1), size: 28),
                          SizedBox(width: 8),
                          Text('Hasta Profil Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Hasta Adı Soyadı',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              ),
                              icon: const Icon(Icons.calendar_month, size: 18),
                              label: Text(
                                '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(1920),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0288D1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.3)),
                            ),
                            child: Text(
                              'Yaş: $calculatedAge',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0288D1)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Bilinen Rahatsızlıklar / Kronik Hastalıklar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tempConditions.map((cond) {
                          return Chip(
                            label: Text(cond, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setDialogState(() {
                                tempConditions.remove(cond);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: conditionController,
                              decoration: const InputDecoration(
                                hintText: 'Örn: Diyabet, Artrit...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), foregroundColor: Colors.white),
                            onPressed: () {
                              if (conditionController.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  tempConditions.add(conditionController.text.trim());
                                  conditionController.clear();
                                });
                              }
                            },
                            child: const Text('Ekle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('İptal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), foregroundColor: Colors.white),
                            onPressed: () {
                              if (nameController.text.trim().isNotEmpty) {
                                setState(() {
                                  _patient.name = nameController.text.trim();
                                  _patient.birthDate = selectedDate;
                                  _patient.medicalConditions = tempConditions;
                                });
                                Navigator.pop(dialogCtx);
                              }
                            },
                            child: const Text('Kaydet'),
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

  Future<void> _toggleMedication(Medication med) async {
    final now = TimeOfDay.now();
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (!med.isTaken) {
      final patientId = widget.selectedPatient?.id;
      if (patientId == null) return;
      try {
        await supabase.from('medication_logs').insert({
          'patient_id': patientId,
          'medication_id': med.id,
          'status': 'taken',
          'logged_at': DateTime.now().toUtc().toIso8601String(),
          'logged_by': supabase.auth.currentUser!.id,
        });
        if (mounted) {
          setState(() {
            med.isTaken = true;
            med.takenTime = formattedTime;
            _addLog('${med.name} ${med.dosage} İlacı Verildi', 'medication', Colors.green, Icons.medication);
          });
        }
      } on PostgrestException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
        }
      }
    } else {
      showDialog(
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
              '${med.name} (${med.dosage}) ilacı verildi olarak işaretlenmişti.\n\nBu kaydı iptal edip verilmedi olarak değiştirmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () async {
                  final patientId = widget.selectedPatient?.id;
                  if (patientId == null) return;
                  try {
                    await supabase.from('medication_logs').insert({
                      'patient_id': patientId,
                      'medication_id': med.id,
                      'status': 'cancelled',
                      'logged_at': DateTime.now().toUtc().toIso8601String(),
                      'logged_by': supabase.auth.currentUser!.id,
                    });
                    if (!dialogCtx.mounted) return;
                    setState(() {
                      med.isTaken = false;
                      med.takenTime = null;
                      _logs.removeWhere((log) =>
                          log.category == 'medication' && log.title.contains(med.name));
                    });
                    Navigator.pop(dialogCtx);
                  } on PostgrestException catch (error) {
                    if (dialogCtx.mounted) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                    }
                  }
                },
                child: const Text('Evet, İptal Et'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showTargetSettingsDialog() {
    final TextEditingController fluidTargetController = TextEditingController(text: _targetFluidMl.toString());
    final TextEditingController urineTargetController = TextEditingController(text: _targetUrineMl.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune, color: Color(0xFF0288D1)),
              SizedBox(width: 8),
              Text('Günlük Hedef Ayarları', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('İdeal Sıvı Hedefi (ml):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: fluidTargetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  suffixText: 'ml',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              const Text('İdeal İdrar Hedefi (ml):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: urineTargetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  suffixText: 'ml',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), foregroundColor: Colors.white),
              onPressed: () {
                final int? fluid = int.tryParse(fluidTargetController.text);
                final int? urine = int.tryParse(urineTargetController.text);

                if (fluid != null && fluid > 0 && urine != null && urine > 0) {
                  setState(() {
                    _targetFluidMl = fluid;
                    _targetUrineMl = urine;
                  });
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _showMedicationManagerDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController timeController = TextEditingController(text: '09:00');
    String selectedTimeSlot = 'Sabah';
    final List<String> timeSlots = ['Sabah', 'Öğle', 'Akşam', 'Gece'];

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
                      Row(
                        children: const [
                          Icon(Icons.medication_liquid, color: Color(0xFF0288D1)),
                          SizedBox(width: 8),
                          Text('İlaç Yönetimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Mevcut İlaçlar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Container(
                        height: 130,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _medications.isEmpty
                            ? const Center(child: Text('Tanımlı ilaç yok', style: TextStyle(fontSize: 12, color: Colors.grey)))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _medications.length,
                                itemBuilder: (ctx, index) {
                                  final med = _medications[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text('${med.name} (${med.dosage})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${med.timeSlot} - ${med.plannedTime}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _medications.removeAt(index);
                                        });
                                        setDialogState(() {});
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 24),
                      const Text('Yeni İlaç Ekle:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0288D1))),
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
                        value: selectedTimeSlot,
                        decoration: const InputDecoration(
                          labelText: 'Öğün / Zaman',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: timeSlots.map((slot) {
                          return DropdownMenuItem(value: slot, child: Text(slot));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedTimeSlot = val;
                            });
                          }
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
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), foregroundColor: Colors.white),
                            onPressed: () async {
                              final patientId = widget.selectedPatient?.id;
                              final name = nameController.text.trim();
                              final dosage = dosageController.text.trim().isEmpty
                                  ? '1 Doz'
                                  : dosageController.text.trim();
                              final plannedTime = timeController.text.trim().isEmpty
                                  ? '09:00'
                                  : timeController.text.trim();

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
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    SnackBar(content: Text(error.message)),
                                  );
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

  Future<void> _insertFluidEntry(int amount, String type) async {
    final patientId = widget.selectedPatient?.id;
    if (patientId == null) return;
    await supabase.from('fluid_entries').insert({
      'patient_id': patientId,
      'amount_ml': amount,
      'type': type,
      'logged_by': supabase.auth.currentUser!.id,
    });
  }

  Future<void> _insertUrineEntry(int amount, String status) async {
    final patientId = widget.selectedPatient?.id;
    if (patientId == null) return;
    await supabase.from('urine_entries').insert({
      'patient_id': patientId,
      'amount_ml': amount,
      'status': status,
      'logged_by': supabase.auth.currentUser!.id,
    });
  }

  void _showFluidAddDialog([BuildContext? sheetContext]) {
    String selectedDrink = 'Su';
    final List<String> drinkOptions = ['Su', 'Çay', 'Meyve Suyu', 'Ayran', 'Çorba', 'Süt', 'Diğer'];
    final TextEditingController amountController = TextEditingController(text: '200');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.local_drink, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Sıvı Girişi Yap', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('İçecek Türü:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
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
                        items: drinkOptions.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedDrink = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Miktar (ml):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
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
                        onPressed: () {
                          setDialogState(() {
                            amountController.text = ml.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () async {
                    final int? amount = int.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      try {
                        await _insertFluidEntry(amount, selectedDrink);
                        if (!dialogCtx.mounted) return;
                        setState(() {
                          _currentFluidMl += amount;
                          _showFluidWarning = false;
                        });
                        _addLog('+$amount ml $selectedDrink İçildi', 'fluid', Colors.blue, Icons.water_drop);
                        Navigator.pop(dialogCtx);
                        if (sheetContext != null && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      } on PostgrestException catch (error) {
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      }
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
  }

  void _showUrineAddDialog(BuildContext sheetContext) {
    String selectedStatus = 'Normal';
    final List<String> statusOptions = [
      'Normal',
      'Az / Koyu',
      'Bol / Berrak',
      'Damla Damla',
      'Sıkıştırma / Kaçırma'
    ];
    final TextEditingController amountController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.wc, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('İdrar / Tuvalet Girişi', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('1. Miktar (ml):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      Text(' *Zorunlu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      if (errorMessage != null && val.trim().isNotEmpty) {
                        setDialogState(() {
                          errorMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Örn: 150',
                      suffixText: 'ml',
                      errorText: errorMessage,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [100, 150, 200, 250].map((ml) {
                      return ActionChip(
                        label: Text('$ml ml', style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setDialogState(() {
                            amountController.text = ml.toString();
                            errorMessage = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('2. İdrar Tipi / Durumu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items: statusOptions.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedStatus = newValue;
                            });
                          }
                        },
                      ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: () async {
                    final int? amount = int.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      setDialogState(() {
                        errorMessage = 'Lütfen miktar girin veya seçin';
                      });
                      return;
                    }

                    final now = TimeOfDay.now();
                    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                    
                    final String title = 'İdrar Çıkışı ($selectedStatus) - $amount ml';

                    try {
                      await _insertUrineEntry(amount, selectedStatus);
                      if (!dialogCtx.mounted) return;
                      setState(() {
                        _currentUrineMl += amount;
                        _lastUrineTime = '$formattedTime ($selectedStatus)';
                      });
                      _addLog(title, 'toilet', Colors.orange, Icons.wc);

                      Navigator.pop(dialogCtx);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    } on PostgrestException catch (error) {
                      if (dialogCtx.mounted) {
                        setDialogState(() => errorMessage = error.message);
                      }
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
  }

  void _showAddEntrySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hızlı Kayıt Ekle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showMedicationManagerDialog();
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('İlaçları Yönet'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('İlaç Takibi', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _medications.where((m) => !m.isTaken).map((med) {
                  return _buildQuickActionButton(
                    icon: Icons.medication,
                    label: '${med.name} (${med.timeSlot})',
                    color: Colors.green,
                    onTap: () {
                      _toggleMedication(med);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              if (_medications.every((m) => m.isTaken))
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text('Tüm günlük ilaçlar verildi 👍', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              const SizedBox(height: 16),

              const Text('Sıvı Alımı', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.local_drink,
                    label: '+200 ml Su',
                    color: Colors.blue,
                    onTap: () async {
                      try {
                        await _insertFluidEntry(200, 'Su');
                        if (!ctx.mounted) return;
                        setState(() {
                          _currentFluidMl += 200;
                          _showFluidWarning = false;
                        });
                        _addLog('+200 ml Su İçildi', 'fluid', Colors.blue, Icons.water_drop);
                        Navigator.pop(ctx);
                      } on PostgrestException catch (error) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      }
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.list_alt,
                    label: 'Detaylı Sıvı Seç',
                    color: Colors.indigo,
                    onTap: () => _showFluidAddDialog(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Boşaltım / Tuvalet', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.wc,
                    label: 'İdrar Ekle (Miktar & Tip)',
                    color: Colors.orange,
                    onTap: () => _showUrineAddDialog(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: supabaseConnectionStatus.startsWith('Bağlantı başarılı')
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: ListTile(
              leading: Icon(
                supabaseConnectionStatus.startsWith('Bağlantı başarılı')
                    ? Icons.cloud_done
                    : Icons.cloud_off,
                color: supabaseConnectionStatus.startsWith('Bağlantı başarılı')
                    ? Colors.green
                    : Colors.orange,
              ),
              title: const Text('Supabase bağlantısı'),
              subtitle: Text(supabaseConnectionStatus),
            ),
          ),
          if (_showFluidWarning)
            Card(
              color: const Color(0xFFFFEBEE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFEF5350), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SIVI ALARMI', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                          Text('3 saattir sıvı girişi yapılmadı!', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _showFluidAddDialog();
                      },
                      child: const Text('Su Ver'),
                    )
                  ],
                ),
              ),
            ),
          if (_showFluidWarning) const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('İLAÇ DÜZENİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              InkWell(
                onTap: _showMedicationManagerDialog,
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF0288D1)),
                    SizedBox(width: 4),
                    Text('İlaç Ekle / Düzenle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0288D1))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_medications.isEmpty)
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('Tanımlı ilaç bulunmuyor. Üstten ekleyebilirsiniz.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ),
            )
          else
            Column(
              children: _medications.map((med) {
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      Icons.medication,
                      color: med.isTaken ? Colors.green : const Color(0xFF0288D1),
                      size: 36,
                    ),
                    title: Text(
                      '${med.name} ${med.dosage}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: med.isTaken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      '${med.timeSlot} Dozu - ${med.plannedTime}${med.takenTime != null ? " (Verildi: ${med.takenTime})" : ""}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: med.isTaken ? Colors.green : const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _toggleMedication(med),
                      icon: Icon(med.isTaken ? Icons.check : Icons.touch_app),
                      label: Text(med.isTaken ? 'Verildi' : 'İlacı Ver'),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SIVI & BOŞALTIM TAKİBİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              InkWell(
                onTap: _showTargetSettingsDialog,
                child: const Row(
                  children: [
                    Icon(Icons.tune, size: 16, color: Color(0xFF0288D1)),
                    SizedBox(width: 4),
                    Text('Hedefleri Değiştir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0288D1))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children: [Icon(Icons.water_drop, color: Colors.blue), SizedBox(width: 8), Text('Sıvı Alımı', style: TextStyle(fontWeight: FontWeight.bold))]),
                      Text('$_currentFluidMl / $_targetFluidMl ml', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentFluidMl / _targetFluidMl).clamp(0.0, 1.0),
                    backgroundColor: Colors.blue[50],
                    color: Colors.blue,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),

                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [const Icon(Icons.wc, color: Colors.orange), const SizedBox(width: 8), Text('Çıkan İdrar ($_lastUrineTime)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))]),
                      Text('$_currentUrineMl / $_targetUrineMl ml', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentUrineMl / _targetUrineMl).clamp(0.0, 1.0),
                    backgroundColor: Colors.orange[50],
                    color: Colors.orange,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<ActivityLog> items,
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const Divider(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Henüz kayıt yok.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              Column(
                children: items.map((log) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(log.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        Text(
                          log.time,
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _buildJournalScreen() {
    final medLogs = _logs.where((l) => l.category == 'medication').toList();
    final fluidLogs = _logs.where((l) => l.category == 'fluid').toList();
    final toiletLogs = _logs.where((l) => l.category == 'toilet').toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildCategorySection(
          title: '💊 İlaç Takibi',
          icon: Icons.medication,
          color: Colors.green,
          items: medLogs,
        ),
        _buildCategorySection(
          title: '💧 Sıvı Alım Geçmişi',
          icon: Icons.water_drop,
          color: Colors.blue,
          items: fluidLogs,
        ),
        _buildCategorySection(
          title: '🚽 Boşaltım / Tuvalet Geçmişi',
          icon: Icons.wc,
          color: Colors.orange,
          items: toiletLogs,
        ),
      ],
    );
  }

  // 📊 YENİ HASTALIK VE YAŞ BİLGİSİ İÇEREN RAPORLAR EKRANI
  Widget _buildReportsScreen() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 🏥 Hasta Medikal Künyesi
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.assignment_ind, color: Color(0xFF0288D1), size: 24),
                    SizedBox(width: 8),
                    Text('Hasta Medikal Özeti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hasta Adı Soyadı:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    Text(_patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Yaş / Doğum Tarihi:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    Text(
                      '${_patient.age} Yaş (${_patient.birthDate.day}.${_patient.birthDate.month}.${_patient.birthDate.year})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Bilinen Rahatsızlıklar:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                _patient.medicalConditions.isEmpty
                    ? const Text('Tanımlı hastalık bulunmuyor.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _patient.medicalConditions.map((cond) {
                          return Chip(
                            backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                            side: BorderSide.none,
                            label: Text(cond, style: const TextStyle(fontSize: 12, color: Color(0xFF0288D1), fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 📈 Günlük İstatistik Kartı
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.bar_chart, color: Colors.green, size: 24),
                    SizedBox(width: 8),
                    Text('Günlük İstatistikler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tamamlanan İlaç Oranı'),
                  trailing: Text(
                    '${_medications.where((m) => m.isTaken).length} / ${_medications.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sıvı Dengesi (İçilen / Çıkan)'),
                  trailing: Text(
                    '$_currentFluidMl ml / $_currentUrineMl ml',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📌 Tüm sayfalardaki üst bar isim yakınına yaş bilgisi eklendi
            Text('Hasta: ${_patient.name} (${_patient.age})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _selectedIndex == 0 
                  ? 'Demans Takip Modu' 
                  : _selectedIndex == 1 
                      ? 'Bugünün Bakım Günlüğü' 
                      : 'Hasta Rapor & Medikal Özet',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Color(0xFF0288D1)),
            tooltip: 'Hasta değiştir',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientSelectionScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28, color: Color(0xFF0288D1)),
            tooltip: 'Hasta Profili',
            onPressed: _showPatientProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 26, color: Color(0xFF0288D1)),
            tooltip: 'Hedef Ayarları',
            onPressed: _showTargetSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.medication_liquid, size: 28, color: Color(0xFF0288D1)),
            tooltip: 'İlaç Yönetimi',
            onPressed: _showMedicationManagerDialog,
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      
      body: _selectedIndex == 0 
          ? _buildHomeScreen() 
          : _selectedIndex == 1 
              ? _buildJournalScreen() 
              : _buildReportsScreen(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            _showAddEntrySheet();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        selectedItemColor: const Color(0xFF0288D1),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Günlük'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 42, color: Color(0xFF0288D1)), label: 'Ekle'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Raporlar'),
        ],
      ),
    );
  }
}