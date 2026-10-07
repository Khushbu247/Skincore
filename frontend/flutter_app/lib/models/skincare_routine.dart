import 'dart:convert';

class SkincareRoutineItem {
  final String id;
  final String userId;
  final String productName;
  final String routineType; // 'Morning', 'Evening', 'Custom'
  final String time; // e.g. '08:00 AM'
  final bool isCompleted;

  const SkincareRoutineItem({
    required this.id,
    required this.userId,
    required this.productName,
    required this.routineType,
    required this.time,
    this.isCompleted = false,
  });

  SkincareRoutineItem copyWith({
    String? id,
    String? userId,
    String? productName,
    String? routineType,
    String? time,
    bool? isCompleted,
  }) {
    return SkincareRoutineItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      routineType: routineType ?? this.routineType,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory SkincareRoutineItem.fromJson(String source) =>
      SkincareRoutineItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
