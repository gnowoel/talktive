import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import '../../providers/private_chat_provider.dart';
import '../../utils/floor_utils.dart';
import '../../helpers/snackbar_helper.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_floor_badge.dart';

import 'package:go_router/go_router.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/client_provider.dart';

final _peepholeMessageProvider = FutureProvider.family<Message?, int>((ref, channelId) async {
  final client = ref.read(clientProvider);
  final messages = await client.message.listMessages(channelId, limit: 1, offset: 0);
  return messages.isNotEmpty ? messages.first : null;
});

class PeepholeScreen extends ConsumerWidget {
  final PrivateChatWithProfile chatItem;

  const PeepholeScreen({super.key, required this.chatItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Peephole vignette overlay could just be a radial gradient
    final otherResident = chatItem.otherResident;
    final otherUserName = chatItem.otherUserName ?? 'Stranger';
    final otherUserId = otherResident.userInfoId.toString();
    final profileAsync = ref.watch(userProfileProvider(otherUserId));

    final initialMessageAsync = ref.watch(_peepholeMessageProvider(chatItem.chat.channelId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🚪 Someone is knocking', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Central glow
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.4),
                    Colors.black,
                  ],
                  stops: const [0.0, 1.0],
                  radius: 1.0,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   const SizedBox(height: AppTheme.duoSpacingLarge),
                   // Avatar and Name
                   Hero(
                     tag: 'avatar_${chatItem.chat.id}',
                     child: DuoAvatar(
                       imageUrl: chatItem.otherUserAvatar,
                       size: 120,
                       mood: chatItem.otherUserMood,
                       trustScore: otherResident.trustScore,
                       showRing: true,
                       floorLevel: FloorUtils.computeFloor(otherResident),
                       showFloor: true,
                       showMood: true,
                     ),
                   ),
                   const SizedBox(height: AppTheme.duoSpacingMedium),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(
                         otherUserName,
                         style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(width: 8),
                       DuoFloorBadge(
                         floor: FloorUtils.computeFloor(otherResident),
                         fontSize: 14,
                         padding: 10,
                       ),
                     ],
                   ),
                   const SizedBox(height: 12),
                   
                   // Info chips
                   Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     alignment: WrapAlignment.center,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                         decoration: BoxDecoration(
                           color: AppTheme.primaryColor.withValues(alpha: 0.3),
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: AppTheme.primaryColor),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Text('⭐', style: TextStyle(fontSize: 18)),
                             const SizedBox(width: 8),
                             Text(
                               'Trust: ${otherResident.trustScore}',
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ],
                         ),
                       ),
                        Container(
                         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                         decoration: BoxDecoration(
                           color: AppTheme.infoColor.withValues(alpha: 0.3),
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: AppTheme.infoColor),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Text('✨', style: TextStyle(fontSize: 18)),
                             const SizedBox(width: 8),
                             Text(
                               'Level ${otherResident.level}',
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                   
                   const SizedBox(height: AppTheme.duoSpacingLarge),
                   
                   // Bio
                   if (otherResident.bio != null && otherResident.bio!.isNotEmpty)
                     Container(
                       padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                       decoration: BoxDecoration(
                         color: Colors.white.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
                         border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                       ),
                       child: Text(
                         '"${otherResident.bio!}"',
                         style: const TextStyle(
                           color: Colors.white, 
                           fontStyle: FontStyle.italic,
                           fontSize: 16,
                         ),
                         textAlign: TextAlign.center,
                       ),
                     ),
                     
                   const SizedBox(height: AppTheme.duoSpacingMedium),

                   // Moments Button
                   _buildMomentsButton(context, profileAsync.value, otherUserId, otherUserName),
                   
                   const SizedBox(height: AppTheme.duoSpacingLarge),

                   // Preview Box
                   Container(
                     padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                         Row(
                           children: [
                             Icon(Icons.message_rounded, color: AppTheme.primaryColor, size: 20),
                             const SizedBox(width: 8),
                             Text(
                               'A message is waiting for you',
                               style: TextStyle(
                                 color: AppTheme.primaryColor, 
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         initialMessageAsync.when(
                           data: (msg) {
                             if (msg?.content != null && msg!.content!.isNotEmpty) {
                               return Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: Colors.grey[100],
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Text(
                                   '"${msg.content}"',
                                   style: TextStyle(
                                     color: Colors.grey[800],
                                     fontStyle: FontStyle.italic,
                                     fontSize: 15,
                                   ),
                                 ),
                               );
                             }
                             return Text(
                               'They sent a knock, but they won\'t know if you read it until you open the door. Tap "Open the Door" to add them to your Chats list.',
                               style: TextStyle(color: Colors.grey[800], height: 1.4),
                             );
                           },
                           loading: () => const Center(child: CircularProgressIndicator()),
                           error: (_, __) => Text(
                             'They sent a knock, but they won\'t know if you read it until you open the door. Tap "Open the Door" to add them to your Chats list.',
                             style: TextStyle(color: Colors.grey[800], height: 1.4),
                           ),
                         ),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 40),
                   
                   // Actions
                   DuoButton(
                     text: '🔓 Open the Door',
                     color: AppTheme.duoGreen,
                     onPressed: () async {
                       HapticFeedback.mediumImpact();
                       try {
                         await ref.read(privateChatListProvider.notifier).respondToInvite(chatItem.chat.channelId, true);
                         if (context.mounted) {
                           Navigator.pop(context); // close peephole
                         }
                       } catch (e) {
                         if (context.mounted) {
                           SnackBarHelper.showError(context, 'Failed to open door');
                         }
                       }
                     },
                   ),
                   const SizedBox(height: AppTheme.duoSpacingMedium),
                   DuoButton(
                     text: '🔒 Keep it Locked',
                     color: AppTheme.duoRed,
                     onPressed: () async {
                       HapticFeedback.mediumImpact();
                       try {
                         await ref.read(privateChatListProvider.notifier).respondToInvite(chatItem.chat.channelId, false);
                         if (context.mounted) {
                           Navigator.pop(context); // close peephole
                         }
                       } catch (e) {
                         if (context.mounted) {
                           SnackBarHelper.showError(context, 'Failed to decline');
                         }
                       }
                     },
                   ),
                   const SizedBox(height: AppTheme.duoSpacingLarge),
                   TextButton.icon(
                     onPressed: () {
                         SnackBarHelper.showInfo(context, 'Reporting & Blocking coming soon');
                     },
                     icon: const Icon(Icons.security, color: Colors.grey),
                     label: const Text('Call Security', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                   )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsButton(BuildContext context, UserProfileView? profile, String userId, String userName) {
    final momentsCount = profile?.totalMoments ?? 0;
    return DuoButton(
      text: '📸 Sharing $momentsCount Moments',
      icon: Icons.auto_awesome,
      isSecondary: true,
      color: AppTheme.duoBlue.withValues(alpha: 0.8), // Slightly transparent for dark theme
      width: double.infinity,
      onPressed: () {
        context.push('/user/$userId/moments?name=${Uri.encodeComponent(userName)}');
      },
    );
  }
}
