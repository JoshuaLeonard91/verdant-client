import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../theme/verdant_theme.dart';
import '../../shared/external_link_warning.dart';
import '../../shared/workspace_link_launcher.dart';
import '../../shared/youtube_embed/workspace_youtube_playback_memory.dart';
import '../../shared/youtube_embed/workspace_youtube_preview.dart';
import 'announcement_content_models.dart';

class AnnouncementCardPreview extends StatelessWidget {
  const AnnouncementCardPreview({
    required this.draft,
    this.linkLauncher = const WorkspaceLinkLauncher(),
    this.youtubePreviewKeyPrefix = 'announcement-card-preview',
    this.youtubePlayerBuilder,
    this.youtubePlaybackMemory,
    this.onYoutubePlaybackChanged,
    super.key,
  });

  final FeedAnnouncementDraft draft;
  final WorkspaceLinkLauncher linkLauncher;
  final String youtubePreviewKeyPrefix;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory? youtubePlaybackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onYoutubePlaybackChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final accent = _hexColorOrDefault(draft.color, colors.accent);
    final description = draft.description?.trim();
    final footer = draft.footer?.trim();
    return Container(
      key: const ValueKey('announcement-feed-preview-card'),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ColoredBox(color: accent, child: const SizedBox(width: 4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_outlined, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Announcement',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                        fontWeight: VerdantFontWeights.black,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  draft.title.trim().isEmpty
                      ? 'Untitled announcement'
                      : draft.title.trim(),
                  style: _styledAnnouncementText(
                    context,
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: draft.title.trim().isEmpty
                          ? colors.textMuted
                          : colors.text,
                      fontWeight: VerdantFontWeights.black,
                    ),
                    draft.titleStyle,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: _styledAnnouncementText(
                      context,
                      Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.35),
                      draft.descriptionStyle,
                    ),
                  ),
                ],
                if (draft.sections.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (
                    var sectionIndex = 0;
                    sectionIndex < draft.sections.length;
                    sectionIndex += 1
                  )
                    if (draft.sections[sectionIndex].hasContent)
                      _AnnouncementPreviewSection(
                        section: draft.sections[sectionIndex],
                        youtubePreviewKeyPrefix:
                            '$youtubePreviewKeyPrefix-youtube-$sectionIndex',
                        accent: accent,
                        linkLauncher: linkLauncher,
                        youtubePlayerBuilder: youtubePlayerBuilder,
                        youtubePlaybackMemory: youtubePlaybackMemory,
                        onYoutubePlaybackChanged: onYoutubePlaybackChanged,
                      ),
                ],
                if (footer != null && footer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Divider(color: colors.border, height: 16),
                  Text(
                    footer,
                    style: _styledAnnouncementText(
                      context,
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                        height: 1.2,
                      ),
                      draft.footerStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle? _styledAnnouncementText(
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
        : _hexColorOrDefault(
            style.color!,
            base.color ?? VerdantThemeColors.of(context).text,
          ),
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

class _AnnouncementPreviewSection extends StatelessWidget {
  const _AnnouncementPreviewSection({
    required this.section,
    required this.youtubePreviewKeyPrefix,
    required this.accent,
    required this.linkLauncher,
    required this.youtubePlayerBuilder,
    required this.youtubePlaybackMemory,
    required this.onYoutubePlaybackChanged,
  });

  final FeedAnnouncementSection section;
  final String youtubePreviewKeyPrefix;
  final Color accent;
  final WorkspaceLinkLauncher linkLauncher;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory? youtubePlaybackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onYoutubePlaybackChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return switch (section) {
      FeedAnnouncementTextSection(:final content, :final color) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          content.trim(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color == null
                ? colors.textMuted
                : _hexColorOrDefault(color, colors.textMuted),
            height: 1.35,
          ),
        ),
      ),
      FeedAnnouncementRichTextSection(:final spans, :final style) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _AnnouncementRichTextPreview(spans: spans, style: style),
      ),
      FeedAnnouncementCodeSection(:final content, :final language) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _AnnouncementCodePreview(content: content, language: language),
      ),
      FeedAnnouncementHeadingSection(:final content, :final level) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          content.trim(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: level == 1
                ? 20
                : level == 2
                ? 17
                : 15,
            fontWeight: VerdantFontWeights.black,
          ),
        ),
      ),
      FeedAnnouncementListSection(:final items, :final ordered, :final style) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AnnouncementListPreview(
            items: items,
            ordered: ordered,
            style: style,
          ),
        ),
      FeedAnnouncementDividerSection() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Divider(color: colors.border, height: 1),
      ),
      FeedAnnouncementButtonSection(:final label, :final url) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _AnnouncementButtonPreview(
          label: label,
          url: url,
          linkLauncher: linkLauncher,
        ),
      ),
      FeedAnnouncementYouTubeSection(:final url, :final title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: WorkspaceYouTubePreview(
          url: url,
          title: title,
          linkLauncher: linkLauncher,
          youtubePlayerBuilder: youtubePlayerBuilder,
          playbackMemory: youtubePlaybackMemory,
          onPlaybackSnapshotChanged: onYoutubePlaybackChanged,
          previewKeyPrefix: youtubePreviewKeyPrefix,
        ),
      ),
      FeedAnnouncementChartSection(:final title, :final points, :final kind) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AnnouncementChartPreview(
            title: title,
            points: points,
            kind: kind,
          ),
        ),
    };
  }
}

class _AnnouncementListPreview extends StatelessWidget {
  const _AnnouncementListPreview({
    required this.items,
    required this.ordered,
    required this.style,
  });

  final List<String> items;
  final bool ordered;
  final FeedAnnouncementTextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final textStyle = _styledAnnouncementText(
      context,
      Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: colors.textMuted, height: 1.35),
      style,
    );
    final visibleItems = [
      for (final item in items)
        if (item.trim().isNotEmpty) item.trim(),
    ];
    return Column(
      key: const ValueKey('announcement-list-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < visibleItems.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == visibleItems.length - 1 ? 0 : 5,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    ordered ? '${index + 1}.' : '•',
                    style: textStyle?.copyWith(
                      color: ordered ? colors.textMuted : colors.accentStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(child: Text(visibleItems[index], style: textStyle)),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnnouncementRichTextPreview extends StatelessWidget {
  const _AnnouncementRichTextPreview({
    required this.spans,
    required this.style,
  });

  final List<FeedAnnouncementRichTextSpan> spans;
  final FeedAnnouncementTextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final baseStyle = _styledAnnouncementText(
      context,
      Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: colors.textMuted, height: 1.35),
      style,
    );
    return RichText(
      key: const ValueKey('announcement-rich-text-section'),
      text: TextSpan(
        style: baseStyle,
        children: _richTextPreviewSpans(context, baseStyle, spans),
      ),
    );
  }
}

List<InlineSpan> _richTextPreviewSpans(
  BuildContext context,
  TextStyle? baseStyle,
  List<FeedAnnouncementRichTextSpan> spans,
) {
  final children = <InlineSpan>[];
  FeedAnnouncementRichTextSpan? previous;
  for (final span in spans) {
    if (span.text.isEmpty) {
      continue;
    }
    if (previous != null && _shouldRecoverTrimmedSpanSpace(previous, span)) {
      children.add(TextSpan(text: ' ', style: baseStyle));
    }
    children.add(
      TextSpan(
        text: span.text,
        style: _styledAnnouncementText(context, baseStyle, span.style),
      ),
    );
    previous = span;
  }
  return children;
}

bool _shouldRecoverTrimmedSpanSpace(
  FeedAnnouncementRichTextSpan left,
  FeedAnnouncementRichTextSpan right,
) {
  if (left.text.isEmpty ||
      right.text.isEmpty ||
      _endsWithWhitespace(left.text) ||
      _startsWithWhitespace(right.text)) {
    return false;
  }
  final leftLast = left.text.characters.last;
  final rightFirst = right.text.characters.first;
  if (!_isReadableWordStart(rightFirst)) {
    return false;
  }
  if (':;'.contains(leftLast)) {
    return true;
  }
  if (!_isReadableWordEnd(leftLast)) {
    return false;
  }
  final boundaryCrossesStyle = left.style != right.style;
  if (!boundaryCrossesStyle) {
    return false;
  }
  return _startsWithCommonContinuationWord(right.text);
}

bool _startsWithWhitespace(String value) {
  return value.characters.first.trim().isEmpty;
}

bool _endsWithWhitespace(String value) {
  return value.characters.last.trim().isEmpty;
}

bool _isReadableWordStart(String value) {
  return RegExp(r'^[A-Za-z0-9]$').hasMatch(value);
}

bool _isReadableWordEnd(String value) {
  return RegExp(r'^[A-Za-z0-9]$').hasMatch(value);
}

bool _startsWithCommonContinuationWord(String value) {
  final normalized = value.toLowerCase();
  const words = [
    'and',
    'are',
    'as',
    'but',
    'for',
    'from',
    'has',
    'have',
    'in',
    'is',
    'no',
    'not',
    'of',
    'on',
    'or',
    'to',
    'was',
    'were',
    'with',
  ];
  for (final word in words) {
    if (normalized == word || normalized.startsWith('$word ')) {
      return true;
    }
  }
  return false;
}

class _AnnouncementCodePreview extends StatelessWidget {
  const _AnnouncementCodePreview({
    required this.content,
    required this.language,
  });

  final String content;
  final String language;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language.trim().isEmpty ? 'code' : language.trim(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.textMuted,
              fontWeight: VerdantFontWeights.black,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            content.trim(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.text,
              fontFamily: 'Consolas',
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementButtonPreview extends StatelessWidget {
  const _AnnouncementButtonPreview({
    required this.label,
    required this.url,
    required this.linkLauncher,
  });

  final String label;
  final String url;
  final WorkspaceLinkLauncher linkLauncher;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final safeUrl = normalizeAnnouncementUrl(url);
    final uri = safeUrl == null ? null : Uri.tryParse(safeUrl);
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: uri == null
            ? null
            : () async => openExternalLinkWithWarning(
                context: context,
                uri: uri,
                linkLauncher: linkLauncher,
              ),
        icon: const Icon(Icons.open_in_new, size: 15),
        label: Text(label.trim().isEmpty ? 'Open link' : label.trim()),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}

class _AnnouncementChartPreview extends StatelessWidget {
  const _AnnouncementChartPreview({
    required this.title,
    required this.points,
    required this.kind,
  });

  final String? title;
  final List<FeedAnnouncementChartPoint> points;
  final FeedAnnouncementChartKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _chartPreviewMaxWidth(kind)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title?.trim().isNotEmpty == true
                    ? title!.trim()
                    : 'Data snapshot',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: VerdantFontWeights.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                kind.editorName.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.accentStrong,
                  fontWeight: VerdantFontWeights.black,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              switch (kind) {
                FeedAnnouncementChartKind.bar => _AnnouncementBarChart(
                  points: points,
                ),
                FeedAnnouncementChartKind.line => _AnnouncementLineChart(
                  points: points,
                ),
                FeedAnnouncementChartKind.donut => _AnnouncementDonutChart(
                  points: points,
                ),
                FeedAnnouncementChartKind.metrics => _AnnouncementMetricCards(
                  points: points,
                ),
                FeedAnnouncementChartKind.progress =>
                  _AnnouncementProgressChart(points: points),
                FeedAnnouncementChartKind.sparkline =>
                  _AnnouncementSparklineChart(points: points),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementBarChart extends StatelessWidget {
  const _AnnouncementBarChart({required this.points});

  final List<FeedAnnouncementChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final maxY = _chartMaxY(points);
    return SizedBox(
      height: 176,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: 12,
          borderData: FlBorderData(show: false),
          gridData: _chartGridData(colors, maxY),
          titlesData: _bottomOnlyTitlesData(
            context,
            points: points,
            labelMode: _ChartLabelMode.selected,
          ),
          barTouchData: BarTouchData(
            mouseCursorResolver: (event, response) => response?.spot == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipBorder: BorderSide(color: colors.border),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              getTooltipColor: (_) => colors.panelRaised,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final index = group.x;
                final point = index >= 0 && index < points.length
                    ? points[index]
                    : null;
                return BarTooltipItem(
                  point == null
                      ? _formatChartValue(rod.toY)
                      : '${point.label}\n${_formatChartValue(point.value)}',
                  TextStyle(
                    color: colors.text,
                    fontSize: 11,
                    fontWeight: VerdantFontWeights.bold,
                  ),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i += 1)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: math.max(0, points[i].value),
                    width: points.length > 8 ? 12 : 18,
                    color: colors.accentStrong,
                    borderRadius: BorderRadius.circular(6),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: colors.border.withValues(alpha: 0.28),
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _AnnouncementLineChart extends StatelessWidget {
  const _AnnouncementLineChart({required this.points});

  final List<FeedAnnouncementChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final maxY = _chartMaxY(points);
    return SizedBox(
      height: 168,
      child: LineChart(
        _lineChartData(
          context,
          points: points,
          maxY: maxY,
          colors: colors,
          compact: false,
        ),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _AnnouncementDonutChart extends StatefulWidget {
  const _AnnouncementDonutChart({required this.points});

  final List<FeedAnnouncementChartPoint> points;

  @override
  State<_AnnouncementDonutChart> createState() =>
      _AnnouncementDonutChartState();
}

class _AnnouncementDonutChartState extends State<_AnnouncementDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final palette = _chartPalette(colors);
    final total = _positiveChartTotal(widget.points);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 39,
              centerSpaceColor: colors.panel,
              sectionsSpace: 3,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                mouseCursorResolver: (event, response) =>
                    response?.touchedSection == null
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response?.touchedSection == null) {
                    setState(() => _touchedIndex = -1);
                    return;
                  }
                  setState(
                    () => _touchedIndex =
                        response!.touchedSection!.touchedSectionIndex,
                  );
                },
              ),
              sections: [
                for (var i = 0; i < widget.points.length; i += 1)
                  PieChartSectionData(
                    value: math.max(0, widget.points[i].value),
                    color: palette[i % palette.length],
                    radius: i == _touchedIndex ? 45 : 38,
                    showTitle: false,
                    cornerRadius: 3,
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 540),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < widget.points.length; i += 1)
                Tooltip(
                  message:
                      '${widget.points[i].label}: ${_formatChartValue(widget.points[i].value)}',
                  waitDuration: const Duration(milliseconds: 260),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: palette[i % palette.length],
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.points[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          total <= 0
                              ? _formatChartValue(widget.points[i].value)
                              : '${((math.max(0, widget.points[i].value) / total) * 100).round()}%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.textMuted,
                                fontWeight: VerdantFontWeights.black,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnnouncementMetricCards extends StatelessWidget {
  const _AnnouncementMetricCards({required this.points});

  final List<FeedAnnouncementChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 420
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final point in points.take(6))
              Tooltip(
                message: '${point.label}: ${_formatChartValue(point.value)}',
                waitDuration: const Duration(milliseconds: 260),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: cardWidth,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.panelRaised,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontWeight: VerdantFontWeights.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatChartValue(point.value),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.accentStrong,
                              fontWeight: VerdantFontWeights.black,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AnnouncementProgressChart extends StatelessWidget {
  const _AnnouncementProgressChart({required this.points});

  final List<FeedAnnouncementChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Column(
      children: [
        for (final point in points.take(6))
          Tooltip(
            message: '${point.label}: ${_formatChartValue(point.value)}%',
            waitDuration: const Duration(milliseconds: 260),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_formatChartValue(point.value)}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontWeight: VerdantFontWeights.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 11,
                          color: colors.border.withValues(alpha: 0.45),
                        ),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 620),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(
                            begin: 0,
                            end: (point.value / 100).clamp(0.0, 1.0).toDouble(),
                          ),
                          builder: (context, widthFactor, child) {
                            return FractionallySizedBox(
                              widthFactor: widthFactor,
                              child: child,
                            );
                          },
                          child: Container(
                            height: 11,
                            color: colors.accentStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AnnouncementSparklineChart extends StatelessWidget {
  const _AnnouncementSparklineChart({required this.points});

  final List<FeedAnnouncementChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final latest = points.isEmpty ? null : points.last;
    final maxY = _chartMaxY(points);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 82,
            child: LineChart(
              _lineChartData(
                context,
                points: points,
                maxY: maxY,
                colors: colors,
                compact: true,
              ),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        if (latest != null) ...[
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: 3),
              Text(
                _formatChartValue(latest.value),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.accentStrong,
                  fontWeight: VerdantFontWeights.black,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

enum _ChartLabelMode { edge, selected }

LineChartData _lineChartData(
  BuildContext context, {
  required List<FeedAnnouncementChartPoint> points,
  required double maxY,
  required VerdantThemeColors colors,
  required bool compact,
}) {
  return LineChartData(
    minX: 0,
    maxX: _chartMaxX(points),
    minY: 0,
    maxY: maxY,
    clipData: const FlClipData.all(),
    borderData: FlBorderData(show: false),
    gridData: compact
        ? const FlGridData(show: false)
        : _chartGridData(colors, maxY),
    titlesData: compact
        ? const FlTitlesData(show: false)
        : _bottomOnlyTitlesData(
            context,
            points: points,
            labelMode: _ChartLabelMode.edge,
          ),
    lineTouchData: LineTouchData(
      enabled: points.isNotEmpty,
      touchSpotThreshold: 14,
      getTouchLineStart: (barData, spotIndex) => 0,
      touchTooltipData: LineTouchTooltipData(
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        tooltipBorderRadius: BorderRadius.circular(8),
        tooltipBorder: BorderSide(color: colors.border),
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        getTooltipColor: (_) => colors.panelRaised,
        getTooltipItems: (spots) {
          return [
            for (final spot in spots)
              LineTooltipItem(
                _lineTooltipText(points, spot),
                TextStyle(
                  color: colors.text,
                  fontSize: 11,
                  fontWeight: VerdantFontWeights.bold,
                ),
                textAlign: TextAlign.left,
              ),
          ];
        },
      ),
      getTouchedSpotIndicator: (barData, indexes) {
        return [
          for (final _ in indexes)
            TouchedSpotIndicatorData(
              FlLine(
                color: colors.accentStrong.withValues(alpha: 0.44),
                strokeWidth: 1.2,
              ),
              FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    _chartDotPainter(colors, radius: 4.5),
              ),
            ),
        ];
      },
    ),
    lineBarsData: [
      LineChartBarData(
        spots: _chartSpots(points),
        isCurved: points.length > 2,
        curveSmoothness: 0.25,
        preventCurveOverShooting: true,
        color: colors.accentStrong,
        barWidth: compact ? 2.2 : 2.8,
        isStrokeCapRound: true,
        isStrokeJoinRound: true,
        dotData: FlDotData(
          show: !compact && points.length <= 8,
          getDotPainter: (spot, percent, bar, index) =>
              _chartDotPainter(colors, radius: 3.4),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: colors.accent.withValues(alpha: compact ? 0.10 : 0.13),
        ),
      ),
    ],
  );
}

FlGridData _chartGridData(VerdantThemeColors colors, double maxY) {
  return FlGridData(
    drawVerticalLine: false,
    horizontalInterval: math.max(1, maxY / 4),
    getDrawingHorizontalLine: (value) =>
        FlLine(color: colors.border.withValues(alpha: 0.38), strokeWidth: 1),
  );
}

FlTitlesData _bottomOnlyTitlesData(
  BuildContext context, {
  required List<FeedAnnouncementChartPoint> points,
  required _ChartLabelMode labelMode,
}) {
  return FlTitlesData(
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: points.isNotEmpty,
        interval: 1,
        reservedSize: 30,
        getTitlesWidget: (value, meta) {
          return _chartBottomTitle(
            context,
            points: points,
            value: value,
            meta: meta,
            labelMode: labelMode,
          );
        },
      ),
    ),
  );
}

Widget _chartBottomTitle(
  BuildContext context, {
  required List<FeedAnnouncementChartPoint> points,
  required double value,
  required TitleMeta meta,
  required _ChartLabelMode labelMode,
}) {
  final index = value.round();
  if ((value - index).abs() > 0.01 ||
      index < 0 ||
      index >= points.length ||
      !_shouldShowChartAxisLabel(index, points.length, labelMode)) {
    return const SizedBox.shrink();
  }
  final colors = VerdantThemeColors.of(context);
  return SideTitleWidget(
    meta: meta,
    space: 6,
    fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
    child: SizedBox(
      width: 68,
      child: Text(
        points[index].label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: index == 0
            ? TextAlign.left
            : index == points.length - 1
            ? TextAlign.right
            : TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
      ),
    ),
  );
}

bool _shouldShowChartAxisLabel(
  int index,
  int length,
  _ChartLabelMode labelMode,
) {
  if (length <= 0) {
    return false;
  }
  if (labelMode == _ChartLabelMode.edge) {
    return index == 0 || index == length - 1;
  }
  if (length <= 6) {
    return true;
  }
  if (index == 0 || index == length - 1) {
    return true;
  }
  return length <= 10 && index.isEven;
}

List<FlSpot> _chartSpots(List<FeedAnnouncementChartPoint> points) {
  return [
    for (var i = 0; i < points.length; i += 1)
      FlSpot(i.toDouble(), math.max(0, points[i].value)),
  ];
}

String _lineTooltipText(
  List<FeedAnnouncementChartPoint> points,
  LineBarSpot spot,
) {
  final index = spot.spotIndex;
  if (index < 0 || index >= points.length) {
    return _formatChartValue(spot.y);
  }
  final point = points[index];
  return '${point.label}\n${_formatChartValue(point.value)}';
}

FlDotPainter _chartDotPainter(
  VerdantThemeColors colors, {
  required double radius,
}) {
  return FlDotCirclePainter(
    radius: radius,
    color: colors.accentStrong,
    strokeWidth: 2,
    strokeColor: colors.panel,
  );
}

Color _hexColorOrDefault(String value, Color fallback) {
  final normalized = normalizeAnnouncementHexColor(value);
  final raw = normalized.startsWith('#') ? normalized.substring(1) : normalized;
  if (raw.length != 6) {
    return fallback;
  }
  return Color(int.parse('FF$raw', radix: 16));
}

String _formatChartValue(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

double _chartPreviewMaxWidth(FeedAnnouncementChartKind kind) {
  return switch (kind) {
    FeedAnnouncementChartKind.bar => 720,
    FeedAnnouncementChartKind.line => 760,
    FeedAnnouncementChartKind.donut => 520,
    FeedAnnouncementChartKind.metrics => 560,
    FeedAnnouncementChartKind.progress => 560,
    FeedAnnouncementChartKind.sparkline => 520,
  };
}

double _maxChartValue(List<FeedAnnouncementChartPoint> points) {
  var maxValue = 0.0;
  for (final point in points) {
    if (point.value > maxValue) {
      maxValue = point.value;
    }
  }
  return maxValue;
}

double _chartMaxY(List<FeedAnnouncementChartPoint> points) {
  final maxValue = _maxChartValue(points);
  if (maxValue <= 0) {
    return 1;
  }
  return maxValue * 1.18;
}

double _chartMaxX(List<FeedAnnouncementChartPoint> points) {
  return math.max(1, points.length - 1).toDouble();
}

double _positiveChartTotal(List<FeedAnnouncementChartPoint> points) {
  var total = 0.0;
  for (final point in points) {
    total += math.max(0, point.value);
  }
  return total;
}

List<Color> _chartPalette(VerdantThemeColors colors) {
  return [
    colors.accentStrong,
    const Color(0xFF60A5FA),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFFA78BFA),
    const Color(0xFF34D399),
  ];
}
