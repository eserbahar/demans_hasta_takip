import 'package:flutter/material.dart';

void main() {
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
      home: const DashboardScreen(),
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // 👤 Hasta Profil Bilgileri
  final PatientProfile _patient = PatientProfile(
    name: 'Ayşe Turan',
    birthDate: DateTime(1948, 5, 14),
    medicalConditions: ['Alzheimer / Demans', 'Hipertansiyon'],
  );

  int _targetFluidMl = 2000;
  int _targetUrineMl = 1500;

  int _currentFluidMl = 1200;
  int _currentUrineMl = 200;
  String _lastUrineTime = '10:15 (Normal)';
  bool _showFluidWarning = true;

  final List<Medication> _medications = [
    Medication(
      id: 'med1',
      name: 'Donepezil',
      dosage: '10mg',
      timeSlot: 'Sabah',
      plannedTime: '08:00',
      isTaken: true,
      takenTime: '08:00',
    ),
    Medication(
      id: 'med2',
      name: 'Memantin',
      dosage: '10mg',
      timeSlot: 'Öğle',
      plannedTime: '13:00',
      isTaken: false,
    ),
    Medication(
      id: 'med3',
      name: 'Tansiyon İlacı',
      dosage: '5mg',
      timeSlot: 'Akşam',
      plannedTime: '20:00',
      isTaken: false,
    ),
  ];

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

  void _toggleMedication(Medication med) {
    final now = TimeOfDay.now();
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (!med.isTaken) {
      setState(() {
        med.isTaken = true;
        med.takenTime = formattedTime;
        _addLog('${med.name} ${med.dosage} İlacı Verildi', 'medication', Colors.green, Icons.medication);
      });
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
                onPressed: () {
                  setState(() {
                    med.isTaken = false;
                    med.takenTime = null;
                    _logs.removeWhere((log) => 
                      log.category == 'medication' && log.title.contains(med.name)
                    );
                  });
                  Navigator.pop(dialogCtx);
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
                            onPressed: () {
                              if (nameController.text.trim().isNotEmpty) {
                                setState(() {
                                  _medications.add(
                                    Medication(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      name: nameController.text.trim(),
                                      dosage: dosageController.text.trim().isEmpty ? '1 Doz' : dosageController.text.trim(),
                                      timeSlot: selectedTimeSlot,
                                      plannedTime: timeController.text.trim().isEmpty ? '09:00' : timeController.text.trim(),
                                    ),
                                  );
                                });
                                nameController.clear();
                                dosageController.clear();
                                setDialogState(() {});
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
                  onPressed: () {
                    final int? amount = int.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      setState(() {
                        _currentFluidMl += amount;
                        _showFluidWarning = false;
                      });
                      _addLog('+$amount ml $selectedDrink İçildi', 'fluid', Colors.blue, Icons.water_drop);
                      Navigator.pop(dialogCtx);
                      if (sheetContext != null) {
                        Navigator.pop(sheetContext);
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
                  onPressed: () {
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

                    setState(() {
                      _currentUrineMl += amount;
                      _lastUrineTime = '$formattedTime ($selectedStatus)';
                    });
                    _addLog(title, 'toilet', Colors.orange, Icons.wc);
                    
                    Navigator.pop(dialogCtx);
                    Navigator.pop(sheetContext);
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
                    onTap: () {
                      setState(() {
                        _currentFluidMl += 200;
                        _showFluidWarning = false;
                      });
                      _addLog('+200 ml Su İçildi', 'fluid', Colors.blue, Icons.water_drop);
                      Navigator.pop(ctx);
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