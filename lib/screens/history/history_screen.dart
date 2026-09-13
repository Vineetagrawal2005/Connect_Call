import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/call_model.dart';
import '../../services/call_history_service.dart';

/// Req 5: lists callHistory/{uid}/records newest-first with missed indicator.
class HistoryScreen extends StatelessWidget {
  final bool showAppBar;

  const HistoryScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please log in to see call history.'));
    }
    final body = StreamBuilder<List<CallRecord>>(
      stream: CallHistoryService().streamHistory(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load call history. Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(child: Text('No calls yet'));
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = records[i];
            final Color iconColor = r.isMissed
                ? AppTheme.missedRed
                : Theme.of(context).colorScheme.primary;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: r.isMissed ? AppTheme.missedRed.withValues(alpha: 0.12) : null,
                child: Icon(
                  r.isVideo ? Icons.videocam : Icons.call,
                  color: iconColor,
                ),
              ),
              title: Text(
                r.otherUserName,
                style: TextStyle(
                  color: r.isMissed ? AppTheme.missedRed : null,
                  fontWeight: r.isMissed ? FontWeight.w600 : null,
                ),
              ),
              subtitle: Text(
                '${r.isVideo ? 'Video' : 'Audio'} • ${_statusLabel(r.status)} • ${r.formattedDuration}',
              ),
              trailing: r.isMissed
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.call_missed, color: AppTheme.missedRed, size: 20),
                        SizedBox(width: 4),
                        Text('Missed', style: TextStyle(color: AppTheme.missedRed, fontSize: 12)),
                      ],
                    )
                  : Text(
                      _formatDate(r.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
            );
          },
        );
      },
    );

    if (!showAppBar) return body;
    return Scaffold(appBar: AppBar(title: const Text('Call history')), body: body);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'missed':
        return 'Missed';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Completed';
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final sameDay = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${dt.day}/${dt.month} $hh:$mm';
  }
}
