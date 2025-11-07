import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntryModel {
  final String id;
  final String plantId;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final String activityType; // watering, fertilizing, pruning, observation
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntryModel({
    required this.id,
    required this.plantId,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.activityType,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'activityType': activityType,
      'createdAt': Timestamp.fromDate(createdAt), // ✅ Sửa: Dùng Timestamp
      'updatedAt': Timestamp.fromDate(updatedAt), // ✅ Sửa: Dùng Timestamp
    };
  }

  // Create from Firestore document
  factory DiaryEntryModel.fromMap(Map<String, dynamic> map) {
    return DiaryEntryModel(
      id: map['id'] ?? '',
      plantId: map['plantId'] ?? '',
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      activityType: map['activityType'] ?? 'observation',
      // ✅ Sửa: Đọc Timestamp từ Firestore và chuyển về DateTime
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  // CopyWith method
  DiaryEntryModel copyWith({
    String? id,
    String? plantId,
    String? userId,
    String? content,
    List<String>? imageUrls,
    String? activityType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntryModel(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      activityType: activityType ?? this.activityType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Activity Types Enum
class ActivityType {
  static const String watering = 'watering';
  static const String fertilizing = 'fertilizing';
  static const String pruning = 'pruning';
  static const String observation = 'observation';

  static List<String> get all => [watering, fertilizing, pruning, observation];
}