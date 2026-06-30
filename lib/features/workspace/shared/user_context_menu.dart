import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';

enum WorkspaceUserContextMenuTone { normal, success, warning, danger }

sealed class WorkspaceUserContextMenuEntry {
  const WorkspaceUserContextMenuEntry();
}

final class WorkspaceUserContextMenuDivider
    extends WorkspaceUserContextMenuEntry {
  const WorkspaceUserContextMenuDivider();
}

final class WorkspaceUserContextMenuCustom
    extends WorkspaceUserContextMenuEntry {
  const WorkspaceUserContextMenuCustom({
    required this.child,
    this.estimatedHeight = 78,
  });

  final Widget child;
  final double estimatedHeight;
}

final class WorkspaceUserContextMenuItem extends WorkspaceUserContextMenuEntry {
  const WorkspaceUserContextMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.tone = WorkspaceUserContextMenuTone.normal,
    this.enabled = true,
  });

  final String id;
  final String label;
  final IconData icon;
  final WorkspaceUserContextMenuTone tone;
  final bool enabled;
}

Future<String?> showWorkspaceUserContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required List<WorkspaceUserContextMenuEntry> entries,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<String?>();
  late final OverlayEntry overlayEntry;

  void complete(String? value) {
    if (completer.isCompleted) {
      return;
    }
    overlayEntry.remove();
    completer.complete(value);
  }

  overlayEntry = OverlayEntry(
    builder: (context) {
      return _WorkspaceUserContextMenuOverlay(
        globalPosition: globalPosition,
        entries: entries,
        onSelected: complete,
        onDismiss: () => complete(null),
      );
    },
  );

  overlay.insert(overlayEntry);
  return completer.future;
}

class _WorkspaceUserContextMenuOverlay extends StatelessWidget {
  const _WorkspaceUserContextMenuOverlay({
    required this.globalPosition,
    required this.entries,
    required this.onSelected,
    required this.onDismiss,
  });

  static const _width = 218.0;

  final Offset globalPosition;
  final List<WorkspaceUserContextMenuEntry> entries;
  final ValueChanged<String> onSelected;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    var estimatedHeight = 10.0;
    for (final entry in entries) {
      estimatedHeight += switch (entry) {
        WorkspaceUserContextMenuDivider() => 9.0,
        WorkspaceUserContextMenuItem() => 40.0,
        WorkspaceUserContextMenuCustom(
          estimatedHeight: final customEstimatedHeight,
        ) =>
          customEstimatedHeight,
      };
    }

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            onSecondaryTapDown: (_) => onDismiss(),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxLeft = constraints.maxWidth > _width + 16
                    ? constraints.maxWidth - _width - 8
                    : 8.0;
                final maxTop = constraints.maxHeight > estimatedHeight + 16
                    ? constraints.maxHeight - estimatedHeight - 8
                    : 8.0;
                final left = globalPosition.dx.clamp(8.0, maxLeft).toDouble();
                final top = globalPosition.dy.clamp(8.0, maxTop).toDouble();

                return Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: _width,
                      child: _WorkspaceUserContextMenuPanel(
                        entries: entries,
                        onSelected: onSelected,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceUserContextMenuPanel extends StatelessWidget {
  const _WorkspaceUserContextMenuPanel({
    required this.entries,
    required this.onSelected,
  });

  final List<WorkspaceUserContextMenuEntry> entries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panelRaised,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in entries)
                switch (entry) {
                  WorkspaceUserContextMenuDivider() => Divider(
                    color: colors.border,
                    height: 9,
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                  ),
                  WorkspaceUserContextMenuItem() => _UserContextMenuRow(
                    item: entry,
                    onSelected: onSelected,
                  ),
                  WorkspaceUserContextMenuCustom(:final child) => child,
                },
            ],
          ),
        ),
      ),
    );
  }
}

class _UserContextMenuRow extends StatefulWidget {
  const _UserContextMenuRow({required this.item, required this.onSelected});

  final WorkspaceUserContextMenuItem item;
  final ValueChanged<String> onSelected;

  @override
  State<_UserContextMenuRow> createState() => _UserContextMenuRowState();
}

class _UserContextMenuRowState extends State<_UserContextMenuRow> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final item = widget.item;
    final color = item.enabled
        ? switch (item.tone) {
            WorkspaceUserContextMenuTone.success => colors.accentStrong,
            WorkspaceUserContextMenuTone.warning => const Color(0xFFFFD166),
            WorkspaceUserContextMenuTone.danger => const Color(0xFFFF6B78),
            WorkspaceUserContextMenuTone.normal => colors.textMuted,
          }
        : colors.textMuted.withValues(alpha: 0.48);
    final textColor = item.enabled
        ? switch (item.tone) {
            WorkspaceUserContextMenuTone.danger => const Color(0xFFFF6B78),
            WorkspaceUserContextMenuTone.success => colors.accentStrong,
            WorkspaceUserContextMenuTone.warning => const Color(0xFFFFD166),
            WorkspaceUserContextMenuTone.normal => colors.textMuted,
          }
        : colors.textMuted.withValues(alpha: 0.48);

    final active = item.enabled && (_hovered || _pressed);
    final background = _pressed
        ? colors.accent.withValues(alpha: 0.22)
        : active
        ? colors.panelHover
        : Colors.transparent;
    final borderColor = _pressed
        ? colors.accent.withValues(alpha: 0.42)
        : active
        ? colors.accent.withValues(alpha: 0.28)
        : Colors.transparent;

    return SizedBox(
      key: ValueKey('user-context-menu-item-${item.id}'),
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: MouseRegion(
          opaque: true,
          cursor: item.enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: item.enabled
                ? (_) => setState(() => _pressed = true)
                : null,
            onPointerCancel: item.enabled
                ? (_) => setState(() => _pressed = false)
                : null,
            onPointerUp: item.enabled
                ? (_) => setState(() => _pressed = false)
                : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: item.enabled ? () => widget.onSelected(item.id) : null,
              child: AnimatedContainer(
                key: ValueKey('user-context-menu-item-surface-${item.id}'),
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: borderColor),
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(item.icon, size: 16, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: active
                              ? VerdantFontWeights.bold
                              : VerdantFontWeights.medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
