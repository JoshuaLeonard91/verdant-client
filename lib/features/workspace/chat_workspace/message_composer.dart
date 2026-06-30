import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/custom_expressive_asset.dart';
import '../shared/member_profile_popover.dart';
import '../workspace_seed.dart';
import 'emoji_picker_popover.dart';
import 'klipy_media_repository.dart';
import 'klipy_media_picker.dart';
import 'message_mentions.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    this.hintText = 'Message #general',
    this.replyingTo,
    this.networkId,
    this.serverId,
    this.mentionMembers = const [],
    this.onCancelReply,
    this.onSubmit,
    this.onTyping,
    this.mediaPolicy = const ServerMediaPolicy(
      allowedOrigins: {},
      allowLocalHttp: false,
    ),
    this.klipyRepository = const SeededKlipyMediaRepository(),
    this.customEmojis = const [],
    this.customEmojiGroups = const [],
    this.customStickers = const [],
    this.customStickerGroups = const [],
    super.key,
  });

  final String hintText;
  final MessageSeed? replyingTo;
  final String? networkId;
  final String? serverId;
  final List<MemberSeed> mentionMembers;
  final VoidCallback? onCancelReply;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onTyping;
  final ServerMediaPolicy mediaPolicy;
  final KlipyMediaRepository klipyRepository;
  final List<ServerCustomEmoji> customEmojis;
  final List<ServerCustomEmojiGroup> customEmojiGroups;
  final List<ServerCustomSticker> customStickers;
  final List<ServerCustomStickerGroup> customStickerGroups;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

enum _ComposerPicker { emoji, klipy }

const _maxMentionSuggestions = 10;

final _mentionTriggerPattern = RegExp(r'(^|\s)@([A-Za-z0-9_]{0,32})$');

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _composerLink = LayerLink();
  OverlayEntry? _pickerEntry;
  _ComposerPicker? _activePicker;
  _MentionRange? _mentionRange;
  var _activeMentionIndex = 0;

  @override
  void dispose() {
    _removePicker();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final showKlipy = constraints.maxWidth >= 340;
        final showSendLabel = constraints.maxWidth >= 480;
        final reply = replyingTo;
        final mentionSuggestions = _mentionSuggestions;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: CompositedTransformTarget(
            link: _composerLink,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mentionSuggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _MentionSuggestionsPanel(
                      suggestions: mentionSuggestions,
                      mediaPolicy: widget.mediaPolicy,
                      activeIndex: _activeMentionIndex.clamp(
                        0,
                        mentionSuggestions.length - 1,
                      ),
                      onHover: (index) =>
                          setState(() => _activeMentionIndex = index),
                      onSelect: _selectMention,
                    ),
                  ),
                DecoratedBox(
                  key: const ValueKey('message-composer-frame'),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: VerdantRadii.sharp,
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reply != null)
                        _ReplyTargetBar(
                          message: reply,
                          onCancel: onCancelReply ?? () {},
                        ),
                      Container(
                        constraints: const BoxConstraints(minHeight: 82),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 58,
                                child: GestureDetector(
                                  key: const ValueKey(
                                    'composer-message-hit-target',
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _focusNode.requestFocus,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Focus(
                                      onKeyEvent: _handleComposerKeyEvent,
                                      child: CallbackShortcuts(
                                        bindings: {
                                          const SingleActivator(
                                            LogicalKeyboardKey.enter,
                                          ): _submitCurrentText,
                                        },
                                        child: TextField(
                                          key: const ValueKey(
                                            'composer-message-field',
                                          ),
                                          controller: _controller,
                                          focusNode: _focusNode,
                                          onChanged: _handleChanged,
                                          onSubmitted: (_) =>
                                              _submitCurrentText(),
                                          textInputAction: TextInputAction.done,
                                          keyboardType: TextInputType.multiline,
                                          minLines: 1,
                                          maxLines: 4,
                                          cursorColor: colors.action,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: colors.text),
                                          decoration:
                                              verdantBareInputDecoration(
                                                context,
                                                hintText: hintText,
                                                hintStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: colors.textMuted,
                                                      fontSize: 16,
                                                    ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (showKlipy)
                              TextButton(
                                key: const ValueKey('composer-klipy-button'),
                                onPressed: () =>
                                    _togglePicker(_ComposerPicker.klipy),
                                child: Text(
                                  'KLIPY',
                                  style: TextStyle(
                                    fontWeight: VerdantFontWeights.black,
                                    color:
                                        _activePicker == _ComposerPicker.klipy
                                        ? colors.action
                                        : colors.accentStrong,
                                  ),
                                ),
                              ),
                            IconButton(
                              key: const ValueKey('composer-emoji-button'),
                              onPressed: () =>
                                  _togglePicker(_ComposerPicker.emoji),
                              tooltip: 'Emoji',
                              icon: Icon(
                                Icons.emoji_emotions,
                                color: _activePicker == _ComposerPicker.emoji
                                    ? colors.action
                                    : colors.textMuted,
                              ),
                            ),
                            VerticalDivider(color: colors.border, width: 18),
                            if (showSendLabel)
                              TextButton(
                                key: const ValueKey('composer-send-button'),
                                onPressed: _canSubmit
                                    ? () => _submitText(_controller.text)
                                    : null,
                                child: const Text('Send'),
                              )
                            else
                              IconButton(
                                key: const ValueKey(
                                  'composer-send-icon-button',
                                ),
                                onPressed: _canSubmit
                                    ? () => _submitText(_controller.text)
                                    : null,
                                tooltip: 'Send',
                                icon: const Icon(Icons.send, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  MessageSeed? get replyingTo => widget.replyingTo;
  String get hintText => widget.hintText;
  VoidCallback? get onCancelReply => widget.onCancelReply;

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  List<_MentionSuggestion> get _mentionSuggestions {
    final range = _mentionRange;
    if (range == null) {
      return const [];
    }
    final lower = range.query.toLowerCase();
    final suggestions = <_MentionSuggestion>[];
    final mentionMembers = normalizedMentionMembers(
      members: widget.mentionMembers,
      networkId: widget.networkId,
    );
    for (final member in mentionMembers) {
      final localUserId = messageMentionLocalUserId(member, widget.networkId);
      if (localUserId == null) {
        continue;
      }
      final username = _mentionUsernameLabel(member);
      if (!username.toLowerCase().startsWith(lower) &&
          !member.name.toLowerCase().startsWith(lower)) {
        continue;
      }
      suggestions.add(
        _MentionSuggestion.member(localUserId: localUserId, member: member),
      );
      if (suggestions.length >= _maxMentionSuggestions) {
        break;
      }
    }
    if (suggestions.length < _maxMentionSuggestions &&
        'everyone'.startsWith(lower)) {
      suggestions.add(_MentionSuggestion.everyone('everyone'));
    }
    if (suggestions.length < _maxMentionSuggestions &&
        'here'.startsWith(lower)) {
      suggestions.add(_MentionSuggestion.everyone('here'));
    }
    return suggestions;
  }

  void _handleChanged(String value) {
    final previousQuery = _mentionRange?.query;
    _mentionRange = _detectMentionRange();
    if (_mentionRange?.query != previousQuery) {
      _activeMentionIndex = 0;
    }
    if (value.trim().isNotEmpty) {
      widget.onTyping?.call();
    }
    setState(() {});
  }

  KeyEventResult _handleComposerKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final suggestions = _mentionSuggestions;
    if (suggestions.isEmpty) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _activeMentionIndex = (_activeMentionIndex + 1) % suggestions.length;
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _activeMentionIndex =
              (_activeMentionIndex - 1 + suggestions.length) %
              suggestions.length;
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.tab:
      case LogicalKeyboardKey.enter:
        _selectMention(
          suggestions[_activeMentionIndex.clamp(0, suggestions.length - 1)],
        );
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        setState(() {
          _mentionRange = null;
          _activeMentionIndex = 0;
        });
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _togglePicker(_ComposerPicker picker) {
    if (_activePicker == picker) {
      _hidePicker();
      return;
    }
    _showPicker(picker);
  }

  void _showPicker(_ComposerPicker picker) {
    _removePicker();
    setState(() => _activePicker = picker);
    _pickerEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hidePicker,
              ),
            ),
            CompositedTransformFollower(
              link: _composerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.bottomRight,
              offset: const Offset(-12, -6),
              child: Material(
                color: Colors.transparent,
                child: _pickerFor(picker),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_pickerEntry!);
  }

  Widget _pickerFor(_ComposerPicker picker) {
    return switch (picker) {
      _ComposerPicker.emoji => EmojiPickerPopover(
        customEmojis: widget.customEmojis,
        customEmojiGroups: _activeCustomEmojiGroups(),
        customStickers: widget.customStickers,
        customStickerGroups: _activeCustomStickerGroups(),
        mediaPolicy: widget.mediaPolicy,
        onSelected: _insertEmoji,
      ),
      _ComposerPicker.klipy => KlipyMediaPicker(
        repository: widget.klipyRepository,
        mediaPolicy: widget.mediaPolicy,
        onSelected: _submitKlipyMedia,
      ),
    };
  }

  void _insertEmoji(String emoji) {
    final selection = _controller.selection;
    final text = _controller.text;
    final start = selection.isValid
        ? selection.start.clamp(0, text.length)
        : text.length;
    final end = selection.isValid ? selection.end.clamp(0, text.length) : start;
    final next = text.replaceRange(start, end, emoji);
    final caret = start + emoji.length;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret),
    );
    _hidePicker();
    _focusNode.requestFocus();
    setState(() {});
  }

  void _submitKlipyMedia(KlipyMediaItem item) {
    _hidePicker();
    _submitText(item.originalUrl);
  }

  void _submitCurrentText() {
    final suggestions = _mentionSuggestions;
    if (suggestions.isNotEmpty) {
      _selectMention(
        suggestions[_activeMentionIndex.clamp(0, suggestions.length - 1)],
      );
      return;
    }
    _submitText(_controller.text);
  }

  void _submitText(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return;
    }
    widget.onSubmit?.call(text);
    _controller.clear();
    _mentionRange = null;
    _activeMentionIndex = 0;
    widget.onCancelReply?.call();
    _focusNode.requestFocus();
    setState(() {});
  }

  _MentionRange? _detectMentionRange() {
    final selection = _controller.selection;
    final text = _controller.text;
    if (!selection.isValid || !selection.isCollapsed) {
      return null;
    }
    final offset = selection.baseOffset.clamp(0, text.length);
    final beforeCursor = text.substring(0, offset);
    final match = _mentionTriggerPattern.firstMatch(beforeCursor);
    if (match == null) {
      return null;
    }
    final leading = match.group(1) ?? '';
    final query = match.group(2) ?? '';
    final start = match.start + leading.length;
    return _MentionRange(start: start, end: offset, query: query);
  }

  void _selectMention(_MentionSuggestion suggestion) {
    final range = _mentionRange;
    if (range == null) {
      return;
    }
    final text = _controller.text;
    final start = range.start.clamp(0, text.length);
    final end = range.end.clamp(start, text.length);
    final replacement = '${suggestion.token} ';
    final next = text.replaceRange(start, end, replacement);
    final caret = start + replacement.length;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret),
    );
    setState(() {
      _mentionRange = null;
      _activeMentionIndex = 0;
    });
    _focusNode.requestFocus();
  }

  void _hidePicker() {
    _removePicker();
    if (!mounted) {
      return;
    }
    setState(() => _activePicker = null);
  }

  void _removePicker() {
    _pickerEntry?.remove();
    _pickerEntry = null;
  }

  List<ServerCustomEmojiGroup> _activeCustomEmojiGroups() {
    final networkId = widget.networkId;
    final serverId = widget.serverId;
    if (widget.customEmojiGroups.isEmpty ||
        networkId == null ||
        serverId == null) {
      return const [];
    }
    final groups = <ServerCustomEmojiGroup>[];
    for (final group in widget.customEmojiGroups) {
      if (group.networkId != networkId || group.serverId != serverId) {
        continue;
      }
      final emojis = [
        for (final emoji in group.emojis)
          if ((emoji.networkId == null || emoji.networkId == networkId) &&
              (emoji.serverId == null || emoji.serverId == serverId))
            emoji,
      ];
      if (emojis.isEmpty) {
        continue;
      }
      groups.add(
        ServerCustomEmojiGroup(
          serverId: serverId,
          networkId: networkId,
          label: group.label,
          iconUrl: group.iconUrl,
          mediaPolicy: group.mediaPolicy,
          emojis: List.unmodifiable(emojis),
        ),
      );
    }
    return List.unmodifiable(groups);
  }

  List<ServerCustomStickerGroup> _activeCustomStickerGroups() {
    final networkId = widget.networkId;
    final serverId = widget.serverId;
    if (widget.customStickerGroups.isEmpty ||
        networkId == null ||
        serverId == null) {
      return const [];
    }
    final groups = <ServerCustomStickerGroup>[];
    for (final group in widget.customStickerGroups) {
      if (group.networkId != networkId || group.serverId != serverId) {
        continue;
      }
      final stickers = [
        for (final sticker in group.stickers)
          if ((sticker.networkId == null || sticker.networkId == networkId) &&
              (sticker.serverId == null || sticker.serverId == serverId))
            sticker,
      ];
      if (stickers.isEmpty) {
        continue;
      }
      groups.add(
        ServerCustomStickerGroup(
          serverId: serverId,
          networkId: networkId,
          label: group.label,
          iconUrl: group.iconUrl,
          mediaPolicy: group.mediaPolicy,
          stickers: List.unmodifiable(stickers),
        ),
      );
    }
    return List.unmodifiable(groups);
  }
}

class _ReplyTargetBar extends StatelessWidget {
  const _ReplyTargetBar({required this.message, required this.onCancel});

  final MessageSeed message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      key: ValueKey('composer-reply-target-${message.id}'),
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: colors.textMuted, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  const TextSpan(text: 'Replying to '),
                  TextSpan(
                    text: message.author,
                    style: TextStyle(
                      color: colors.name,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: message.body,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: ValueKey('composer-cancel-reply-${message.id}'),
            tooltip: 'Cancel reply',
            onPressed: onCancel,
            icon: Icon(Icons.close, color: colors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MentionSuggestionsPanel extends StatelessWidget {
  const _MentionSuggestionsPanel({
    required this.suggestions,
    required this.mediaPolicy,
    required this.activeIndex,
    required this.onHover,
    required this.onSelect,
  });

  final List<_MentionSuggestion> suggestions;
  final ServerMediaPolicy mediaPolicy;
  final int activeIndex;
  final ValueChanged<int> onHover;
  final ValueChanged<_MentionSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('composer-mention-suggestions'),
        width: 344,
        constraints: const BoxConstraints(maxHeight: 260),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: VerdantRadii.sharp,
          border: Border.all(color: colors.borderStrong),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.52),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: Offset.zero,
            ),
          ],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 5),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return _MentionSuggestionRow(
              key: ValueKey('composer-mention-suggestion-${suggestion.id}'),
              suggestion: suggestion,
              mediaPolicy: mediaPolicy,
              selected: index == activeIndex,
              onHover: () => onHover(index),
              onSelect: () => onSelect(suggestion),
            );
          },
        ),
      ),
    );
  }
}

class _MentionSuggestionRow extends StatelessWidget {
  const _MentionSuggestionRow({
    required this.suggestion,
    required this.mediaPolicy,
    required this.selected,
    required this.onHover,
    required this.onSelect,
    super.key,
  });

  final _MentionSuggestion suggestion;
  final ServerMediaPolicy mediaPolicy;
  final bool selected;
  final VoidCallback onHover;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final member = suggestion.member;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: SizedBox(
          height: 56,
          child: Stack(
            children: [
              if (member != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: selected ? 0.42 : 0.3,
                    child: _MentionSuggestionBanner(
                      key: ValueKey(
                        'composer-mention-suggestion-banner-${suggestion.id}',
                      ),
                      member: member,
                      mediaPolicy: mediaPolicy,
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  key: ValueKey(
                    'composer-mention-suggestion-surface-${suggestion.id}',
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.desktopHoverOverlay.withValues(alpha: 0.78)
                        : colors.background.withValues(alpha: 0.24),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      _MentionSuggestionAvatar(
                        key: ValueKey(
                          'composer-mention-suggestion-avatar-${suggestion.id}',
                        ),
                        suggestion: suggestion,
                        mediaPolicy: mediaPolicy,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          suggestion.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.text,
                                fontWeight: VerdantFontWeights.bold,
                              ),
                        ),
                      ),
                      if (suggestion.detailLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          suggestion.detailLabel,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MentionSuggestionAvatar extends StatelessWidget {
  const _MentionSuggestionAvatar({
    required this.suggestion,
    required this.mediaPolicy,
    super.key,
  });

  final _MentionSuggestion suggestion;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    if (suggestion.kind == _MentionSuggestionKind.everyone) {
      return SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Text(
            '@',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.actionStrong,
              fontWeight: VerdantFontWeights.black,
            ),
          ),
        ),
      );
    }
    final member = suggestion.member;
    if (member != null) {
      return MemberMediaAvatar(
        member: member,
        mediaPolicy: mediaPolicy,
        size: 30,
        playAnimatedMedia: true,
        imageKeyPrefix: 'composer-mention-suggestion-avatar-image',
      );
    }
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.action.withValues(alpha: 0.2),
        borderRadius: VerdantRadii.sharp,
        border: Border.all(color: colors.actionMuted),
      ),
      child: Text(
        suggestion.initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.actionStrong,
          fontWeight: VerdantFontWeights.black,
        ),
      ),
    );
  }
}

class _MentionSuggestionBanner extends StatelessWidget {
  const _MentionSuggestionBanner({
    required this.member,
    required this.mediaPolicy,
    super.key,
  });

  final MemberSeed member;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    return MemberMediaBanner(
      member: member,
      mediaPolicy: mediaPolicy,
      playAnimatedMedia: true,
      imageKeyPrefix: 'composer-mention-suggestion-banner-image',
      fallbackOpacity: 0.86,
      bannerUrlOverride: member.memberListBannerUrl ?? member.bannerUrl,
      bannerCropOverride: member.memberListBannerCrop ?? member.bannerCrop,
    );
  }
}

enum _MentionSuggestionKind { member, everyone }

final class _MentionSuggestion {
  const _MentionSuggestion._({
    required this.id,
    required this.displayName,
    required this.detailLabel,
    required this.token,
    required this.kind,
    this.initials = '@',
    this.member,
  });

  factory _MentionSuggestion.member({
    required String localUserId,
    required MemberSeed member,
  }) {
    final username = _mentionUsernameLabel(member);
    return _MentionSuggestion._(
      id: localUserId,
      displayName: member.name,
      detailLabel: username.isEmpty ? '' : '@$username',
      token: '@$localUserId',
      kind: _MentionSuggestionKind.member,
      initials: member.initials,
      member: member,
    );
  }

  factory _MentionSuggestion.everyone(String name) {
    return _MentionSuggestion._(
      id: name,
      displayName: '@$name',
      detailLabel: '',
      token: '@$name',
      kind: _MentionSuggestionKind.everyone,
    );
  }

  final String id;
  final String displayName;
  final String detailLabel;
  final String token;
  final _MentionSuggestionKind kind;
  final String initials;
  final MemberSeed? member;
}

String _mentionUsernameLabel(MemberSeed member) {
  final username = member.username?.trim();
  if (username == null ||
      username.isEmpty ||
      _looksLikeMentionBackendId(username)) {
    return '';
  }
  return username;
}

bool _looksLikeMentionBackendId(String value) {
  final trimmed = value.trim();
  return RegExp(r'^\d{12,}$').hasMatch(trimmed) ||
      RegExp(r'^user[_-]?\d{6,}$', caseSensitive: false).hasMatch(trimmed);
}

final class _MentionRange {
  const _MentionRange({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;
}
