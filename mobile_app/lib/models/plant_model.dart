import 'package:cloud_firestore/cloud_firestore.dart';
class PlantModel {
  final String id;
  final String userId;
  final String name;
  final String species;
  final String? description;
  final DateTime plantedDate;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.description,
    required this.plantedDate,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'species': species,
      if (description != null) 'description': description,
      'plantedDate': plantedDate,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // ✅ Create from Firestore document
  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      description: map['description'],
      // 🔥 Firestore lưu DateTime thành Timestamp, không phải string
      plantedDate: (map['plantedDate'] is Timestamp)
          ? (map['plantedDate'] as Timestamp).toDate()
          : DateTime.parse(map['plantedDate']),
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt']),
    );
  }

  // CopyWith method
  PlantModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    String? description,
    DateTime? plantedDate,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      description: description ?? this.description,
      plantedDate: plantedDate ?? this.plantedDate,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate plant age in days
  int get ageInDays => DateTime.now().difference(plantedDate).inDays;
}
