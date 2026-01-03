import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// Model untuk user
@HiveType(typeId: 2)
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String? fullName;

  @HiveField(3)
  final String? gender; // 'L' untuk Laki-laki, 'P' untuk Perempuan

  @HiveField(4)
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.gender,
    required this.createdAt,
  });

  /// Sapaan berdasarkan gender
  String get sapaan {
    if (gender == 'P') return 'Ukhti';
    return 'Akhi';
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON (Supabase response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  String toString() => 'UserModel(id: $id, username: $username)';
}
