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
