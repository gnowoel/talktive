import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import '../../utils/floor_utils.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_card.dart';

class GroupMembersScreen extends ConsumerWidget {
  final Group group;

  const GroupMembersScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.id!));

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Members',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: membersAsync.when(
        data: (members) => _buildMembersList(context, members),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildMembersList(BuildContext context, List<Resident> members) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberCard(context, member, index)
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 300.ms)
            .slideX(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildMemberCard(BuildContext context, Resident member, int index) {
    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Row(
          children: [
            DuoAvatar(
              imageUrl: member.avatar,
              size: 48,
              showRing: true,
              floorLevel: FloorUtils.computeFloor(member),
            ),
            const SizedBox(width: AppTheme.duoSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resident',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.apartment, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Floor ${FloorUtils.computeFloor(member)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.star, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${member.level} • ⭐ ${member.trustScore}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.duoRed),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            'Failed to load members',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            error.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
