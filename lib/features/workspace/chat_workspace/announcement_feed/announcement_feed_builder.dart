import 'package:flutter/material.dart';

import '../../../../shared/smooth_single_child_scroll_view.dart';
import '../../../../theme/verdant_theme.dart';
import 'announcement_card_preview.dart';
import 'announcement_content_models.dart';
import 'announcement_feed_builder_controller.dart';

class AnnouncementFeedBuilderPanel extends StatefulWidget {
  const AnnouncementFeedBuilderPanel({
    required this.feedName,
    required this.onClose,
    this.controller,
    this.initialDraft,
    this.onPublish,
    this.submitLabel = 'Publish',
    super.key,
  });

  final String feedName;
  final VoidCallback onClose;
  final AnnouncementFeedBuilderController? controller;
  final FeedAnnouncementDraft? initialDraft;
  final Future<void> Function(FeedAnnouncementDraft draft)? onPublish;
  final String submitLabel;

  @override
  State<AnnouncementFeedBuilderPanel> createState() =>
      _AnnouncementFeedBuilderPanelState();
}

class _AnnouncementFeedBuilderPanelState
    extends State<AnnouncementFeedBuilderPanel> {
  late AnnouncementFeedBuilderController _controller;
  late bool _ownsController;
  bool _isSubmitting = false;
  bool _previewOpen = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        AnnouncementFeedBuilderController(initialDraft: widget.initialDraft);
  }

  @override
  void didUpdateWidget(covariant AnnouncementFeedBuilderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _ownsController = widget.controller == null;
      _controller =
          widget.controller ??
          AnnouncementFeedBuilderController(initialDraft: widget.initialDraft);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      key: const ValueKey('announcement-feed-builder-panel'),
      decoration: BoxDecoration(color: colors.panelRaised),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const ValueKey('announcement-builder-close-button'),
                    tooltip: 'Back to feed',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.arrow_back, size: 18),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return _BuilderEditor(controller: _controller);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final draft = _controller.draft;
                    final canSubmit =
                        widget.onPublish != null &&
                        draft.canSubmit &&
                        !_isSubmitting;
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_submitError != null) ...[
                                Text(
                                  _submitError!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          key: const ValueKey(
                            'announcement-builder-preview-button',
                          ),
                          style: _subtleOutlinedButtonStyle(context),
                          onPressed: () => setState(() => _previewOpen = true),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Preview'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          key: const ValueKey(
                            'announcement-builder-publish-button',
                          ),
                          onPressed: canSubmit
                              ? () => _publish(_controller.draft)
                              : null,
                          icon: const Icon(Icons.campaign_outlined, size: 16),
                          label: Text(
                            widget.onPublish == null
                                ? 'Publish hookup next'
                                : _isSubmitting
                                ? 'Saving...'
                                : widget.submitLabel,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (_previewOpen)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return _BuilderFullPreview(
                    draft: _controller.draft,
                    onClose: () => setState(() => _previewOpen = false),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _publish(FeedAnnouncementDraft draft) async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      await widget.onPublish?.call(draft);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

ButtonStyle _subtleOutlinedButtonStyle(
  BuildContext context, {
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  ),
  Size? minimumSize,
}) {
  final colors = VerdantThemeColors.of(context);
  return OutlinedButton.styleFrom(
    foregroundColor: colors.text,
    side: BorderSide(color: colors.borderStrong),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    minimumSize: minimumSize,
    padding: padding,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return colors.text.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return colors.text.withValues(alpha: 0.07);
      }
      return null;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return BorderSide(color: colors.textMuted.withValues(alpha: 0.9));
      }
      return BorderSide(color: colors.borderStrong);
    }),
  );
}

ButtonStyle _contentBlockButtonStyle(BuildContext context) {
  final colors = VerdantThemeColors.of(context);
  return _subtleOutlinedButtonStyle(
    context,
    minimumSize: const Size(0, 27),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
  ).copyWith(
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return colors.text;
      }
      return colors.textMuted;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return BorderSide(color: colors.textMuted.withValues(alpha: 0.7));
      }
      return BorderSide(color: colors.border);
    }),
  );
}

InputDecoration _neutralBuilderInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
}) {
  final colors = VerdantThemeColors.of(context);
  final border = OutlineInputBorder(
    borderRadius: VerdantRadii.sharp,
    borderSide: BorderSide(color: colors.border),
  );
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: colors.panel,
    hoverColor: Colors.transparent,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: VerdantRadii.sharp,
      borderSide: BorderSide(color: colors.action),
    ),
  );
}

class _BuilderFullPreview extends StatelessWidget {
  const _BuilderFullPreview({required this.draft, required this.onClose});

  final FeedAnnouncementDraft draft;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      key: const ValueKey('announcement-builder-full-preview'),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: VerdantFontWeights.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('announcement-builder-preview-close'),
                  tooltip: 'Close preview',
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SmoothSingleChildScrollView(
                primary: false,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: AnnouncementCardPreview(draft: draft),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BuilderStyleTarget { title, description, footer }

class _BuilderEditor extends StatefulWidget {
  const _BuilderEditor({required this.controller});

  final AnnouncementFeedBuilderController controller;

  @override
  State<_BuilderEditor> createState() => _BuilderEditorState();
}

class _BuilderEditorState extends State<_BuilderEditor> {
  _BuilderStyleTarget? _activeStyleTarget;

  AnnouncementFeedBuilderController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SmoothSingleChildScrollView(
        primary: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StyledBuilderField(
                fieldKey: const ValueKey('announcement-builder-title-field'),
                controller: controller.titleController,
                label: 'Title',
                hintText: 'Release notes, event update, server notice',
                visible: _activeStyleTarget == _BuilderStyleTarget.title,
                onFocus: () => _showStyleTarget(_BuilderStyleTarget.title),
                onBlur: () => _hideStyleTarget(_BuilderStyleTarget.title),
                styleControls: _AnnouncementTextStyleControls(
                  key: const ValueKey(
                    'announcement-builder-title-style-controls',
                  ),
                  keyPrefix: 'announcement-builder-title',
                  style: controller.titleStyle,
                  onChanged: controller.setTitleStyle,
                ),
              ),
              const SizedBox(height: 12),
              _StyledBuilderField(
                fieldKey: const ValueKey(
                  'announcement-builder-description-field',
                ),
                controller: controller.descriptionController,
                label: 'Summary',
                hintText: 'Short intro copy for the announcement card',
                minLines: 2,
                maxLines: 3,
                visible: _activeStyleTarget == _BuilderStyleTarget.description,
                onFocus: () =>
                    _showStyleTarget(_BuilderStyleTarget.description),
                onBlur: () => _hideStyleTarget(_BuilderStyleTarget.description),
                styleControls: _AnnouncementTextStyleControls(
                  key: const ValueKey(
                    'announcement-builder-description-style-controls',
                  ),
                  keyPrefix: 'announcement-builder-description',
                  style: controller.descriptionStyle,
                  onChanged: controller.setDescriptionStyle,
                ),
              ),
              const SizedBox(height: 12),
              _AnnouncementAccentColorPicker(controller: controller),
              const SizedBox(height: 12),
              _StyledBuilderField(
                fieldKey: const ValueKey('announcement-builder-footer-field'),
                controller: controller.footerController,
                label: 'Footer',
                hintText: 'Optional attribution or visibility note',
                visible: _activeStyleTarget == _BuilderStyleTarget.footer,
                onFocus: () => _showStyleTarget(_BuilderStyleTarget.footer),
                onBlur: () => _hideStyleTarget(_BuilderStyleTarget.footer),
                styleControls: _AnnouncementTextStyleControls(
                  key: const ValueKey(
                    'announcement-builder-footer-style-controls',
                  ),
                  keyPrefix: 'announcement-builder-footer',
                  style: controller.footerStyle,
                  onChanged: controller.setFooterStyle,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Content blocks',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontWeight: VerdantFontWeights.black,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButtonTheme(
                data: OutlinedButtonThemeData(
                  style: _contentBlockButtonStyle(context).copyWith(
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('announcement-builder-add-heading'),
                      onPressed: controller.addHeadingSection,
                      icon: const Icon(Icons.title, size: 14),
                      label: const Text('Heading'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('announcement-builder-add-rich-text'),
                      onPressed: controller.addRichTextSection,
                      icon: const Icon(Icons.format_color_text, size: 14),
                      label: const Text('Text'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey(
                        'announcement-builder-add-bullet-list',
                      ),
                      onPressed: () => controller.addListSection(),
                      icon: const Icon(Icons.format_list_bulleted, size: 14),
                      label: const Text('Bullets'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey(
                        'announcement-builder-add-number-list',
                      ),
                      onPressed: () => controller.addListSection(ordered: true),
                      icon: const Icon(Icons.format_list_numbered, size: 14),
                      label: const Text('Numbers'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('announcement-builder-add-divider'),
                      onPressed: controller.addDividerSection,
                      icon: const Icon(Icons.horizontal_rule, size: 14),
                      label: const Text('Divider'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('announcement-builder-add-code'),
                      onPressed: controller.addCodeSection,
                      icon: const Icon(Icons.code, size: 14),
                      label: const Text('Code'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('announcement-builder-add-chart'),
                      onPressed: controller.addChartSection,
                      icon: const Icon(Icons.bar_chart, size: 14),
                      label: const Text('Chart'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('announcement-builder-add-youtube'),
                      onPressed: controller.addYouTubeSection,
                      icon: const Icon(Icons.play_circle_outline, size: 14),
                      label: const Text('YouTube'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('announcement-builder-add-button'),
                      onPressed: controller.addButtonSection,
                      icon: const Icon(Icons.smart_button_outlined, size: 14),
                      label: const Text('Button'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (controller.sections.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.panelRaised,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Add blocks to build a structured announcement. Raw HTML is never rendered.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (var index = 0; index < controller.sections.length; index++)
                  _AnimatedSectionMount(
                    key: ValueKey(
                      'announcement-builder-section-$index-transition',
                    ),
                    child: _SectionEditor(
                      index: index,
                      section: controller.sections[index],
                      onChanged: (value) =>
                          controller.updateSectionContent(index, value),
                      onRichTextChanged: (value) =>
                          controller.updateRichTextContent(
                            sectionIndex: index,
                            text: value,
                          ),
                      onRichTextSelectionStyleChanged: (selection, style) =>
                          controller.applyRichTextSelectionStyle(
                            sectionIndex: index,
                            selection: selection,
                            style: style,
                          ),
                      onRemove: () => controller.removeSection(index),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStyleTarget(_BuilderStyleTarget target) {
    if (_activeStyleTarget == target) {
      return;
    }
    setState(() => _activeStyleTarget = target);
  }

  void _hideStyleTarget(_BuilderStyleTarget target) {
    if (_activeStyleTarget != target) {
      return;
    }
    setState(() => _activeStyleTarget = null);
  }
}

class _AnimatedSectionMount extends StatelessWidget {
  const _AnimatedSectionMount({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

class _StyledBuilderField extends StatelessWidget {
  const _StyledBuilderField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.visible,
    required this.onFocus,
    required this.onBlur,
    required this.styleControls,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool visible;
  final VoidCallback onFocus;
  final VoidCallback onBlur;
  final Widget styleControls;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StyleControlsReveal(visible: visible, child: styleControls),
          _BuilderField(
            key: fieldKey,
            controller: controller,
            label: label,
            hintText: hintText,
            minLines: minLines,
            maxLines: maxLines,
            onFocus: onFocus,
            onTapOutside: onBlur,
          ),
        ],
      ),
    );
  }
}

class _BuilderField extends StatefulWidget {
  const _BuilderField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.onFocus,
    required this.onTapOutside,
    this.minLines = 1,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final VoidCallback onFocus;
  final VoidCallback onTapOutside;
  final int minLines;
  final int maxLines;

  @override
  State<_BuilderField> createState() => _BuilderFieldState();
}

class _BuilderFieldState extends State<_BuilderField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onTap: widget.onFocus,
      onTapOutside: (_) => widget.onTapOutside(),
      decoration: _neutralBuilderInputDecoration(
        context,
        labelText: widget.label,
        hintText: widget.hintText,
      ),
    );
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      widget.onFocus();
    }
  }
}

class _StyleControlsReveal extends StatelessWidget {
  const _StyleControlsReveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: visible
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 170),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.35),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _AnnouncementTextStyleControls extends StatelessWidget {
  const _AnnouncementTextStyleControls({
    required this.keyPrefix,
    required this.style,
    required this.onChanged,
    this.embedded = false,
    super.key,
  });

  final String keyPrefix;
  final FeedAnnouncementTextStyle? style;
  final ValueChanged<FeedAnnouncementTextStyle?> onChanged;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final current = style ?? const FeedAnnouncementTextStyle();
    final controls = SizedBox(
      height: 28,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AnnouncementFontSizeInput(
                keyPrefix: keyPrefix,
                value: current.fontSize ?? _fontSizeForNamedSize(current.size),
                onChanged: _setFontSize,
              ),
              const SizedBox(width: 6),
              _StyleChip(
                key: ValueKey('$keyPrefix-weight-bold'),
                label: 'B',
                tooltip: 'Bold',
                selected: current.weight == FeedAnnouncementTextWeight.bold,
                onTap: () => _setWeight(
                  current.weight == FeedAnnouncementTextWeight.bold
                      ? null
                      : FeedAnnouncementTextWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              _StyleChip(
                key: ValueKey('$keyPrefix-style-italic'),
                label: 'I',
                tooltip: 'Italic',
                selected: current.italic == true,
                italic: true,
                onTap: () => _setItalic(current.italic != true),
              ),
              const SizedBox(width: 6),
              _StyleChip(
                key: ValueKey('$keyPrefix-style-strikethrough'),
                label: 'S',
                tooltip: 'Strikethrough',
                selected: current.strikethrough == true,
                strikethrough: true,
                onTap: () => _setStrikethrough(current.strikethrough != true),
              ),
              const SizedBox(width: 6),
              _AnnouncementStyleColorInput(
                keyPrefix: keyPrefix,
                value: current.color,
                onChanged: _setColor,
              ),
              const SizedBox(width: 6),
              _StyleChip(
                key: ValueKey('$keyPrefix-style-reset'),
                label: 'Reset',
                tooltip: 'Clear style',
                selected: false,
                onTap: () => onChanged(null),
              ),
            ],
          ),
        ),
      ),
    );
    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 3),
        child: controls,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.panelRaised.withValues(alpha: 0.62),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: controls,
    );
  }

  double? _fontSizeForNamedSize(FeedAnnouncementTextSize? size) {
    return switch (size) {
      FeedAnnouncementTextSize.xs => 11,
      FeedAnnouncementTextSize.sm => 13,
      FeedAnnouncementTextSize.md => 15,
      FeedAnnouncementTextSize.lg => 18,
      FeedAnnouncementTextSize.xl => 22,
      null => null,
    };
  }

  void _setFontSize(double? fontSize) {
    _commit((current) => current.copyWith(size: null, fontSize: fontSize));
  }

  void _setWeight(FeedAnnouncementTextWeight? weight) {
    _commit((current) => current.copyWith(weight: weight));
  }

  void _setItalic(bool value) {
    _commit((current) => current.copyWith(italic: value ? true : null));
  }

  void _setStrikethrough(bool value) {
    _commit((current) => current.copyWith(strikethrough: value ? true : null));
  }

  void _setColor(String? color) {
    _commit((current) => current.copyWith(color: color));
  }

  void _commit(
    FeedAnnouncementTextStyle Function(FeedAnnouncementTextStyle current)
    update,
  ) {
    final next = update(style ?? const FeedAnnouncementTextStyle());
    onChanged(next.hasContent ? next : null);
  }
}

class _AnnouncementFontSizeInput extends StatefulWidget {
  const _AnnouncementFontSizeInput({
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
  });

  final String keyPrefix;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<_AnnouncementFontSizeInput> createState() =>
      _AnnouncementFontSizeInputState();
}

class _AnnouncementFontSizeInputState
    extends State<_AnnouncementFontSizeInput> {
  static const double _defaultFontSize = 14;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  double get _displayValue => widget.value ?? _defaultFontSize;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatFontSize(_displayValue));
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void didUpdateWidget(covariant _AnnouncementFontSizeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _formatFontSize(_displayValue);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final textStyle =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          color: colors.text,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          height: 1.05,
        );
    final pxStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.textMuted,
      fontWeight: FontWeight.w700,
      fontSize: 9,
      height: 1,
    );
    final hiddenInputStyle = textStyle.copyWith(color: Colors.transparent);
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(
          color: _focusNode.hasFocus ? colors.accent : colors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 28,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                TextField(
                  key: ValueKey('${widget.keyPrefix}-font-size-field'),
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: _commit,
                  onEditingComplete: () => _commit(_controller.text),
                  cursorColor: Colors.transparent,
                  cursorHeight: 13,
                  cursorWidth: 1.2,
                  decoration: null,
                  enableInteractiveSelection: false,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  scrollPadding: EdgeInsets.zero,
                  textAlignVertical: TextAlignVertical.center,
                  strutStyle: const StrutStyle(
                    fontSize: 12.5,
                    height: 1.05,
                    forceStrutHeight: true,
                  ),
                  style: hiddenInputStyle,
                  textAlign: TextAlign.center,
                ),
                IgnorePointer(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      final displayValue = value.text.trim().isEmpty
                          ? _formatFontSize(_displayValue)
                          : value.text.trim();
                      return Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              displayValue,
                              style: textStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(width: 4),
                            Text('px', style: pxStyle),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 28,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.border)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: _FontSizeStepButton(
                    key: ValueKey('${widget.keyPrefix}-font-size-increment'),
                    label: '+',
                    onTap: () => _step(1),
                  ),
                ),
                Container(
                  height: 1,
                  color: colors.borderStrong.withValues(alpha: 0.75),
                ),
                Expanded(
                  child: _FontSizeStepButton(
                    key: ValueKey('${widget.keyPrefix}-font-size-decrement'),
                    label: '-',
                    onTap: () => _step(-1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _step(double delta) {
    final next = normalizeAnnouncementFontSize(_displayValue + delta);
    if (next == null) {
      return;
    }
    _controller.text = _formatFontSize(next);
    widget.onChanged(next);
  }

  void _commit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _controller.text = _formatFontSize(_defaultFontSize);
      widget.onChanged(null);
      return;
    }
    final parsed = double.tryParse(trimmed);
    final normalized = normalizeAnnouncementFontSize(parsed);
    if (normalized == null) {
      _controller.text = _formatFontSize(_displayValue);
      return;
    }
    _controller.text = _formatFontSize(normalized);
    widget.onChanged(normalized);
  }
}

class _FontSizeStepButton extends StatefulWidget {
  const _FontSizeStepButton({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_FontSizeStepButton> createState() => _FontSizeStepButtonState();
}

class _FontSizeStepButtonState extends State<_FontSizeStepButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final background = _pressed
        ? colors.text.withValues(alpha: 0.13)
        : _hovered
        ? colors.text.withValues(alpha: 0.08)
        : Colors.transparent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          width: 20,
          color: background,
          child: Center(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _hovered ? colors.text : colors.textMuted,
                fontWeight: VerdantFontWeights.black,
                fontSize: 9.5,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleChip extends StatefulWidget {
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltip,
    this.italic = false,
    this.strikethrough = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;
  final bool italic;
  final bool strikethrough;

  @override
  State<_StyleChip> createState() => _StyleChipState();
}

class _StyleChipState extends State<_StyleChip> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final active = widget.selected;
    final background = _pressed
        ? colors.text.withValues(alpha: 0.14)
        : active
        ? colors.text.withValues(alpha: 0.11)
        : _hovered
        ? colors.text.withValues(alpha: 0.07)
        : colors.panel;
    final borderColor = active
        ? colors.textMuted.withValues(alpha: 0.95)
        : _hovered
        ? colors.textMuted.withValues(alpha: 0.62)
        : colors.border;
    final textColor = active || _hovered ? colors.text : colors.textMuted;
    final chip = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          height: 28,
          constraints: const BoxConstraints(minWidth: 30),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: active ? VerdantFontWeights.black : FontWeight.w800,
              fontStyle: widget.italic ? FontStyle.italic : null,
              decoration: widget.strikethrough
                  ? TextDecoration.lineThrough
                  : null,
              fontSize: 11,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
    return widget.tooltip == null
        ? chip
        : Tooltip(message: widget.tooltip!, child: chip);
  }
}

class _AnnouncementStyleColorInput extends StatelessWidget {
  const _AnnouncementStyleColorInput({
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
  });

  final String keyPrefix;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CompactColorPickerInput(
      keyPrefix: keyPrefix,
      label: 'Color',
      value: value,
      fallbackHex: '#ffffff',
      allowClear: true,
      onChanged: onChanged,
    );
  }
}

class _AnnouncementAccentColorPicker extends StatelessWidget {
  const _AnnouncementAccentColorPicker({required this.controller});

  final AnnouncementFeedBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      key: const ValueKey('announcement-builder-accent-color-picker'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Accent color',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textMuted,
            fontWeight: VerdantFontWeights.black,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: _CompactColorPickerInput(
            keyPrefix: 'announcement-builder-accent',
            value: controller.accentColor,
            fallbackHex: defaultAnnouncementAccent,
            onChanged: (value) {
              if (value != null) {
                controller.setAccentColor(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _CompactColorPickerInput extends StatefulWidget {
  const _CompactColorPickerInput({
    required this.keyPrefix,
    required this.value,
    required this.fallbackHex,
    required this.onChanged,
    this.label,
    this.allowClear = false,
  });

  final String keyPrefix;
  final String? value;
  final String fallbackHex;
  final String? label;
  final bool allowClear;
  final ValueChanged<String?> onChanged;

  @override
  State<_CompactColorPickerInput> createState() =>
      _CompactColorPickerInputState();
}

class _CompactColorPickerInputState extends State<_CompactColorPickerInput> {
  static const double _popoverWidth = 224;
  static const double _popoverMargin = 12;

  final LayerLink _layerLink = LayerLink();
  late final TextEditingController _hexController;
  late HSVColor _workingColor;
  OverlayEntry? _overlayEntry;
  bool _dragging = false;
  bool _popoverOpen = false;
  bool _overlayRebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    _workingColor = _hsvFromValue();
    _hexController = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant _CompactColorPickerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.value != widget.value) {
      _workingColor = _hsvFromValue();
      _hexController.text = widget.value ?? '';
      _scheduleOverlayRebuild();
    }
  }

  HSVColor _hsvFromValue() {
    return HSVColor.fromColor(
      _parseAnnouncementHexColor(widget.value ?? widget.fallbackHex) ??
          const Color(0xFFFFFFFF),
    );
  }

  @override
  void dispose() {
    _removeOverlay(updateState: false);
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final preview =
        _parseAnnouncementHexColor(widget.value) ?? _workingColor.toColor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 5),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: ValueKey('${widget.keyPrefix}-color-anchor'),
              behavior: HitTestBehavior.opaque,
              onTap: _toggleOverlay,
              child: Container(
                key: ValueKey('${widget.keyPrefix}-preview'),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: preview,
                  border: Border.all(
                    color: _popoverOpen
                        ? colors.textMuted.withValues(alpha: 0.9)
                        : colors.border,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    if (_popoverOpen)
                      BoxShadow(
                        color: preview.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 88,
          height: 24,
          child: TextFormField(
            key: ValueKey('${widget.keyPrefix}-hex-field'),
            controller: _hexController,
            maxLength: 7,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: _commitHexInput,
            textAlignVertical: TextAlignVertical.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
            decoration: InputDecoration(
              isDense: true,
              constraints: const BoxConstraints.tightFor(height: 24),
              counterText: '',
              hintText: widget.allowClear ? '#ffffff' : widget.fallbackHex,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              filled: true,
              fillColor: colors.panel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border),
                borderRadius: BorderRadius.circular(6),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: colors.textMuted.withValues(alpha: 0.9),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        if (widget.allowClear && widget.value != null)
          IconButton(
            key: ValueKey('${widget.keyPrefix}-color-clear'),
            tooltip: 'Use default color',
            onPressed: widget.value == null
                ? null
                : () => widget.onChanged(null),
            icon: const Icon(Icons.close, size: 14),
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            padding: EdgeInsets.zero,
            splashRadius: 13,
            color: colors.textMuted,
          ),
      ],
    );
  }

  void _toggleOverlay() {
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_overlayEntry!);
    setState(() => _popoverOpen = true);
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final horizontalOffset = _popoverHorizontalOffset(overlayContext);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned.fill(
          child: TextFieldTapRegion(
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(horizontalOffset, 32),
              child: Align(
                alignment: Alignment.topLeft,
                widthFactor: 1,
                heightFactor: 1,
                child: Material(
                  color: Colors.transparent,
                  child: _buildPopover(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _popoverHorizontalOffset(BuildContext overlayContext) {
    final renderObject = context.findRenderObject();
    final mediaQuery = MediaQuery.maybeOf(overlayContext);
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        mediaQuery == null) {
      return 0;
    }

    final anchorX = renderObject.localToGlobal(Offset.zero).dx;
    final windowWidth = mediaQuery.size.width;
    final overflow = anchorX + _popoverWidth + _popoverMargin - windowWidth;
    var shift = overflow > 0 ? -overflow : 0.0;
    final shiftedLeft = anchorX + shift;
    if (shiftedLeft < _popoverMargin) {
      shift += _popoverMargin - shiftedLeft;
    }
    return shift;
  }

  Widget _buildPopover(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      key: ValueKey('${widget.keyPrefix}-color-popover'),
      width: _popoverWidth,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (padContext) {
              return GestureDetector(
                key: ValueKey('${widget.keyPrefix}-saturation-value'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handlePadTap(details, padContext),
                onPanStart: (details) => _handlePadStart(details, padContext),
                onPanUpdate: (details) => _handlePadUpdate(details, padContext),
                onPanEnd: (_) => _commitWorkingColor(),
                onPanCancel: _commitWorkingColor,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        HSVColor.fromAHSV(1, _workingColor.hue, 1, 1).toColor(),
                      ],
                    ),
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment(
                      (_workingColor.saturation * 2) - 1,
                      1 - (_workingColor.value * 2),
                    ),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (hueContext) {
              return GestureDetector(
                key: ValueKey('${widget.keyPrefix}-hue-slider'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleHueTap(details, hueContext),
                onPanStart: (details) => _handleHueStart(details, hueContext),
                onPanUpdate: (details) => _handleHueUpdate(details, hueContext),
                onPanEnd: (_) => _commitWorkingColor(),
                onPanCancel: _commitWorkingColor,
                child: CustomPaint(
                  painter: _AnnouncementHueSliderPainter(colors.border),
                  child: SizedBox(
                    height: 14,
                    child: Align(
                      alignment: Alignment((_workingColor.hue / 180) - 1, 0),
                      child: Container(
                        width: 8,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.panel, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handlePadTap(TapDownDetails details, BuildContext targetContext) {
    _setColorFromPad(details.localPosition, targetContext);
    _commitWorkingColor();
  }

  void _handlePadStart(DragStartDetails details, BuildContext targetContext) {
    _dragging = true;
    _setColorFromPad(details.localPosition, targetContext);
  }

  void _handlePadUpdate(DragUpdateDetails details, BuildContext targetContext) {
    _setColorFromPad(details.localPosition, targetContext);
  }

  void _handleHueTap(TapDownDetails details, BuildContext targetContext) {
    _setHueFromPosition(details.localPosition, targetContext);
    _commitWorkingColor();
  }

  void _handleHueStart(DragStartDetails details, BuildContext targetContext) {
    _dragging = true;
    _setHueFromPosition(details.localPosition, targetContext);
  }

  void _handleHueUpdate(DragUpdateDetails details, BuildContext targetContext) {
    _setHueFromPosition(details.localPosition, targetContext);
  }

  void _setColorFromPad(Offset localPosition, BuildContext targetContext) {
    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final size = box.size;
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    setState(() {
      _workingColor = _workingColor.withSaturation(saturation).withValue(value);
      _hexController.text = _hexFromAnnouncementColor(_workingColor.toColor());
    });
    _scheduleOverlayRebuild();
  }

  void _setHueFromPosition(Offset localPosition, BuildContext targetContext) {
    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final hue = (localPosition.dx / box.size.width).clamp(0.0, 1.0) * 360;
    setState(() {
      _workingColor = _workingColor.withHue(hue);
      _hexController.text = _hexFromAnnouncementColor(_workingColor.toColor());
    });
    _scheduleOverlayRebuild();
  }

  void _commitHexInput(String value) {
    final normalized = _normalizedAnnouncementHexInput(value);
    if (normalized == null) {
      if (widget.allowClear && value.trim().isEmpty) {
        widget.onChanged(null);
        return;
      }
      _hexController.text = widget.value ?? '';
      return;
    }
    setState(() {
      _workingColor = HSVColor.fromColor(
        _parseAnnouncementHexColor(normalized)!,
      );
      _hexController.text = normalized;
    });
    widget.onChanged(normalized);
    _scheduleOverlayRebuild();
  }

  void _commitWorkingColor() {
    _dragging = false;
    final hex = _hexFromAnnouncementColor(_workingColor.toColor());
    _hexController.text = hex;
    widget.onChanged(hex);
    _scheduleOverlayRebuild();
  }

  void _scheduleOverlayRebuild() {
    if (_overlayEntry == null || _overlayRebuildScheduled) {
      return;
    }
    _overlayRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayRebuildScheduled = false;
      if (!mounted) {
        return;
      }
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _removeOverlay({bool updateState = true}) {
    final overlay = _overlayEntry;
    if (overlay == null) {
      return;
    }
    overlay.remove();
    _overlayEntry = null;
    if (updateState && mounted) {
      setState(() => _popoverOpen = false);
    } else {
      _popoverOpen = false;
    }
  }
}

class _AnnouncementHueSliderPainter extends CustomPainter {
  const _AnnouncementHueSliderPainter(this.borderColor);

  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(rect);
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _AnnouncementHueSliderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}

Color? _parseAnnouncementHexColor(String? value) {
  if (value == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
    return null;
  }
  return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
}

String _hexFromAnnouncementColor(Color color) {
  final value = color.toARGB32() & 0x00ffffff;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

String _formatFontSize(double? value) {
  if (value == null) {
    return '';
  }
  final normalized = normalizeAnnouncementFontSize(value);
  if (normalized == null) {
    return '';
  }
  if (normalized == normalized.roundToDouble()) {
    return normalized.round().toString();
  }
  return normalized.toStringAsFixed(1);
}

String? _normalizedAnnouncementHexInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final prefixed = trimmed.startsWith('#') ? trimmed : '#$trimmed';
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(prefixed)) {
    return null;
  }
  return prefixed.toLowerCase();
}

class _SectionEditor extends StatelessWidget {
  const _SectionEditor({
    required this.index,
    required this.section,
    required this.onChanged,
    required this.onRichTextChanged,
    required this.onRichTextSelectionStyleChanged,
    required this.onRemove,
  });

  final int index;
  final FeedAnnouncementSection section;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onRichTextChanged;
  final void Function(TextSelection selection, FeedAnnouncementTextStyle? style)
  onRichTextSelectionStyleChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final label = switch (section) {
      FeedAnnouncementTextSection() => 'Text',
      FeedAnnouncementRichTextSection() => 'Rich Text',
      FeedAnnouncementCodeSection() => 'Code',
      FeedAnnouncementHeadingSection() => 'Heading',
      FeedAnnouncementListSection(:final ordered) =>
        ordered ? 'Number List' : 'Bullet List',
      FeedAnnouncementDividerSection() => 'Divider',
      FeedAnnouncementButtonSection() => 'Button',
      FeedAnnouncementYouTubeSection() => 'YouTube',
      FeedAnnouncementChartSection() => 'Chart',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.38),
        border: Border.all(color: colors.borderStrong.withValues(alpha: 0.62)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontWeight: VerdantFontWeights.black,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Remove block',
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 15),
              ),
            ],
          ),
          if (section case FeedAnnouncementDividerSection())
            Divider(color: colors.border, height: 22)
          else if (section case FeedAnnouncementRichTextSection(:final spans))
            _RichTextSectionEditor(
              sectionIndex: index,
              spans: spans,
              onTextChanged: onRichTextChanged,
              onSelectionStyleChanged: onRichTextSelectionStyleChanged,
            )
          else
            TextFormField(
              key: ValueKey('announcement-builder-section-$index-field'),
              initialValue: _sectionContent(section),
              minLines: _sectionMinLines(section),
              maxLines: _sectionMaxLines(section),
              decoration: _neutralBuilderInputDecoration(
                context,
                hintText: _sectionHintText(section),
              ),
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _RichTextSectionEditor extends StatefulWidget {
  const _RichTextSectionEditor({
    required this.sectionIndex,
    required this.spans,
    required this.onTextChanged,
    required this.onSelectionStyleChanged,
  });

  final int sectionIndex;
  final List<FeedAnnouncementRichTextSpan> spans;
  final ValueChanged<String> onTextChanged;
  final void Function(TextSelection selection, FeedAnnouncementTextStyle? style)
  onSelectionStyleChanged;

  @override
  State<_RichTextSectionEditor> createState() => _RichTextSectionEditorState();
}

class _RichTextSectionEditorState extends State<_RichTextSectionEditor> {
  late final _AnnouncementRichTextEditingController _textController;
  late final FocusNode _focusNode;
  TextSelection? _selection;
  late String _lastText;
  bool _showSelectionTools = false;

  @override
  void initState() {
    super.initState();
    _textController = _AnnouncementRichTextEditingController(
      spans: widget.spans,
    )..addListener(_handleEditingValueChanged);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _lastText = _textController.text;
    _selection = _textController.selection;
  }

  @override
  void didUpdateWidget(covariant _RichTextSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _textController.setSpans(widget.spans);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleEditingValueChanged);
    _textController.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyPrefix = 'announcement-builder-rich-text-${widget.sectionIndex}';
    final activeSelection = _activeSelection;
    return TextFieldTapRegion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StyleControlsReveal(
            visible: _showSelectionTools,
            child: _AnnouncementTextStyleControls(
              key: ValueKey('$keyPrefix-selection-style-controls'),
              keyPrefix: '$keyPrefix-selection',
              style: _styleForSelection(activeSelection),
              embedded: true,
              onChanged: (style) {
                final selection = _activeSelection;
                if (selection == null) {
                  return;
                }
                widget.onSelectionStyleChanged(selection, style);
              },
            ),
          ),
          TextFormField(
            key: ValueKey('$keyPrefix-field'),
            controller: _textController,
            focusNode: _focusNode,
            minLines: 3,
            maxLines: 6,
            onChanged: widget.onTextChanged,
            onTap: () => setState(() => _showSelectionTools = true),
            onTapOutside: (_) => setState(() {
              _selection = null;
              _showSelectionTools = false;
            }),
            decoration: _neutralBuilderInputDecoration(
              context,
              labelText: 'Rich text',
              hintText:
                  'Write an announcement, then highlight text to style it',
            ),
          ),
        ],
      ),
    );
  }

  TextSelection? get _activeSelection {
    final selection = _selection;
    if (selection == null || selection.isCollapsed) {
      return null;
    }
    final textLength = _textController.text.length;
    if (selection.start < 0 ||
        selection.end < 0 ||
        selection.start > textLength ||
        selection.end > textLength) {
      return null;
    }
    return selection;
  }

  FeedAnnouncementTextStyle? _styleForSelection(TextSelection? selection) {
    if (selection == null) {
      return null;
    }
    return _textController.styleAt(selection.start);
  }

  void _handleEditingValueChanged() {
    final textChanged = _textController.text != _lastText;
    _lastText = _textController.text;
    final next = _textController.selection;
    if (next.isValid && !next.isCollapsed) {
      if (next == _selection && _showSelectionTools) {
        return;
      }
      setState(() {
        _selection = next;
        _showSelectionTools = true;
      });
      return;
    }
    if (textChanged) {
      setState(() {
        _selection = null;
        _showSelectionTools = _focusNode.hasFocus;
      });
      return;
    }
    if (_focusNode.hasFocus && !_showSelectionTools) {
      setState(() => _showSelectionTools = true);
    }
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      final selection = _textController.selection;
      setState(() {
        _showSelectionTools = true;
        if (selection.isValid && !selection.isCollapsed) {
          _selection = selection;
        }
      });
    }
  }
}

class _AnnouncementRichTextEditingController extends TextEditingController {
  _AnnouncementRichTextEditingController({
    required List<FeedAnnouncementRichTextSpan> spans,
  }) : _spans = spans,
       super(text: richTextPlainText(spans));

  List<FeedAnnouncementRichTextSpan> _spans;

  void setSpans(List<FeedAnnouncementRichTextSpan> spans) {
    _spans = spans;
    final nextText = richTextPlainText(spans);
    if (text != nextText) {
      final clampedOffset = selection.baseOffset.clamp(0, nextText.length);
      value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: clampedOffset),
      );
      return;
    }
    notifyListeners();
  }

  FeedAnnouncementTextStyle? styleAt(int offset) {
    if (offset < 0) {
      return null;
    }
    var cursor = 0;
    for (final span in _spans) {
      final end = cursor + span.text.length;
      if (offset >= cursor && offset < end) {
        return span.style;
      }
      cursor = end;
    }
    return _spans.isEmpty ? null : _spans.last.style;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (richTextPlainText(_spans) != text) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return TextSpan(
      style: style,
      children: [
        for (final span in _spans)
          TextSpan(
            text: span.text,
            style: _styledRichTextEditorText(context, style, span.style),
          ),
      ],
    );
  }
}

TextStyle? _styledRichTextEditorText(
  BuildContext context,
  TextStyle? base,
  FeedAnnouncementTextStyle? style,
) {
  if (style == null || !style.hasContent) {
    return base;
  }
  return base?.copyWith(
    color: style.color == null
        ? base.color
        : _parseAnnouncementHexColor(style.color!) ??
              base.color ??
              VerdantThemeColors.of(context).text,
    fontSize:
        style.fontSize ??
        switch (style.size) {
          FeedAnnouncementTextSize.xs => 11,
          FeedAnnouncementTextSize.sm => 13,
          FeedAnnouncementTextSize.md => 15,
          FeedAnnouncementTextSize.lg => 18,
          FeedAnnouncementTextSize.xl => 22,
          null => base.fontSize,
        },
    fontWeight: switch (style.weight) {
      FeedAnnouncementTextWeight.normal => FontWeight.w400,
      FeedAnnouncementTextWeight.medium => FontWeight.w500,
      FeedAnnouncementTextWeight.semibold => FontWeight.w600,
      FeedAnnouncementTextWeight.bold => FontWeight.w700,
      null => base.fontWeight,
    },
    fontStyle: style.italic == true ? FontStyle.italic : base.fontStyle,
    decoration: style.strikethrough == true
        ? TextDecoration.lineThrough
        : base.decoration,
  );
}

String _sectionContent(FeedAnnouncementSection section) {
  return switch (section) {
    FeedAnnouncementTextSection(:final content) => content,
    FeedAnnouncementRichTextSection() => '',
    FeedAnnouncementCodeSection(:final content) => content,
    FeedAnnouncementHeadingSection(:final content) => content,
    FeedAnnouncementListSection(:final items) => items.join('\n'),
    FeedAnnouncementDividerSection() => '',
    FeedAnnouncementButtonSection(:final label, :final url) => '$label\n$url',
    FeedAnnouncementYouTubeSection(:final url) => url,
    FeedAnnouncementChartSection(:final title, :final data, :final kind) =>
      'type: ${kind.editorName}\n'
          'title: ${title?.trim().isNotEmpty == true ? title!.trim() : 'Sample data'}\n'
          '$data',
  };
}

int _sectionMinLines(FeedAnnouncementSection section) {
  return switch (section) {
    FeedAnnouncementTextSection() => 3,
    FeedAnnouncementRichTextSection() => 1,
    FeedAnnouncementCodeSection() => 5,
    FeedAnnouncementListSection() => 3,
    FeedAnnouncementButtonSection() => 2,
    FeedAnnouncementChartSection() => 5,
    FeedAnnouncementHeadingSection() ||
    FeedAnnouncementYouTubeSection() ||
    FeedAnnouncementDividerSection() => 1,
  };
}

int _sectionMaxLines(FeedAnnouncementSection section) {
  return switch (section) {
    FeedAnnouncementTextSection() => 6,
    FeedAnnouncementRichTextSection() => 1,
    FeedAnnouncementCodeSection() => 10,
    FeedAnnouncementListSection() => 8,
    FeedAnnouncementButtonSection() => 2,
    FeedAnnouncementChartSection() => 8,
    FeedAnnouncementHeadingSection() ||
    FeedAnnouncementYouTubeSection() ||
    FeedAnnouncementDividerSection() => 1,
  };
}

String _sectionHintText(FeedAnnouncementSection section) {
  return switch (section) {
    FeedAnnouncementHeadingSection() => 'Section heading',
    FeedAnnouncementTextSection() => 'Text content',
    FeedAnnouncementRichTextSection() => '',
    FeedAnnouncementCodeSection() => 'Code content, wraps in preview',
    FeedAnnouncementListSection() => 'One item per line',
    FeedAnnouncementButtonSection() => 'Button label on line 1, URL on line 2',
    FeedAnnouncementYouTubeSection() => 'https://www.youtube.com/watch?v=...',
    FeedAnnouncementChartSection() =>
      'type: bar|line|donut|metrics|progress|sparkline\ntitle: Metrics\nActive users: 42',
    FeedAnnouncementDividerSection() => '',
  };
}
