class ShiftModel {
  final int? id;
  final int userId;
  final String startTime;
  final String? endTime;
  final double startingCash;
  final double expectedCash;
  final double? actualCash;
  final double? difference;
  final String status; // 'open', 'closed'
  final int isSynced;

  ShiftModel({
    this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.startingCash,
    required this.expectedCash,
    this.actualCash,
    this.difference,
    this.status = 'open',
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime,
      'end_time': endTime,
      'starting_cash': startingCash,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'difference': difference,
      'status': status,
      'is_synced': isSynced,
    };
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'],
      userId: map['user_id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      startingCash: (map['starting_cash'] ?? 0.0).toDouble(),
      expectedCash: (map['expected_cash'] ?? 0.0).toDouble(),
      actualCash: (map['actual_cash'] as num?)?.toDouble(),
      difference: (map['difference'] as num?)?.toDouble(),
      status: map['status'] ?? 'open',
      isSynced: map['is_synced'] ?? 0,
    );
  }
}
