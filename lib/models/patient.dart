/// In-memory patient profile used for display in the app bar / dialogs.
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

/// Supabase-backed patient row from the `patients` table.
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
