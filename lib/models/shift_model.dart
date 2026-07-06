import 'dart:convert';

/// Represents a work shift schedule.
class ShiftModel {
  final String id;
  final String name;
  final String checkInTime;   // Format: "HH:mm"
  final String checkOutTime;  // Format: "HH:mm"
  final int lateToleranceMinutes;

  const ShiftModel({
    required this.id,
    required this.name,
    required this.checkInTime,
    required this.checkOutTime,
    required this.lateToleranceMinutes,
  });

  /// Display time range (e.g. "08:00 - 16:00").
  String get displayTime => '$checkInTime - $checkOutTime';

  /// Parse checkInTime to hour & minute.
  int get checkInHour => int.parse(checkInTime.split(':')[0]);
  int get checkInMinute => int.parse(checkInTime.split(':')[1]);

  /// Parse checkOutTime to hour & minute.
  int get checkOutHour => int.parse(checkOutTime.split(':')[0]);
  int get checkOutMinute => int.parse(checkOutTime.split(':')[1]);

  /// Whether a given [DateTime] counts as late for this shift.
  bool isLate(DateTime time) {
    final limitMinute = checkInMinute + lateToleranceMinutes;
    final limitHour = checkInHour + (limitMinute ~/ 60);
    final normalizedMinute = limitMinute % 60;

    if (time.hour > limitHour) return true;
    if (time.hour == limitHour && time.minute > normalizedMinute) return true;
    return false;
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  ShiftModel copyWith({
    String? id,
    String? name,
    String? checkInTime,
    String? checkOutTime,
    int? lateToleranceMinutes,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      lateToleranceMinutes: lateToleranceMinutes ?? this.lateToleranceMinutes,
    );
  }

  // ── Serialization ───────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'checkintime': checkInTime,
      'checkouttime': checkOutTime,
      'latetoleranceminutes': lateToleranceMinutes,
    };
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'] as String,
      name: map['name'] as String,
      checkInTime: map['checkintime'] as String,
      checkOutTime: map['checkouttime'] as String,
      lateToleranceMinutes: (map['latetoleranceminutes'] as num).toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ShiftModel.fromJson(String source) =>
      ShiftModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ShiftModel(id: $id, name: $name, time: $displayTime, tolerance: ${lateToleranceMinutes}min)';
}
