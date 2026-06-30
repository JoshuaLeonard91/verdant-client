import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/verdant_input_sanitizer.dart';
import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import '../chat_workspace/chat_invite_link.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../server_settings_workspace/server_settings_service.dart';
import 'rail_action_modal_shell.dart';

class JoinServerRailModal extends StatefulWidget {
  const JoinServerRailModal({
    required this.apiOrigin,
    required this.networkLabel,
    required this.onPreview,
    required this.onJoin,
    required this.onOpenExisting,
    super.key,
  });

  final String apiOrigin;
  final String networkLabel;
  final Future<ServerInvitePreview> Function(ChatInviteTarget target) onPreview;
  final Future<ServerSettingsServer> Function(
    ChatInviteTarget target,
    ServerInvitePreview preview,
  )
  onJoin;
  final Future<void> Function(
    ChatInviteTarget target,
    ServerSettingsServer server,
  )
  onOpenExisting;

  @override
  State<JoinServerRailModal> createState() => _JoinServerRailModalState();
}

class _JoinServerRailModalState extends State<JoinServerRailModal> {
  final _inviteController = TextEditingController();
  ServerInvitePreview? _preview;
  ChatInviteTarget? _previewTarget;
  var _isLoading = false;
  var _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final busy = _isLoading || _isJoining;

    return RailActionModalShell(
      key: const ValueKey('join-server-modal'),
      title: 'Join Server',
      icon: PhosphorIconsRegular.arrowRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.networkLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: VerdantColors.accentStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('join-server-invite-field'),
                  controller: _inviteController,
                  autofocus: true,
                  enabled: !busy,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_preview != null) {
                      setState(() {
                        _preview = null;
                        _previewTarget = null;
                        _error = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _previewInvite(),
                  decoration: railActionInputDecoration(
                    label: 'Invite Code',
                    hint: 'code or invite link',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 106,
                child: VerdantButton(
                  key: const ValueKey('join-server-preview-button'),
                  label: 'Go',
                  isBusy: _isLoading,
                  onPressed: busy ? null : _previewInvite,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            RailActionErrorText(_error!),
          ],
          if (preview != null) ...[
            const SizedBox(height: 16),
            _InvitePreviewCard(preview: preview),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: VerdantButton(
                  label: 'Cancel',
                  variant: VerdantButtonVariant.ghost,
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              if (preview != null)
                Expanded(
                  child: VerdantButton(
                    key: const ValueKey('join-server-submit-button'),
                    label: preview.isMember ? 'Open' : 'Join',
                    icon: preview.isMember
                        ? PhosphorIconsRegular.arrowSquareOut
                        : PhosphorIconsRegular.arrowRight,
                    isBusy: _isJoining,
                    onPressed: busy ? null : _joinOrOpen,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _previewInvite() async {
    final target = _extractInviteTarget(_inviteController.text);
    if (target == null) {
      setState(() => _error = 'Enter a valid invite code');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _preview = null;
      _previewTarget = null;
    });
    try {
      final preview = await widget.onPreview(target);
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
        _previewTarget = target;
        _isLoading = false;
      });
    } on ServerSettingsException catch (error) {
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid or expired invite';
      });
    }
  }

  Future<void> _joinOrOpen() async {
    final preview = _preview;
    final target = _previewTarget;
    if (preview == null || target == null) {
      return;
    }
    setState(() {
      _isJoining = true;
      _error = null;
    });
    try {
      final server = preview.isMember
          ? preview.server
          : await widget.onJoin(target, preview);
      if (preview.isMember) {
        await widget.onOpenExisting(target, server);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(server);
    } on ServerSettingsException catch (error) {
      setState(() {
        _isJoining = false;
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _isJoining = false;
        _error = 'Could not join server';
      });
    }
  }

  ChatInviteTarget? _extractInviteTarget(String raw) {
    final trimmed = sanitizeUrlInput(raw);
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      final targets = extractChatInviteTargets(trimmed, max: 1);
      if (targets.isEmpty) {
        return null;
      }
      return targets.single;
    }
    if (trimmed.startsWith('/')) {
      final targets = extractChatInviteTargets(trimmed, max: 1);
      if (targets.isEmpty) {
        return null;
      }
      return ChatInviteTarget(
        code: targets.single.code,
        apiOrigin: widget.apiOrigin,
      );
    }
    if (trimmed.contains('/') || trimmed.contains('\\')) {
      return null;
    }
    final code = sanitizeInviteCodeInput(trimmed);
    return code.isEmpty
        ? null
        : ChatInviteTarget(code: code, apiOrigin: widget.apiOrigin);
  }
}

class _InvitePreviewCard extends StatelessWidget {
  const _InvitePreviewCard({required this.preview});

  final ServerInvitePreview preview;

  @override
  Widget build(BuildContext context) {
    final initials = preview.server.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Container(
      key: const ValueKey('join-server-preview-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VerdantColors.background,
        border: Border.all(color: VerdantColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            color: VerdantColors.panelRaised,
            child: Text(
              initials.length > 3 ? initials.substring(0, 3) : initials,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: VerdantColors.accentStrong,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.server.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 3),
                Text(
                  '${preview.server.memberCount} members - invited by ${preview.inviterUsername}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (preview.isMember)
                  Text(
                    'Already joined',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: VerdantColors.accentStrong,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
