import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/messaging.dart';
import '../../../navigation/app_router.dart';
import '../../../state/chat_provider.dart';

/// Conversation list with job context, unread badges and pull-to-refresh.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final ChatProvider chat = context.read<ChatProvider>();
    if (chat.conversations.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => chat.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final ChatProvider chat = context.watch<ChatProvider>();

    return AppScaffold(
      appBar: const AppTopBar(title: 'Messages'),
      body: chat.isLoading && chat.conversations.isEmpty
          ? const SkeletonList(count: 4)
          : chat.hasError && chat.conversations.isEmpty
          ? ErrorStateView(
              message: chat.error ?? 'Could not load messages',
              onRetry: chat.retry,
            )
          : chat.conversations.isEmpty
          ? const EmptyStateView(
              title: 'No conversations yet',
              message: 'Chats with work givers and workers will appear here.',
              icon: Icons.chat_bubble_outline_rounded,
            )
          : RefreshIndicator(
              onRefresh: () => chat.load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.xl,
                ),
                children: <Widget>[
                  SectionHeader(
                    title: '${chat.conversations.length} conversation(s)',
                  ),
                  for (final Conversation conversation in chat.conversations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        onTap: () => AppRouter.push(
                          context,
                          AppRoutes.chat,
                          arguments: conversation.id,
                        ),
                        child: Row(
                          children: <Widget>[
                            ProfileAvatar(
                              name: conversation.participantName,
                              showOnlineDot: true,
                              isOnline: conversation.isOnline,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          conversation.participantName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: texts.label,
                                        ),
                                      ),
                                      if (conversation.lastMessageAt != null)
                                        Text(
                                          AppFormat.messageTime(
                                            conversation.lastMessageAt!,
                                          ),
                                          style: texts.caption,
                                        ),
                                    ],
                                  ),
                                  if (conversation.jobContext.isNotEmpty)
                                    Text(
                                      conversation.jobContext,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: texts.caption?.copyWith(
                                        color: context.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    conversation.lastMessage.isEmpty
                                        ? 'No messages yet'
                                        : conversation.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: texts.bodyMedium?.copyWith(
                                      color: conversation.unread > 0
                                          ? AppColors.textPrimary
                                          : null,
                                      fontWeight: conversation.unread > 0
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (conversation.unread > 0) ...<Widget>[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.primary,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  '${conversation.unread}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
