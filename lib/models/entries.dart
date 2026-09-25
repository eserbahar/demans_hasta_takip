/// Models mirroring the new/extended Supabase tables from
/// `supabase/migrations/002_activity_tracking.sql`. Each has a `fromMap`
/// factory (mirroring `RemotePatient.fromMap`) and a `toInsertMap` helper
/// for writing new rows.
library;

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value as String)?.toLocal();
}

class FluidEntry {
  final String id;
  final int amountMl;
  final String type;
  final int? rating;
  final String? notes;
  final DateTime? loggedAt;

  const FluidEntry({
    required this.id,
    required this.amountMl,
    required this.type,
    this.rating,
    this.notes,
    this.loggedAt,
  });

  factory FluidEntry.fromMap(Map<String, dynamic> map) {
    return FluidEntry(
      id: map['id'] as String,
      amountMl: map['amount_ml'] as int,
      type: map['type'] as String,
      rating: map['rating'] as int?,
      notes: map['notes'] as String?,
      loggedAt: _parseTimestamp(map['logged_at']),
    );
  }
}

class UrineEntry {
  final String id;
  final int amountMl;
  final String status;
  final int? rating;
  final String? notes;
  final DateTime? loggedAt;

  const UrineEntry({
    required this.id,
    required this.amountMl,
    required this.status,
    this.rating,
    this.notes,
    this.loggedAt,
  });

  factory UrineEntry.fromMap(Map<String, dynamic> map) {
    return UrineEntry(
      id: map['id'] as String,
      amountMl: map['amount_ml'] as int,
      status: map['status'] as String,
      rating: map['rating'] as int?,
      notes: map['notes'] as String?,
      loggedAt: _parseTimestamp(map['logged_at']),
    );
  }
}

class NutritionEntry {
  final String id;
  final int rating;
  final String? mealType;
  final int? portionPercent;
  final String? notes;
  final DateTime? loggedAt;

  const NutritionEntry({
    required this.id,
    required this.rating,
    this.mealType,
    this.portionPercent,
    this.notes,
    this.loggedAt,
  });

  factory NutritionEntry.fromMap(Map<String, dynamic> map) {
    return NutritionEntry(
      id: map['id'] as String,
      rating: map['rating'] as int,
      mealType: map['meal_type'] as String?,
      portionPercent: map['portion_percent'] as int?,
      notes: map['notes'] as String?,
      loggedAt: _parseTimestamp(map['logged_at']),
    );
  }
}

class BowelEntry {
  final String id;
  final int rating;
  final String? consistency;
  final String? notes;
  final DateTime? loggedAt;

  const BowelEntry({
    required this.id,
    required this.rating,
    this.consistency,
    this.notes,
    this.loggedAt,
  });

  factory BowelEntry.fromMap(Map<String, dynamic> map) {
    return BowelEntry(
      id: map['id'] as String,
      rating: map['rating'] as int,
      consistency: map['consistency'] as String?,
      notes: map['notes'] as String?,
      loggedAt: _parseTimestamp(map['logged_at']),
    );
  }
}

/// Shared by the Fiziksel / Zihinsel / Sosyal tiles — one table
/// (`activity_entries`), distinguished by the `category` column.
enum ActivityCategory { physical, mental, social }

extension ActivityCategoryDb on ActivityCategory {
  String get dbValue => name;

  static ActivityCategory fromDb(String value) {
    return ActivityCategory.values.firstWhere(
      (category) => category.dbValue == value,
      orElse: () => ActivityCategory.physical,
    );
  }
}

class ActivityEntry {
  final String id;
  final ActivityCategory category;
  final int rating;
  final int? durationMinutes;
  final String? notes;
  final DateTime? loggedAt;

  const ActivityEntry({
    required this.id,
    required this.category,
    required this.rating,
    this.durationMinutes,
    this.notes,
    this.loggedAt,
  });

  factory ActivityEntry.fromMap(Map<String, dynamic> map) {
    return ActivityEntry(
      id: map['id'] as String,
      category: ActivityCategoryDb.fromDb(map['category'] as String),
      rating: map['rating'] as int,
      durationMinutes: map['duration_minutes'] as int?,
      notes: map['notes'] as String?,
      loggedAt: _parseTimestamp(map['logged_at']),
    );
  }
}

class VitalsEntry {
  final String id;
  final int rating;
  final double? temperatureC;
  final int? pulseBpm;
  final int? bpSystolic;
  final int? bpDiastolic;
  final String? notes;
  final DateTime? loggedAt;

  const VitalsEntry({
    required this.id,
    required this.rating,
    this.temperatureC,
    this.pulseBpm,
    this.bpSystolic,
    this.bpDiastolic,
    this.notes,
    this.loggedAt,
  });

  factory VitalsEntry.fromMap(Map<String, dynamic> map) {
    return VitalsEntry(
      id: map['id'] as String,
      rating: map['rating'] as int,
      temperatureC: (map['temperature_c'] as num?)?.toDouble(),
      pulseBpm: map['pulse_bpm'] as int?,
      bpSystolic: map['bp_systolic'] as int?,
      bpDiastolic: map['bp_diastolic'] as int?,
      notes: map['notes'] as String?,
      loggedAt: _parseTimestamp(map['logged_at']),
    );
  }

  /// e.g. "38.5°C · Nb 72 · TA 120/80" for the tile's filled state.
  String get summary {
    final parts = <String>[];
    if (temperatureC != null) parts.add('${temperatureC!.toStringAsFixed(1)}°C');
    if (pulseBpm != null) parts.add('Nb $pulseBpm');
    if (bpSystolic != null && bpDiastolic != null) {
      parts.add('TA $bpSystolic/$bpDiastolic');
    }
    return parts.join(' · ');
  }
}
