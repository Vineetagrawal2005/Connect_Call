import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../services/zego_service.dart';

/// One row in the contacts list: avatar placeholder, name, online/offline
/// dot, and audio-call + video-call buttons (real ZEGOCLOUD invitations).
class UserTile extends StatelessWidget {
  final AppUser user;

  const UserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            child: Text(user.initial, style: const TextStyle(fontSize: 20)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: user.online ? AppTheme.onlineGreen : AppTheme.offlineGrey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(user.name),
      subtitle: Text(
        user.online ? 'Online' : 'Offline',
        style: TextStyle(
          color: user.online ? AppTheme.onlineGreen : AppTheme.offlineGrey,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CallButton(user: user, isVideo: false),
          const SizedBox(width: 4),
          _CallButton(user: user, isVideo: true),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final AppUser user;
  final bool isVideo;

  const _CallButton({required this.user, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.isZegoConfigured) {
      // Zego keys not set yet — explain instead of failing silently.
      return IconButton(
        tooltip: isVideo ? 'Video call' : 'Audio call',
        icon: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.grey),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calling not configured yet — add your ZEGOCLOUD AppID/AppSign in core/constants.dart.'),
          ),
        ),
      );
    }
    return ZegoSendCallInvitationButton(
      isVideoCall: isVideo,
      invitees: [ZegoUIKitUser(id: user.uid, name: user.name)],
      iconSize: const Size(40, 40),
      buttonSize: const Size(40, 40),
      icon: ButtonIcon(
        icon: Icon(
          isVideo ? Icons.videocam : Icons.call,
          color: Theme.of(context).colorScheme.primary,
        ),
        backgroundColor: Colors.transparent,
      ),
      onWillPressed: () => ZegoService.ensurePermissions(isVideo, context),
      onPressed: (code, message, errorInvitees) {
        if (code.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start call: $message')),
          );
        }
      },
    );
  }
}
