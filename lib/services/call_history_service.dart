import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/call_model.dart';

/// Reads/writes `callHistory/{uid}/records`.
class CallHistoryService {
  final FirebaseFirestore _db;

  CallHistoryService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _records(String uid) {
    return _db
        .collection(AppConstants.callHistoryCollection)
        .doc(uid)
        .collection(AppConstants.callRecordsSubcollection);
  }

  Future<void> logCall({
    required String uid,
    required String otherUserName,
    required String type, // 'audio' | 'video'
    required int durationSeconds,
    required String status, // 'completed' | 'missed' | 'rejected'
  }) async {
    try {
      await _records(uid).add({
        'otherUserName': otherUserName,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'durationSeconds': durationSeconds,
        'status': status,
      });
    } catch (_) {
      // History must never break the call flow — swallow errors here.
    }
  }

  /// Newest first.
  Stream<List<CallRecord>> streamHistory(String uid) {
    return _records(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CallRecord.fromDoc).toList());
  }
}
