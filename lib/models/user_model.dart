import 'dart:convert';

import '../core/enums.dart';

/// Represents a user (admin or employee) in the system.
class UserModel {
  final String id;
  final String employeeCode;
  final String fullName;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? token;

  const UserModel({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.token,
  });

  /// Returns user initials for avatar placeholder.
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? id,
    String? employeeCode,
    String? fullName,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
    );
  }

  // ── Serialization ───────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeecode': employeeCode,
      'fullname': fullName,
      'email': email,
      'role': role.name,
      'createdat': createdAt.toIso8601String(),
      'token': token,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      employeeCode: map['employeecode'] as String,
      fullName: map['fullname'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      createdAt: DateTime.parse(map['createdat'] as String),
      token: map['token'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'UserModel(id: $id, employeeCode: $employeeCode, fullName: $fullName, role: ${role.name})';
}
