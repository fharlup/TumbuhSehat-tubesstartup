import 'package:equatable/equatable.dart';

class NutritionistModel extends Equatable {
  final String id;
  final String name;
  final String role;
  final String? photoUrl;
  final bool isOnline; // <--- Bagian ini yang sebelumnya hilang

  const NutritionistModel({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
    this.isOnline = false, // Default false
  });

  factory NutritionistModel.fromJson(Map<String, dynamic> json) {
    return NutritionistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      photoUrl: json['photo_url'],
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'photo_url': photoUrl,
      'is_online': isOnline,
    };
  }

  @override
  List<Object?> get props => [id, name, role, photoUrl, isOnline];
}