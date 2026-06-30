import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';
import '../../auth/auth_models.dart';
import '../chat_workspace/klipy_media_repository.dart';
import '../chat_workspace/message_composer.dart';
import '../chat_workspace/message_timeline.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/member_profile_popover.dart';
import '../shared/chat_timestamp_format.dart';
import '../workspace_seed.dart';
import 'direct_messages_models.dart';

class DmConversationModule extends StatefulWidget {
  const DmConversationModule({
    required this.conversation,
    required this.messages,
    required this.isLoading,
    required this.error,
    required this.mediaPolicy,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserInitials,
    this.hasOlderMessages = false,
    this.isLoadingOlderMessages = false,
    this.timestampOptions,
    this.klipyRepository = const SeededKlipyMediaRepository(),
    this.onSendMessage,
    this.onLoadOlderMessages,
    this.onDeleteMessage,
    super.key,
  });

  final DmConversationPreviewSeed conversation;
  final DmConversationMessages? messages;
  final bool isLoading;
  final String? error;
  final ServerMediaPolicy mediaPolicy;
  final String currentUserId;
  final String currentUserName;
  final String currentUserInitials;
  final bool hasOlderMessages;
  final bool isLoadingOlderMessages;
  final ChatTimestampFormatOptions? timestampOptions;
  final KlipyMediaRepository klipyRepository;
  final Future<void> Function(String message)? onSendMessage;
  final Future<void> Function()? onLoadOlderMessages;
  final ValueChanged<MessageSeed>? onDeleteMessage;

  @override
  State<DmConversationModule> createState() => _DmConversationModuleState();
}

class _DmConversationModuleState extends State<DmConversationModule> {
  MessageSeed? _replyingTo;
  var _localMessages = const <MessageSeed>[];

  @override
  void didUpdateWidget(covariant DmConversationModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.channelId != widget.conversation.channelId ||
        oldWidget.conversation.networkId != widget.conversation.networkId) {
      _localMessages = const [];
    }
    final reply = _replyingTo;
    final messages = _messages;
    if (reply != null && !messages.any((message) => message.id == reply.id)) {
      _replyingTo = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      key: const ValueKey('dm-conversation-module'),
      decoration: BoxDecoration(color: colors.panelRaised),
      child: Column(
        children: [
          _DmConversationHeader(
            conversation: widget.conversation,
            mediaPolicy: widget.mediaPolicy,
          ),
          Expanded(
            child: _DmConversationBody(
              state: widget,
              messages: _messages,
              onReplyMessage: (message) {
                setState(() => _replyingTo = message);
              },
              onDeleteMessage: widget.onDeleteMessage,
            ),
          ),
          MessageComposer(
            hintText: 'Message ${widget.conversation.displayName}',
            replyingTo: _replyingTo,
            onCancelReply: () => setState(() => _replyingTo = null),
            onSubmit: _submitMessage,
            mediaPolicy: widget.mediaPolicy,
            klipyRepository: widget.klipyRepository,
          ),
        ],
      ),
    );
  }

  List<MessageSeed> get _messages => [
    ...?widget.messages?.messages,
    ..._localMessages,
  ];

  void _submitMessage(String body) {
    final send = widget.onSendMessage;
    if (send == null) {
      _appendLocalMessage(body);
      return;
    }
    setState(() => _replyingTo = null);
    unawaited(send(body));
  }

  void _appendLocalMessage(String body) {
    final now = DateTime.now();
    setState(() {
      _localMessages = [
        ..._localMessages,
        MessageSeed(
          id: '${widget.conversation.networkId}/local-dm-message-${now.microsecondsSinceEpoch}',
          authorId: '${widget.conversation.networkId}/${widget.currentUserId}',
          author: widget.currentUserName,
          authorColor: VerdantAuthorColors.green,
          time: formatClockLabel(now),
          createdAt: now.toIso8601String(),
          body: body,
          initials: widget.currentUserInitials,
          isOwnMessage: true,
        ),
      ];
      _replyingTo = null;
    });
  }
}

class _DmConversationHeader extends StatelessWidget {
  const _DmConversationHeader({
    required this.conversation,
    required this.mediaPolicy,
  });

  final DmConversationPreviewSeed conversation;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final member = _conversationMemberSeed(conversation);
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (conversation.bannerUrl != null)
            Opacity(
              opacity: 0.18,
              child: MemberMediaBanner(
                member: member,
                mediaPolicy: mediaPolicy,
                playAnimatedMedia: true,
                imageKeyPrefix: 'dm-conversation-header-banner',
                fallbackOpacity: 0,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                MemberMediaAvatar(
                  member: member,
                  mediaPolicy: mediaPolicy,
                  size: 34,
                  playAnimatedMedia: true,
                  imageKeyPrefix: 'dm-conversation-header-avatar',
                  loadingPlaceholder: _HeaderAvatar(
                    initials: conversation.initials,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${conversation.status} - ${_networkLabel(conversation.networkId)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PhosphorIcon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

MemberSeed _conversationMemberSeed(DmConversationPreviewSeed conversation) {
  return MemberSeed(
    id: conversation.localUserId == null
        ? conversation.channelId
        : '${conversation.networkId}/${conversation.localUserId}',
    name: conversation.displayName,
    status: conversation.status,
    initials: conversation.initials,
    avatarUrl: conversation.avatarUrl,
    bannerUrl: conversation.bannerUrl,
  );
}

class _DmConversationBody extends StatelessWidget {
  const _DmConversationBody({
    required this.state,
    required this.messages,
    required this.onReplyMessage,
    required this.onDeleteMessage,
  });

  final DmConversationModule state;
  final List<MessageSeed> messages;
  final ValueChanged<MessageSeed> onReplyMessage;
  final ValueChanged<MessageSeed>? onDeleteMessage;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && messages.isEmpty) {
      return const _ConversationStatus(
        icon: PhosphorIconsRegular.chatCircleDots,
        title: 'Loading messages',
        detail: 'Opening direct message history',
        showProgress: true,
      );
    }

    final error = state.error;
    if (error != null && messages.isEmpty) {
      return _ConversationStatus(
        icon: PhosphorIconsRegular.warningCircle,
        title: 'Could not load messages',
        detail: error,
      );
    }

    if (messages.isEmpty) {
      return _ConversationStatus(
        icon: PhosphorIconsRegular.chatCircleText,
        title: 'No messages yet',
        detail: 'Start a conversation with ${state.conversation.displayName}.',
      );
    }

    final timeline = MessageTimeline(
      messages: messages,
      beginningLabel: 'Beginning of DM with ${state.conversation.displayName}',
      pageStorageKey: 'dm-message-timeline-${state.conversation.channelId}',
      mediaPolicy: state.mediaPolicy,
      timestampOptions: state.timestampOptions,
      hasOlderMessages: state.hasOlderMessages,
      isLoadingOlderMessages: state.isLoadingOlderMessages,
      onLoadOlderMessages: state.onLoadOlderMessages,
      onReplyMessage: onReplyMessage,
      onDeleteMessage: onDeleteMessage,
    );
    if (!state.isLoading && error == null) {
      return timeline;
    }
    return Stack(
      children: [
        timeline,
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _DmLoadingBanner(
            label: error ?? 'Syncing direct message',
            showProgress: state.isLoading,
          ),
        ),
      ],
    );
  }
}

class _DmLoadingBanner extends StatelessWidget {
  const _DmLoadingBanner({required this.label, required this.showProgress});

  final String label;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Align(
      key: const ValueKey('dm-message-loading-overlay'),
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.92),
          borderRadius: VerdantRadii.sharp,
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress) ...[
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationStatus extends StatelessWidget {
  const _ConversationStatus({
    required this.icon,
    required this.title,
    required this.detail,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              PhosphorIcon(icon, size: 34, color: VerdantColors.textMuted),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox.square(
      dimension: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.actionMuted),
        child: Center(
          child: Text(
            initials,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colors.accentStrong),
          ),
        ),
      ),
    );
  }
}

String _networkLabel(String networkId) {
  final apiOrigin = apiOriginFromNetworkId(networkId);
  if (apiOrigin == null) {
    return 'Network';
  }
  return Uri.parse(apiOrigin).host;
}
