import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../core/constants.dart';
import 'call_history_service.dart';

/// Owns the ZEGOCLOUD invitation service:
/// - init/uninit on login/logout (called from AuthProvider + main's
///   auth-state listener so both fresh logins and existing sessions work),
/// - permission gating before outgoing calls,
/// - writing call-history records for completed/missed/rejected calls.
///
/// The prebuilt widgets provide mute, speaker toggle, camera on/off +
/// camera switch, and end-call out of the box.
class ZegoService {
  ZegoService._();

  static String? _activeUid;
  static bool get isInitialized => _activeUid != null;

  // callID -> moment the invitation was sent/received (fallback start time).
  static final Map<String, DateTime> _invitedAt = {};
  // callID -> moment the call was accepted (accurate duration start).
  static final Map<String, DateTime> _acceptedAt = {};
  // Last incoming caller (used when the callee declines a call).
  static String? _lastIncomingCallerName;
  static String? _lastIncomingCallID;
  static bool _lastIncomingWasVideo = false;

  static final CallHistoryService _history = CallHistoryService();

  /// Must be called once at app start (before runApp) so the invitation
  /// service can show the incoming-call screen from anywhere.
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(key);
  }

  static Future<void> init({required String userId, required String userName}) async {
    if (!AppConstants.isZegoConfigured) return; // app still runs; calls show a setup hint.
    if (_activeUid == userId) return;
    await uninit();

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: AppConstants.zegoAppID,
      appSign: AppConstants.zegoAppSign,
      userID: userId,
      userName: userName.isEmpty ? userId : userName,
      plugins: [ZegoUIKitSignalingPlugin()],
      requireConfig: (ZegoCallInvitationData data) {
        final config = data.type == ZegoCallInvitationType.videoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
        return config;
      },
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
          _handleCallEnd(event);
          defaultAction.call();
        },
      ),
      invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        onOutgoingCallSent: (callID, caller, callType, callees, customData) {
          _invitedAt[callID] = DateTime.now();
        },
        onOutgoingCallAccepted: (callID, callee) {
          _acceptedAt[callID] = DateTime.now();
        },
        onOutgoingCallDeclined: (callID, callee, customData) {
          _logForCurrentUser(
            otherUserName: callee.name.isEmpty ? 'Unknown' : callee.name,
            isVideo: null,
            durationSeconds: 0,
            status: 'rejected',
          );
          _invitedAt.remove(callID);
        },
        onOutgoingCallRejectedCauseBusy: (callID, callee, customData) {
          _logForCurrentUser(
            otherUserName: callee.name.isEmpty ? 'Unknown' : callee.name,
            isVideo: null,
            durationSeconds: 0,
            status: 'rejected',
          );
          _invitedAt.remove(callID);
        },
        onOutgoingCallTimeout: (callID, callees, isVideoCall) {
          final other = callees.isNotEmpty ? callees.first.name : 'Unknown';
          _logForCurrentUser(
            otherUserName: other.isEmpty ? 'Unknown' : other,
            isVideo: isVideoCall,
            durationSeconds: 0,
            status: 'missed',
          );
          _invitedAt.remove(callID);
        },
        onIncomingCallReceived: (callID, caller, callType, callees, customData) {
          _invitedAt[callID] = DateTime.now();
          _lastIncomingCallID = callID;
          _lastIncomingCallerName = caller.name.isEmpty ? 'Unknown' : caller.name;
          _lastIncomingWasVideo = callType == ZegoCallInvitationType.videoCall;
        },
        onIncomingCallAcceptButtonPressed: () {
          if (_lastIncomingCallID != null) {
            _acceptedAt[_lastIncomingCallID!] = DateTime.now();
          }
        },
        onIncomingCallDeclineButtonPressed: () {
          // Callee actively declined → record as rejected on their side.
          _logForCurrentUser(
            otherUserName: _lastIncomingCallerName ?? 'Unknown',
            isVideo: _lastIncomingWasVideo,
            durationSeconds: 0,
            status: 'rejected',
          );
          if (_lastIncomingCallID != null) {
            _invitedAt.remove(_lastIncomingCallID!);
          }
        },
        onIncomingCallTimeout: (callID, caller) {
          _logForCurrentUser(
            otherUserName: caller.name.isEmpty ? 'Unknown' : caller.name,
            isVideo: _lastIncomingWasVideo,
            durationSeconds: 0,
            status: 'missed',
          );
          _invitedAt.remove(callID);
        },
      ),
    );
    _activeUid = userId;
  }

  static Future<void> uninit() async {
    if (_activeUid == null) return;
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
    } catch (_) {}
    _activeUid = null;
    _invitedAt.clear();
    _acceptedAt.clear();
  }

  /// Called by the prebuilt call page when a connected call ends.
  /// Derives the "other user" from the invitation data so BOTH sides log it.
  static void _handleCallEnd(ZegoCallEndEvent event) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = event.invitationData;
    String otherName = 'Unknown';
    String type = 'audio';
    if (data != null) {
      type = data.type == ZegoCallInvitationType.videoCall ? 'video' : 'audio';
      if (data.inviter?.id == uid) {
        if (data.invitees.isNotEmpty) {
          otherName = data.invitees.first.name.isEmpty ? 'Unknown' : data.invitees.first.name;
        }
      } else {
        otherName = (data.inviter?.name ?? '').isEmpty ? 'Unknown' : data.inviter!.name;
      }
    }
    final start = _acceptedAt[event.callID] ?? _invitedAt[event.callID];
    final duration = start == null ? 0 : DateTime.now().difference(start).inSeconds;
    _acceptedAt.remove(event.callID);
    _invitedAt.remove(event.callID);
    _history.logCall(
      uid: uid,
      otherUserName: otherName,
      type: type,
      durationSeconds: duration < 0 ? 0 : duration,
      status: 'completed',
    );
  }

  static void _logForCurrentUser({
    required String otherUserName,
    required bool? isVideo,
    required int durationSeconds,
    required String status,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _history.logCall(
      uid: uid,
      otherUserName: otherUserName,
      // Fall back to the pending-call type when the callback lacks it.
      type: (isVideo ?? _lastIncomingWasVideo) ? 'video' : 'audio',
      durationSeconds: durationSeconds,
      status: status,
    );
  }

  /// Requests mic (audio) or mic+camera (video) BEFORE starting a call.
  /// Returns true if the call may proceed. Shows a simple denial dialog.
  static Future<bool> ensurePermissions(bool isVideoCall, BuildContext context) async {
    final statuses = await (isVideoCall
        ? [Permission.microphone, Permission.camera].request()
        : [Permission.microphone].request());
    final granted = statuses.values.every((s) => s.isGranted);
    if (granted) return true;
    if (!context.mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission needed'),
        content: Text(
          isVideoCall
              ? 'Camera and microphone access is required for video calls. Please allow them and try again.'
              : 'Microphone access is required for audio calls. Please allow it and try again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
    return false;
  }
}
