import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors `callHistory/{uid}/records/{recordId}`:
/// {otherUserName, type: audio|video, timestamp, durationSeconds, status}
class CallRecord {
  final String id;
  final String otherUserName;
  final String type; // 'audio' | 'video'
  final DateTime timestamp;
  final int durationSeconds;
  final String status; // 'completed' | 'missed' | 'rejected'

  const CallRecord({
    required this.id,
    required this.otherUserName,
    required this.type,
    required this.timestamp,
    required this.durationSeconds,
    required this.status,
  });

  factory CallRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CallRecord(
      id: doc.id,
      otherUserName: (data['otherUserName'] ?? 'Unknown') as String,
      type: (data['type'] ?? 'audio') as String,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationSeconds: (data['durationSeconds'] ?? 0) as int,
      status: (data['status'] ?? 'completed') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'otherUserName': otherUserName,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'durationSeconds': durationSeconds,
      'status': status,
    };
  }

  bool get isVideo => type == 'video';
  bool get isMissed => status == 'missed';
  bool get isRejected => status == 'rejected';

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}
