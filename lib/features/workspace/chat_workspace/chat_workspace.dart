import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/verdant_input_sanitizer.dart';
import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../shared/chat_timestamp_format.dart';
import '../shared/custom_expressive_asset.dart';
import '../workspace_seed.dart';
import 'chat_message_search.dart';
import 'klipy_media_repository.dart';
import 'link_preview_service.dart';
import 'message_composer.dart';
import 'message_invite_card.dart';
import 'message_mentions.dart';
import 'message_timeline.dart';
import 'server_custom_emojis.dart';

const _typingIndicatorStripHeight = 30.0;

class ChatWorkspace extends StatefulWidget {
  const ChatWorkspace({
    required this.seed,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserInitials,
    this.isLoading = false,
    this.error,
    this.identityMembers,
    this.typingMembers = const [],
    this.hasOlderMessages = false,
    this.isLoadingOlderMessages = false,
    this.timestampOptions,
    this.klipyRepository = const SeededKlipyMediaRepository(),
    this.linkPreviewService,
    this.customEmojiGroups = const [],
    this.customStickerGroups = const [],
    this.showHeader = true,
    this.onSendMessage,
    this.onTyping,
    this.onLoadOlderMessages,
    this.onDeleteMessage,
    this.onSetReaction,
    this.onPreviewInvite,
    this.onAcceptInvite,
    this.onPrepareMemberProfile,
    super.key,
  });

  final WorkspaceSeed seed;
  final String currentUserId;
  final String currentUserName;
  final String currentUserInitials;
  final bool isLoading;
  final String? error;
  final List<MemberSeed>? identityMembers;
  final List<MemberSeed> typingMembers;
  final bool hasOlderMessages;
  final bool isLoadingOlderMessages;
  final ChatTimestampFormatOptions? timestampOptions;
  final KlipyMediaRepository klipyRepository;
  final MessageLinkPreviewService? linkPreviewService;
  final List<ServerCustomEmojiGroup> customEmojiGroups;
  final List<ServerCustomStickerGroup> customStickerGroups;
  final bool showHeader;
  final Future<void> Function(String body)? onSendMessage;
  final Future<void> Function()? onTyping;
  final Future<void> Function()? onLoadOlderMessages;
  final ValueChanged<MessageSeed>? onDeleteMessage;
  final ServerReactionChangeHandler? onSetReaction;
  final ChatInvitePreviewHandler? onPreviewInvite;
  final ChatInviteAcceptHandler? onAcceptInvite;
  final FutureOr<MemberSeed> Function(MemberSeed member)?
  onPrepareMemberProfile;

  @override
  State<ChatWorkspace> createState() => _ChatWorkspaceState();
}

class _ChatWorkspaceState extends State<ChatWorkspace> {
  MessageSeed? _replyingTo;
  var _localMessages = const <MessageSeed>[];

  @override
  void didUpdateWidget(covariant ChatWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed.networkId != widget.seed.networkId ||
        oldWidget.seed.serverId != widget.seed.serverId ||
        _selectedChannelName(oldWidget.seed) !=
            _selectedChannelName(widget.seed)) {
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
    final selectedChannels = widget.seed.channels
        .where((channel) => channel.selected)
        .toList(growable: false);
    final activeChannel = selectedChannels.isEmpty
        ? null
        : selectedChannels.first;
    final channelName = activeChannel?.name ?? 'general';
    final customEmojis = serverCustomEmojisFromSettings(
      widget.seed.serverSettings,
    );
    final customStickers = serverCustomStickersFromSettings(
      widget.seed.serverSettings,
    );
    final customEmojiGroups = _activeCustomEmojiGroupsForRoute(
      activeSettings: widget.seed.serverSettings,
      activeMediaPolicy: widget.seed.mediaPolicy,
      groups: widget.customEmojiGroups,
    );
    final customStickerGroups = _activeCustomStickerGroupsForRoute(
      activeSettings: widget.seed.serverSettings,
      activeMediaPolicy: widget.seed.mediaPolicy,
      groups: widget.customStickerGroups,
    );
    final renderCustomEmojis = _mergeCustomEmojiCatalogs(
      customEmojis,
      customEmojiGroups,
    );
    final renderCustomStickers = _mergeCustomStickerCatalogs(
      customStickers,
      customStickerGroups,
    );
    final customExpressionSources = _customExpressionSourcesByAsset(
      emojiGroups: customEmojiGroups,
      stickerGroups: customStickerGroups,
    );
    return DecoratedBox(
      key: const ValueKey('chat-workspace-surface'),
      decoration: BoxDecoration(color: colors.panelRaised),
      child: Column(
        children: [
          if (widget.showHeader)
            ChannelHeaderModule(
              channelName: channelName,
              seed: widget.seed,
              messages: _messages,
              members: widget.identityMembers ?? widget.seed.members,
            ),
          Expanded(
            child: _ChatBody(
              seed: widget.seed,
              messages: _messages,
              channelName: channelName,
              isLoading: widget.isLoading,
              error: widget.error,
              identityMembers: widget.identityMembers,
              typingMembers: widget.typingMembers,
              hasOlderMessages: widget.hasOlderMessages,
              isLoadingOlderMessages: widget.isLoadingOlderMessages,
              timestampOptions: widget.timestampOptions,
              linkPreviewService: widget.linkPreviewService,
              customEmojis: renderCustomEmojis,
              customStickers: renderCustomStickers,
              customExpressionSources: customExpressionSources,
              onReplyMessage: (message) {
                setState(() => _replyingTo = message);
              },
              onLoadOlderMessages: widget.onLoadOlderMessages,
              onDeleteMessage: widget.onDeleteMessage,
              onSetReaction: widget.onSetReaction,
              onPreviewInvite: widget.onPreviewInvite,
              onAcceptInvite: widget.onAcceptInvite,
              onPrepareMemberProfile: widget.onPrepareMemberProfile,
            ),
          ),
          MessageComposer(
            hintText: 'Message #$channelName',
            replyingTo: _replyingTo,
            networkId: widget.seed.networkId,
            serverId: widget.seed.serverSettings.localServerId,
            mentionMembers: widget.identityMembers ?? widget.seed.members,
            onCancelReply: () => setState(() => _replyingTo = null),
            onSubmit: _submitMessage,
            onTyping: _sendTypingStart,
            mediaPolicy: widget.seed.mediaPolicy,
            klipyRepository: widget.klipyRepository,
            customEmojis: renderCustomEmojis,
            customEmojiGroups: customEmojiGroups,
            customStickers: renderCustomStickers,
            customStickerGroups: customStickerGroups,
          ),
        ],
      ),
    );
  }

  List<MessageSeed> get _messages => [
    ...widget.seed.messages,
    ..._localMessages,
  ];

  void _submitMessage(String body) {
    final normalizedBody = normalizeOutgoingMessageMentions(
      body: body,
      networkId: widget.seed.networkId,
      members: widget.identityMembers ?? widget.seed.members,
    );
    final send = widget.onSendMessage;
    if (send == null) {
      _appendLocalMessage(normalizedBody);
      return;
    }
    setState(() => _replyingTo = null);
    unawaited(send(normalizedBody));
  }

  void _sendTypingStart() {
    final send = widget.onTyping;
    if (send == null) {
      return;
    }
    unawaited(send());
  }

  void _appendLocalMessage(String body) {
    final now = DateTime.now();
    setState(() {
      _localMessages = [
        ..._localMessages,
        MessageSeed(
          id: '${widget.seed.networkId}/local-message-${now.microsecondsSinceEpoch}',
          authorId: '${widget.seed.networkId}/${widget.currentUserId}',
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

List<ServerCustomEmojiGroup> _activeCustomEmojiGroupsForRoute({
  required ServerSettingsSeed activeSettings,
  required ServerMediaPolicy activeMediaPolicy,
  required List<ServerCustomEmojiGroup> groups,
}) {
  final activeNetworkId = activeSettings.networkId;
  final activeServerId = activeSettings.localServerId;
  final activeGroups = <ServerCustomEmojiGroup>[];
  for (final group in groups) {
    if (group.networkId != activeNetworkId ||
        group.serverId != activeServerId) {
      continue;
    }
    final activeEmojis = [
      for (final emoji in group.emojis)
        if ((emoji.networkId == null || emoji.networkId == activeNetworkId) &&
            (emoji.serverId == null || emoji.serverId == activeServerId))
          emoji,
    ];
    if (activeEmojis.isEmpty) {
      continue;
    }
    activeGroups.add(
      ServerCustomEmojiGroup(
        serverId: activeServerId,
        networkId: activeNetworkId,
        label: group.label,
        iconUrl: group.iconUrl,
        mediaPolicy: group.mediaPolicy ?? activeMediaPolicy,
        emojis: List.unmodifiable(activeEmojis),
      ),
    );
  }
  if (activeGroups.isNotEmpty) {
    return List.unmodifiable(activeGroups);
  }
  return serverCustomEmojiGroupsFromSettings(
    activeSettings,
    mediaPolicy: activeMediaPolicy,
  );
}

List<ServerCustomStickerGroup> _activeCustomStickerGroupsForRoute({
  required ServerSettingsSeed activeSettings,
  required ServerMediaPolicy activeMediaPolicy,
  required List<ServerCustomStickerGroup> groups,
}) {
  final activeNetworkId = activeSettings.networkId;
  final activeServerId = activeSettings.localServerId;
  final activeGroups = <ServerCustomStickerGroup>[];
  for (final group in groups) {
    if (group.networkId != activeNetworkId ||
        group.serverId != activeServerId) {
      continue;
    }
    final activeStickers = [
      for (final sticker in group.stickers)
        if ((sticker.networkId == null ||
                sticker.networkId == activeNetworkId) &&
            (sticker.serverId == null || sticker.serverId == activeServerId))
          sticker,
    ];
    if (activeStickers.isEmpty) {
      continue;
    }
    activeGroups.add(
      ServerCustomStickerGroup(
        serverId: activeServerId,
        networkId: activeNetworkId,
        label: group.label,
        iconUrl: group.iconUrl,
        mediaPolicy: group.mediaPolicy ?? activeMediaPolicy,
        stickers: List.unmodifiable(activeStickers),
      ),
    );
  }
  if (activeGroups.isNotEmpty) {
    return List.unmodifiable(activeGroups);
  }
  return serverCustomStickerGroupsFromSettings(
    activeSettings,
    mediaPolicy: activeMediaPolicy,
  );
}

List<ServerCustomEmoji> _mergeCustomEmojiCatalogs(
  List<ServerCustomEmoji> activeEmojis,
  List<ServerCustomEmojiGroup> groups,
) {
  if (groups.isEmpty) {
    return activeEmojis;
  }

  final seen = <String>{};
  final merged = <ServerCustomEmoji>[];

  void add(ServerCustomEmoji emoji) {
    final key =
        '${emoji.networkId ?? ''}/${emoji.serverId ?? ''}/${emoji.id}/${emoji.name.toLowerCase()}';
    if (seen.add(key)) {
      merged.add(emoji);
    }
  }

  for (final emoji in activeEmojis) {
    add(emoji);
  }
  for (final group in groups) {
    for (final emoji in group.emojis) {
      add(emoji);
    }
  }
  return List.unmodifiable(merged);
}

List<ServerCustomSticker> _mergeCustomStickerCatalogs(
  List<ServerCustomSticker> activeStickers,
  List<ServerCustomStickerGroup> groups,
) {
  if (groups.isEmpty) {
    return activeStickers;
  }

  final seen = <String>{};
  final merged = <ServerCustomSticker>[];

  void add(ServerCustomSticker sticker) {
    final key =
        '${sticker.networkId ?? ''}/${sticker.serverId ?? ''}/${sticker.id}/${sticker.name.toLowerCase()}';
    if (seen.add(key)) {
      merged.add(sticker);
    }
  }

  for (final sticker in activeStickers) {
    add(sticker);
  }
  for (final group in groups) {
    for (final sticker in group.stickers) {
      add(sticker);
    }
  }
  return List.unmodifiable(merged);
}

Map<String, CustomExpressionSource> _customExpressionSourcesByAsset({
  required List<ServerCustomEmojiGroup> emojiGroups,
  required List<ServerCustomStickerGroup> stickerGroups,
}) {
  final sources = <String, CustomExpressionSource>{};

  void addSource({
    required CustomExpressiveAsset asset,
    required String serverId,
    required String networkId,
    required String label,
    required String? iconUrl,
    required ServerMediaPolicy? mediaPolicy,
  }) {
    sources.putIfAbsent(
      customExpressionSourceKey(asset),
      () => CustomExpressionSource(
        serverId: serverId,
        networkId: networkId,
        label: label,
        iconUrl: iconUrl,
        mediaPolicy: mediaPolicy,
      ),
    );
  }

  for (final group in emojiGroups) {
    for (final emoji in group.emojis) {
      addSource(
        asset: emoji,
        serverId: group.serverId,
        networkId: group.networkId,
        label: group.label,
        iconUrl: group.iconUrl,
        mediaPolicy: group.mediaPolicy,
      );
    }
  }
  for (final group in stickerGroups) {
    for (final sticker in group.stickers) {
      addSource(
        asset: sticker,
        serverId: group.serverId,
        networkId: group.networkId,
        label: group.label,
        iconUrl: group.iconUrl,
        mediaPolicy: group.mediaPolicy,
      );
    }
  }

  return Map.unmodifiable(sources);
}

class ChannelHeaderModule extends StatefulWidget {
  const ChannelHeaderModule({
    required this.channelName,
    this.seed,
    this.messages = const [],
    this.members = const [],
    super.key,
  });

  final String channelName;
  final WorkspaceSeed? seed;
  final List<MessageSeed> messages;
  final List<MemberSeed> members;

  @override
  State<ChannelHeaderModule> createState() => _ChannelHeaderModuleState();
}

class _ChannelHeaderModuleState extends State<ChannelHeaderModule> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  var _searchFocused = false;
  var _activeSuggestionIndex = 0;
  var _filters = const <ChatSearchFilter>[];
  var _results = const <MessageSeed>[];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSearch = constraints.maxWidth >= 620;
        final showActions = constraints.maxWidth >= 430;
        final showWelcome = constraints.maxWidth >= 720;
        final searchWidth = constraints.maxWidth >= 900 ? 360.0 : 260.0;
        final actionIconsWidth = showActions ? 78.0 : 0.0;
        final trailingWidth =
            actionIconsWidth + (showSearch ? searchWidth : 0.0);

        return Container(
          key: const ValueKey('workspace-channel-header'),
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: colors.panelRaised,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Text(
                '#',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.textMuted,
                  fontWeight: VerdantFontWeights.medium,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: showWelcome ? 2 : 1,
                      child: Container(
                        key: const ValueKey('channel-header-title-slot'),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.channelName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    if (showWelcome) ...[
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 3,
                        child: Container(
                          key: const ValueKey('channel-header-welcome-slot'),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Welcome to #${widget.channelName}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                key: const ValueKey('channel-header-actions-slot'),
                width: trailingWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showActions) ...[
                      Icon(Icons.push_pin, size: 18, color: colors.textMuted),
                      const SizedBox(width: 18),
                      Icon(Icons.groups, color: colors.accent, size: 24),
                      const SizedBox(width: 18),
                    ],
                    if (showSearch)
                      SizedBox(
                        width: searchWidth,
                        child: _MessageSearchBox(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          focused: _searchFocused,
                          filters: _filters,
                          results: _results,
                          suggestions: _suggestions,
                          activeSuggestionIndex: _activeSuggestionIndex,
                          onFocused: (focused) =>
                              setState(() => _searchFocused = focused),
                          onChanged: _handleSearchChanged,
                          onKeyEvent: _handleSearchKeyEvent,
                          onSelectSuggestion: _selectSuggestion,
                          onRemoveFilter: _removeFilter,
                          onClear: _clearSearch,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<ChatSearchSuggestion> get _suggestions {
    final text = _searchController.text;
    final prefix = detectChatSearchPrefix(text);
    if (prefix == null) {
      final operator = detectChatSearchOperatorSuggestion(text);
      return operator == null
          ? const []
          : [ChatSearchSuggestion.operator(operator)];
    }
    final seed = widget.seed;
    if (seed == null) {
      return const [];
    }
    if (prefix.type == ChatSearchTargetType.channel) {
      return chatChannelSearchSuggestions(
        channels: seed.channels,
        partial: prefix.partial,
      );
    }
    return chatMemberSearchSuggestions(
      members: widget.members,
      partial: prefix.partial,
    );
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final suggestions = _suggestions;
    if (suggestions.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _activeSuggestionIndex =
              (_activeSuggestionIndex + 1) % suggestions.length;
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _activeSuggestionIndex =
              (_activeSuggestionIndex - 1 + suggestions.length) %
              suggestions.length;
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.tab ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _selectSuggestion(suggestions[_activeSuggestionIndex]);
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _clearSearch();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _searchController.text.isEmpty &&
        _filters.isNotEmpty) {
      _removeFilter(_filters.length - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _refreshSearchResults();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleSearchChanged(String value) {
    final sanitized = sanitizeSearchInput(value);
    if (sanitized != value) {
      _searchController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
    setState(() {
      _searchFocused = true;
      _activeSuggestionIndex = 0;
      _results = detectChatSearchPrefix(sanitized) == null
          ? searchHydratedChatMessages(
              messages: widget.messages,
              query: sanitized,
              filters: _filters,
            )
          : const [];
    });
  }

  void _selectSuggestion(ChatSearchSuggestion suggestion) {
    final selection = applyChatSearchSuggestion(
      query: _searchController.text,
      suggestion: suggestion,
      filters: _filters,
    );
    setState(() {
      _filters = selection.filters;
      _activeSuggestionIndex = 0;
      _searchController.value = TextEditingValue(
        text: selection.query,
        selection: TextSelection.collapsed(offset: selection.query.length),
      );
      _results = searchHydratedChatMessages(
        messages: widget.messages,
        query: selection.query,
        filters: _filters,
      );
    });
    _searchFocusNode.requestFocus();
  }

  void _removeFilter(int index) {
    setState(() {
      _filters = [
        for (var i = 0; i < _filters.length; i += 1)
          if (i != index) _filters[i],
      ];
      _results = searchHydratedChatMessages(
        messages: widget.messages,
        query: _searchController.text,
        filters: _filters,
      );
    });
  }

  void _clearSearch() {
    setState(() {
      _filters = const [];
      _results = const [];
      _searchController.clear();
      _activeSuggestionIndex = 0;
    });
  }

  void _refreshSearchResults() {
    setState(() {
      _results = searchHydratedChatMessages(
        messages: widget.messages,
        query: _searchController.text,
        filters: _filters,
      );
    });
  }
}

class _MessageSearchBox extends StatelessWidget {
  const _MessageSearchBox({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.filters,
    required this.results,
    required this.suggestions,
    required this.activeSuggestionIndex,
    required this.onFocused,
    required this.onChanged,
    required this.onKeyEvent,
    required this.onSelectSuggestion,
    required this.onRemoveFilter,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final List<ChatSearchFilter> filters;
  final List<MessageSeed> results;
  final List<ChatSearchSuggestion> suggestions;
  final int activeSuggestionIndex;
  final ValueChanged<bool> onFocused;
  final ValueChanged<String> onChanged;
  final FocusOnKeyEventCallback onKeyEvent;
  final ValueChanged<ChatSearchSuggestion> onSelectSuggestion;
  final ValueChanged<int> onRemoveFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final query = controller.text.trim();
    final showPanel =
        focused &&
        (suggestions.isNotEmpty || results.isNotEmpty || query.isNotEmpty);
    return Focus(
      onKeyEvent: onKeyEvent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: const ValueKey('channel-message-search-box'),
            height: 34,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: VerdantRadii.sharp,
              border: Border.all(
                color: focused ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search, size: 16, color: colors.textMuted),
                for (var i = 0; i < filters.length; i += 1)
                  _SearchFilterPill(
                    filter: filters[i],
                    onRemove: () => onRemoveFilter(i),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      key: const ValueKey('channel-message-search-field'),
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onTap: () => onFocused(true),
                      onEditingComplete: () {},
                      cursorColor: colors.action,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: verdantBareInputDecoration(
                        context,
                        hintText: filters.isEmpty
                            ? 'Search messages...'
                            : 'Search...',
                        hintStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: colors.text),
                    ),
                  ),
                ),
                if (query.isNotEmpty || filters.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    iconSize: 14,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          if (showPanel)
            Positioned(
              top: 40,
              right: 0,
              width: 360,
              child: _SearchPanel(
                suggestions: suggestions,
                results: results,
                activeSuggestionIndex: activeSuggestionIndex,
                query: query,
                onSelectSuggestion: onSelectSuggestion,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchFilterPill extends StatelessWidget {
  const _SearchFilterPill({required this.filter, required this.onRemove});

  final ChatSearchFilter filter;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final prefix = filter.type == ChatSearchTargetType.user ? 'from:' : 'in:';
    return Container(
      key: ValueKey('chat-search-filter-${filter.type}-${filter.id}'),
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.actionMuted,
        borderRadius: VerdantRadii.sharp,
        border: Border.all(color: colors.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$prefix ${filter.label}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.accentStrong),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.suggestions,
    required this.results,
    required this.activeSuggestionIndex,
    required this.query,
    required this.onSelectSuggestion,
  });

  final List<ChatSearchSuggestion> suggestions;
  final List<MessageSeed> results;
  final int activeSuggestionIndex;
  final String query;
  final ValueChanged<ChatSearchSuggestion> onSelectSuggestion;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: VerdantRadii.sharp,
          border: Border.all(color: colors.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: suggestions.isNotEmpty
            ? _SearchSuggestionList(
                suggestions: suggestions,
                activeSuggestionIndex: activeSuggestionIndex,
                onSelectSuggestion: onSelectSuggestion,
              )
            : _SearchResultsList(results: results, query: query),
      ),
    );
  }
}

class _SearchSuggestionList extends StatelessWidget {
  const _SearchSuggestionList({
    required this.suggestions,
    required this.activeSuggestionIndex,
    required this.onSelectSuggestion,
  });

  final List<ChatSearchSuggestion> suggestions;
  final int activeSuggestionIndex;
  final ValueChanged<ChatSearchSuggestion> onSelectSuggestion;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        final active = index == activeSuggestionIndex;
        final operator = suggestion.operator;
        return InkWell(
          onTap: () => onSelectSuggestion(suggestion),
          child: Container(
            color: active ? colors.desktopHoverOverlay : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  suggestion.type == ChatSearchTargetType.user
                      ? Icons.person
                      : Icons.tag,
                  size: 16,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 10),
                if (operator != null) ...[
                  Text(
                    operator,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.accentStrong,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suggestion.targetLabel ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else
                  Expanded(
                    child: Text(
                      suggestion.label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({required this.results, required this.query});

  final List<MessageSeed> results;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          query.isEmpty
              ? 'Type to search · in: channel · from: user'
              : 'No messages found',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: results.length,
      separatorBuilder: (context, _) =>
          Divider(height: 1, color: colors.border),
      itemBuilder: (context, index) {
        final message = results[index];
        return Padding(
          key: ValueKey('chat-search-result-${message.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message.author,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    message.time,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                message.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.seed,
    required this.messages,
    required this.channelName,
    required this.isLoading,
    required this.error,
    required this.identityMembers,
    required this.typingMembers,
    required this.hasOlderMessages,
    required this.isLoadingOlderMessages,
    required this.timestampOptions,
    required this.linkPreviewService,
    required this.customEmojis,
    required this.customStickers,
    required this.customExpressionSources,
    required this.onReplyMessage,
    this.onDeleteMessage,
    this.onLoadOlderMessages,
    this.onSetReaction,
    this.onPreviewInvite,
    this.onAcceptInvite,
    this.onPrepareMemberProfile,
  });

  final WorkspaceSeed seed;
  final List<MessageSeed> messages;
  final String channelName;
  final bool isLoading;
  final String? error;
  final List<MemberSeed>? identityMembers;
  final List<MemberSeed> typingMembers;
  final bool hasOlderMessages;
  final bool isLoadingOlderMessages;
  final ChatTimestampFormatOptions? timestampOptions;
  final MessageLinkPreviewService? linkPreviewService;
  final List<ServerCustomEmoji> customEmojis;
  final List<ServerCustomSticker> customStickers;
  final Map<String, CustomExpressionSource> customExpressionSources;
  final ValueChanged<MessageSeed> onReplyMessage;
  final ValueChanged<MessageSeed>? onDeleteMessage;
  final Future<void> Function()? onLoadOlderMessages;
  final ServerReactionChangeHandler? onSetReaction;
  final ChatInvitePreviewHandler? onPreviewInvite;
  final ChatInviteAcceptHandler? onAcceptInvite;
  final FutureOr<MemberSeed> Function(MemberSeed member)?
  onPrepareMemberProfile;

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return const _ChatStatus(label: 'Loading messages', showProgress: true);
    }
    final error = this.error;
    if (error != null && messages.isEmpty) {
      return _ChatStatus(label: error);
    }
    if (messages.isEmpty) {
      return _ChatStatus(label: 'No messages yet in #$channelName');
    }
    final timeline = Column(
      children: [
        Expanded(
          child: MessageTimeline(
            messages: messages,
            beginningLabel: 'Beginning of #$channelName',
            pageStorageKey:
                'chat-message-timeline-${seed.networkId}-${seed.serverId}-$channelName',
            bottomPadding: 14,
            mediaPolicy: seed.mediaPolicy,
            networkId: seed.networkId,
            members: identityMembers ?? seed.members,
            timestampOptions: timestampOptions,
            linkPreviewService: linkPreviewService,
            customEmojis: customEmojis,
            customStickers: customStickers,
            customExpressionSources: customExpressionSources,
            hasOlderMessages: hasOlderMessages,
            isLoadingOlderMessages: isLoadingOlderMessages,
            canManageMessages: seed.serverSettings.canManageMessages,
            onLoadOlderMessages: onLoadOlderMessages,
            onReplyMessage: onReplyMessage,
            onDeleteMessage: onDeleteMessage,
            onSetReaction: onSetReaction,
            onPreviewInvite: onPreviewInvite,
            onAcceptInvite: onAcceptInvite,
            onPrepareMemberProfile: onPrepareMemberProfile,
          ),
        ),
        _TypingIndicatorStrip(members: typingMembers),
      ],
    );
    if (!isLoading && error == null) {
      return timeline;
    }
    return Stack(
      children: [
        timeline,
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _ChatLoadingBanner(
            label: error ?? 'Loading channel',
            showProgress: isLoading,
          ),
        ),
      ],
    );
  }
}

class _ChatLoadingBanner extends StatelessWidget {
  const _ChatLoadingBanner({required this.label, required this.showProgress});

  final String label;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Align(
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
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicatorStrip extends StatelessWidget {
  const _TypingIndicatorStrip({required this.members});

  final List<MemberSeed> members;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('chat-typing-strip'),
      height: _typingIndicatorStripHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: members.isEmpty
            ? const SizedBox(key: ValueKey('chat-typing-strip-empty'))
            : _TypingIndicator(
                key: const ValueKey('chat-typing-indicator'),
                members: members,
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.members, super.key});

  final List<MemberSeed> members;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncDotAnimation();
  }

  @override
  void didUpdateWidget(covariant _TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDotAnimation();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  void _syncDotAnimation() {
    if (widget.members.isEmpty) {
      _dotController.stop();
      return;
    }
    if (!_dotController.isAnimating) {
      _dotController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = VerdantThemeColors.of(context);
    final names = widget.members
        .map((member) => member.name)
        .toList(growable: false);
    final text = names.length == 1
        ? '${names.single} is typing'
        : names.length == 2
        ? '${names[0]} and ${names[1]} are typing'
        : '${names[0]} and ${names.length - 1} others are typing';
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.panelRaised.withValues(alpha: 0.92),
              borderRadius: VerdantRadii.sharp,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.text,
                      fontWeight: VerdantFontWeights.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _TypingDots(animation: _dotController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index += 1)
              Opacity(
                key: ValueKey('typing-dot-$index'),
                opacity: _dotOpacity(index),
                child: Text(
                  '.',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: VerdantFontWeights.black,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _dotOpacity(int index) {
    final phase = (animation.value + index * 0.22) % 1;
    return 0.35 + 0.65 * (1 - (phase - 0.5).abs() * 2);
  }
}

String _selectedChannelName(WorkspaceSeed seed) {
  final selectedChannels = seed.channels
      .where((channel) => channel.selected)
      .toList(growable: false);
  return selectedChannels.isEmpty ? 'general' : selectedChannels.first.name;
}

class _ChatStatus extends StatelessWidget {
  const _ChatStatus({required this.label, this.showProgress = false});

  final String label;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
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
              Icon(
                Icons.chat_bubble_outline,
                color: colors.textMuted,
                size: 34,
              ),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
