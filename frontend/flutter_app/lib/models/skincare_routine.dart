import 'dart:convert';

class SkincareRoutineItem {
  final String id;
  final String userId;
  final String productName;
  final String routineType; // 'Morning', 'Evening', 'Custom'
  final String time; // e.g. '08:00 AM'
  final bool isCompleted; // Deprecated fallback flag
  final DateTime createdAt;

  SkincareRoutineItem({
    required this.id,
    required this.userId,
    required this.productName,
    required this.routineType,
    required this.time,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SkincareRoutineItem copyWith({
    String? id,
    String? userId,
    String? productName,
    String? routineType,
    String? time,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return SkincareRoutineItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      routineType: routineType ?? this.routineType,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productName': productName,
      'routineType': routineType,
      'time': time,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SkincareRoutineItem.fromMap(Map<String, dynamic> map) {
    return SkincareRoutineItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      productName: map['productName'] ?? '',
      routineType: map['routineType'] ?? 'Morning',
      time: map['time'] ?? '08:00 AM',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SkincareRoutineItem.fromJson(String source) =>
      SkincareRoutineItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Date-stamped completion record for daily routine adherence tracking
class RoutineCompletionLog {
  final String id;
  final String routineId;
  final String userId;
  final String dateString; // 'YYYY-MM-DD'
  final DateTime completedAt;

  const RoutineCompletionLog({
    required this.id,
    required this.routineId,
    required this.userId,
    required this.dateString,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'userId': userId,
      'dateString': dateString,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory RoutineCompletionLog.fromMap(Map<String, dynamic> map) {
    return RoutineCompletionLog(
      id: map['id'] ?? '',
      routineId: map['routineId'] ?? '',
      userId: map['userId'] ?? '',
      dateString: map['dateString'] ?? '',
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineCompletionLog.fromJson(String source) =>
      RoutineCompletionLog.fromMap(json.decode(source) as Map<String, dynamic>);
}
