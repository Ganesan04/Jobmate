import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/messaging.dart';
import '../../../navigation/app_router.dart';
import '../../../state/chat_provider.dart';

/// Single conversation: message bubbles, typing indicator and composer.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openThread(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    final bool sent = await context.read<ChatProvider>().send(
      widget.conversationId,
      text,
    );
    if (sent && _scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: AppDurations.normal,
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final ChatProvider chat = context.watch<ChatProvider>();
    final Conversation? conversation = chat.conversationById(
      widget.conversationId,
    );
    final List<Message> messages = chat.thread(widget.conversationId);
    final bool sending = chat.isSending(widget.conversationId);

    if (conversation == null) {
      return const AppScaffold(
        appBar: AppTopBar(title: 'Chat'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: AppScaffold(
        centerContent: false,
        appBar: AppTopBar(
          title: conversation.participantName,
          subtitle: conversation.isOnline
              ? 'Online now'
              : conversation.jobContext,
          actions: <Widget>[
            AppIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: 'Options',
              onPressed: () => showAppSheet<void>(
                context: context,
                title: conversation.participantName,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text('Report conversation'),
                        onTap: () {
                          Navigator.of(context).pop();
                          AppRouter.push(context, AppRoutes.reportProblem);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: const Text('View profile'),
                        onTap: () {
                          Navigator.of(context).pop();
                          AppRouter.push(context, AppRoutes.profile);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Column(
          children: <Widget>[
            if (conversation.jobContext.isNotEmpty)
              Container(
                width: double.infinity,
                color: context.primaryTint,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.work_outline_rounded,
                      size: 15,
                      color: context.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        conversation.jobContext,
                        style: texts.caption?.copyWith(color: context.primary),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: messages.isEmpty
                  ? const EmptyStateView(
                      title: 'Start the conversation',
                      message: 'Ask about the shift, pay or location.',
                      icon: Icons.waving_hand_rounded,
                      compact: true,
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.md,
                        AppSpacing.screen,
                        AppSpacing.md,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int index) =>
                          _Bubble(message: messages[index]),
                    ),
            ),
            if (sending) const InlineLoader(label: 'Sending'),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _controller,
                      hint: 'Type a message',
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Material(
                    color: context.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _send,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: mine ? context.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(mine ? AppRadius.lg : 4),
            bottomRight: Radius.circular(mine ? 4 : AppRadius.lg),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              message.text,
              style: Theme.of(context).textTheme.body?.copyWith(
                color: mine ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppFormat.messageTime(message.sentAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: mine ? Colors.white70 : AppColors.textTertiary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
