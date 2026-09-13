// ConnectCall smoke tests (no Firebase needed — pure model logic).
import 'package:flutter_test/flutter_test.dart';

import 'package:connect_call/models/call_model.dart';

void main() {
  test('CallRecord duration formatting', () {
    final base = DateTime(2026, 1, 1, 12, 0);
    expect(
      CallRecord(
        id: '1',
        otherUserName: 'Asha',
        type: 'audio',
        timestamp: base,
        durationSeconds: 45,
        status: 'completed',
      ).formattedDuration,
      '45s',
    );
    expect(
      CallRecord(
        id: '2',
        otherUserName: 'Ravi',
        type: 'video',
        timestamp: base,
        durationSeconds: 125,
        status: 'completed',
      ).formattedDuration,
      '2m 05s',
    );
  });

  test('CallRecord status flags', () {
    final base = DateTime(2026, 1, 1, 12, 0);
    final missed = CallRecord(
      id: '3',
      otherUserName: 'Asha',
      type: 'audio',
      timestamp: base,
      durationSeconds: 0,
      status: 'missed',
    );
    expect(missed.isMissed, isTrue);
    expect(missed.isVideo, isFalse);
    expect(missed.isRejected, isFalse);
  });
}
