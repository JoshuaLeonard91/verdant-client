import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/member_profile_popover.dart';
import '../workspace_seed.dart';

typedef MemberContextMenuCallback =
    void Function(MemberSeed member, Offset globalPosition);
typedef MemberProfilePrepareCallback =
    FutureOr<MemberSeed> Function(MemberSeed member);

class ContextWorkspace extends StatefulWidget {
  const ContextWorkspace({
    required this.members,
    required this.width,
    this.activeMembers,
    this.isLoading = false,
    this.mediaPolicy = const ServerMediaPolicy(
      allowedOrigins: {},
      allowLocalHttp: false,
    ),
    this.onOpenMemberContextMenu,
    this.onPrepareMemberProfile,
    super.key,
  });

  final List<MemberSeed> members;
  final List<MemberSeed>? activeMembers;
  final double width;
  final bool isLoading;
  final ServerMediaPolicy mediaPolicy;
  final MemberContextMenuCallback? onOpenMemberContextMenu;
  final MemberProfilePrepareCallback? onPrepareMemberProfile;

  @override
  State<ContextWorkspace> createState() => _ContextWorkspaceState();
}

class _ContextWorkspaceState extends State<ContextWorkspace> {
  var _showAllMembers = false;
  OverlayEntry? _profileEntry;
  var _profileRequestSerial = 0;

  @override
  void dispose() {
    _removeProfilePopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final sourceActiveMembers = widget.activeMembers == null
        ? widget.members
        : widget.activeMembers!;
    final activeMembers = sourceActiveMembers
        .where(_isActiveChannelMember)
        .toList(growable: false);
    final shownMembers = _showAllMembers ? widget.members : activeMembers;
    final sectionCounts = _sectionCounts(shownMembers);
    final header = _showAllMembers ? 'All members' : 'Active in this channel';
    final footer = _showAllMembers ? 'View Active Channel' : 'View All Members';

    return SizedBox(
      width: widget.width,
      child: DecoratedBox(
        key: const ValueKey('context-workspace-surface'),
        decoration: BoxDecoration(color: colors.panel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Text(
                header,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Divider(color: colors.border, height: 1),
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  key: const ValueKey('context-members-list-switcher'),
                  duration: const Duration(milliseconds: 230),
                  reverseDuration: const Duration(milliseconds: 190),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final direction = _showAllMembers ? 1.0 : -1.0;
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0.12 * direction, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _MembersBody(
                    key: ValueKey(
                      _showAllMembers
                          ? 'context-members-body-all'
                          : 'context-members-body-active',
                    ),
                    members: shownMembers,
                    sectionCounts: sectionCounts,
                    isLoading: widget.isLoading,
                    isAllMembers: _showAllMembers,
                    mediaPolicy: widget.mediaPolicy,
                    onOpenMemberContextMenu: widget.onOpenMemberContextMenu,
                    onOpenProfile: _showProfilePopover,
                  ),
                ),
              ),
            ),
            Divider(color: colors.border, height: 1),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('context-members-toggle'),
                onTap: () {
                  setState(() => _showAllMembers = !_showAllMembers);
                },
                hoverColor: colors.panelHover.withValues(alpha: 0.66),
                splashColor: colors.accent.withValues(alpha: 0.12),
                child: SizedBox(
                  height: 54,
                  child: Center(
                    child: Text(
                      footer,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfilePopover(MemberSeed member, Rect anchorRect) async {
    _removeProfilePopover();
    final requestSerial = ++_profileRequestSerial;
    final prepare = widget.onPrepareMemberProfile;
    final prepared = prepare == null
        ? member
        : await Future<MemberSeed>.value(prepare(member));
    if (!mounted || requestSerial != _profileRequestSerial) {
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (context) {
        return MemberIdentityPopoverOverlay(
          member: prepared,
          mediaPolicy: widget.mediaPolicy,
          anchorRect: anchorRect,
          side: MemberIdentityPopoverSide.left,
          onDismiss: _removeProfilePopover,
        );
      },
    );
    _profileEntry = entry;
    overlay.insert(entry);
  }

  void _removeProfilePopover() {
    _profileRequestSerial += 1;
    _profileEntry?.remove();
    _profileEntry = null;
  }
}

class _MembersBody extends StatelessWidget {
  const _MembersBody({
    required this.members,
    required this.sectionCounts,
    required this.isLoading,
    required this.isAllMembers,
    required this.mediaPolicy,
    required this.onOpenMemberContextMenu,
    required this.onOpenProfile,
    super.key,
  });

  final List<MemberSeed> members;
  final Map<String, int> sectionCounts;
  final bool isLoading;
  final bool isAllMembers;
  final ServerMediaPolicy mediaPolicy;
  final MemberContextMenuCallback? onOpenMemberContextMenu;
  final Future<void> Function(MemberSeed member, Rect anchorRect) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    if (isLoading && members.isEmpty) {
      return const _ContextStatus(label: 'Loading members', showProgress: true);
    }
    if (members.isEmpty) {
      return _ContextStatus(
        label: isAllMembers ? 'Members will appear here' : 'No active members',
      );
    }
    return ListView.builder(
      key: ValueKey(
        isAllMembers
            ? 'context-all-members-list'
            : 'context-active-members-list',
      ),
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 18),
      itemCount: members.length,
      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
      itemBuilder: (context, index) {
        final member = members[index];
        final showSection =
            index == 0 ||
            _sectionLabel(members[index - 1]) != _sectionLabel(member);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSection)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
                child: Text(
                  '${_sectionLabel(member)} - ${sectionCounts[_sectionLabel(member)] ?? 0}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            _MemberRow(
              member: member,
              mediaPolicy: mediaPolicy,
              onOpenContextMenu: onOpenMemberContextMenu,
              onOpenProfile: onOpenProfile,
            ),
          ],
        );
      },
    );
  }
}

class _MemberRow extends StatefulWidget {
  const _MemberRow({
    required this.member,
    required this.mediaPolicy,
    required this.onOpenContextMenu,
    required this.onOpenProfile,
  });

  final MemberSeed member;
  final ServerMediaPolicy mediaPolicy;
  final MemberContextMenuCallback? onOpenContextMenu;
  final Future<void> Function(MemberSeed member, Rect anchorRect) onOpenProfile;

  @override
  State<_MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends State<_MemberRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final member = widget.member;
    final memberId = member.id ?? member.name;
    final inactive = memberStatusIsOffline(member.status);
    final memberListBannerUrl = member.memberListBannerUrl;
    return Opacity(
      opacity: inactive ? 0.56 : 1,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) {
          setState(() => _hovered = false);
        },
        child: GestureDetector(
          key: ValueKey('context-member-row-$memberId'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final rect = _globalRect();
            if (rect != null) {
              unawaited(widget.onOpenProfile(member, rect));
            }
          },
          onSecondaryTapDown: (details) {
            widget.onOpenContextMenu?.call(member, details.globalPosition);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            height: 64,
            margin: const EdgeInsets.symmetric(vertical: 2),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _hovered
                  ? colors.panelHover.withValues(alpha: 0.68)
                  : Colors.transparent,
              borderRadius: VerdantRadii.sharp,
            ),
            child: Stack(
              children: [
                if (memberListBannerUrl != null)
                  Positioned.fill(
                    child: Stack(
                      key: ValueKey('context-member-banner-$memberId'),
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            key: ValueKey(
                              'context-member-banner-opacity-$memberId',
                            ),
                            opacity: _hovered ? 1 : 0.96,
                            child: MemberMediaBanner(
                              member: member,
                              mediaPolicy: widget.mediaPolicy,
                              playAnimatedMedia: _hovered,
                              imageKeyPrefix: 'context-member-banner-image',
                              bannerUrlOverride: memberListBannerUrl,
                              bannerCropOverride: member.memberListBannerCrop,
                              fallbackOpacity: _hovered ? 0.62 : 0.52,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors.panel.withValues(alpha: 0.96),
                                  colors.panel.withValues(alpha: 0.90),
                                  colors.panel.withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                                stops: const [0, 0.24, 0.58, 1],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors.panel.withValues(alpha: 0.18),
                                  Colors.transparent,
                                  colors.panel.withValues(alpha: 0.28),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        key: ValueKey('context-member-status-rail-$memberId'),
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOutCubic,
                        width: 3,
                        height: 38,
                        decoration: BoxDecoration(
                          color: inactive
                              ? Colors.transparent
                              : memberPresenceColor(member.status),
                          borderRadius: VerdantRadii.sharp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      MemberMediaAvatar(
                        member: member,
                        mediaPolicy: widget.mediaPolicy,
                        size: 42,
                        playAnimatedMedia: _hovered,
                        imageKeyPrefix: 'context-member-avatar-image',
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: member.displayColor ?? colors.text,
                                      fontWeight: VerdantFontWeights.medium,
                                      shadows: memberListBannerUrl == null
                                          ? null
                                          : const [
                                              Shadow(
                                                color: Color(0xAA000000),
                                                blurRadius: 6,
                                              ),
                                            ],
                                    ),
                                  ),
                                ),
                                if (_isBotMember(member)) ...[
                                  const SizedBox(width: 7),
                                  DecoratedBox(
                                    key: ValueKey(
                                      'context-member-bot-pill-$memberId',
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.accent.withValues(
                                        alpha: 0.18,
                                      ),
                                      border: Border.all(
                                        color: colors.accentStrong.withValues(
                                          alpha: 0.66,
                                        ),
                                      ),
                                      borderRadius: VerdantRadii.sharp,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        'BOT',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: colors.accentStrong,
                                              fontSize: 9,
                                              letterSpacing: 0.8,
                                              fontWeight:
                                                  VerdantFontWeights.black,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        key: ValueKey('context-member-presence-dot-$memberId'),
                        decoration: BoxDecoration(
                          color: memberPresenceColor(member.status),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Rect? _globalRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _ContextStatus extends StatelessWidget {
  const _ContextStatus({required this.label, this.showProgress = false});

  final String label;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.groups_outlined,
                color: VerdantColors.textMuted,
                size: 30,
              ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _sectionLabel(MemberSeed member) {
  if (memberStatusIsOffline(member.status)) {
    return 'Offline';
  }
  if (member.role.trim().isNotEmpty) {
    return member.role;
  }
  return 'Online';
}

bool _isActiveChannelMember(MemberSeed member) {
  return member.isActive && !memberStatusIsOffline(member.status);
}

bool _isBotMember(MemberSeed member) {
  return member.isBot || member.role.toLowerCase().trim() == 'bot';
}

Map<String, int> _sectionCounts(List<MemberSeed> members) {
  final counts = <String, int>{};
  for (final member in members) {
    final label = _sectionLabel(member);
    counts[label] = (counts[label] ?? 0) + 1;
  }
  return counts;
}
