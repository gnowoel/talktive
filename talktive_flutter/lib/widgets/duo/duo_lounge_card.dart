import 'package:flutter/material.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import '../../helpers/date_formatter.dart';
import 'duo_card.dart';

class DuoLoungeCard extends StatelessWidget {
  final Lounge lounge;
  final VoidCallback? onTap;
  final Widget? trailing;
  final List<Widget>? bottomActions;
  final bool showPublicBadge;
  final bool showInterests;
  final int maxInterests;

  const DuoLoungeCard({
    super.key,
    required this.lounge,
    this.onTap,
    this.trailing,
    this.bottomActions,
    this.showPublicBadge = true,
    this.showInterests = false,
    this.maxInterests = 3,
  });

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingSmall),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildEmojiContainer(),
                const SizedBox(width: AppTheme.duoSpacingMedium),
                Expanded(child: _buildInfo(context)),
                if (trailing != null) trailing!,
              ],
            ),
            if (showInterests &&
                lounge.interests != null &&
                lounge.interests!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInterests(),
            ],
            if (lounge.description != null && lounge.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDescription(context),
            ],
            if (bottomActions != null && bottomActions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...bottomActions!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiContainer() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.duoBlueGradient[0].withValues(alpha: 0.2),
            AppTheme.duoBlueGradient[1].withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
      ),
      child: Center(
        child: Text(lounge.emoji ?? '👥', style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lounge.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showPublicBadge && lounge.isPublic)
              _buildBadge(context, 'Public', AppTheme.duoGreen),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.people, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${lounge.memberCount}/${lounge.maxMembers}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            if (lounge.lastMessageAt != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 2),
              Text(
                formatTimestamp(lounge.lastMessageAt!),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
              ),
            ],
          ],
        ),
        if (lounge.lastMessage != null && lounge.lastMessage!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.duoBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lounge.lastMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.duoBlue,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInterests() {
    return Wrap(
      spacing: 6,
      runSpacing: -6,
      children: lounge.interests!
          .take(maxInterests)
          .map(
            (interest) => Chip(
              label: Text(
                '#$interest',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.duoBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              padding: EdgeInsets.zero,
              backgroundColor: AppTheme.duoBlue.withValues(alpha: 0.1),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      lounge.description!,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
