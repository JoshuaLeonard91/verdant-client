import 'dart:convert';

import '../../shared/youtube_embed/workspace_youtube_url.dart';

const defaultAnnouncementAccent = '#1ee3b6';
const minAnnouncementFontSize = 8.0;
const maxAnnouncementFontSize = 48.0;
final RegExp _hexColor = RegExp(r'^#[0-9a-fA-F]{6}$');

final class FeedAnnouncementDraft {
  const FeedAnnouncementDraft({
    required this.title,
    required this.color,
    this.description,
    this.titleStyle,
    this.descriptionStyle,
    this.sections = const [],
    this.footer,
    this.footerStyle,
  });

  factory FeedAnnouncementDraft.empty() {
    return const FeedAnnouncementDraft(
      title: '',
      color: defaultAnnouncementAccent,
    );
  }

  factory FeedAnnouncementDraft.fromJson(Map<String, Object?> json) {
    final title = _jsonString(json['title']).trim();
    if (title.isEmpty) {
      throw const FormatException('Announcement title was missing');
    }
    final sections = <FeedAnnouncementSection>[];
    final rawSections = json['sections'];
    if (rawSections is List) {
      for (final rawSection in rawSections) {
        final sectionMap = _jsonMap(rawSection);
        if (sectionMap == null) {
          continue;
        }
        final section = FeedAnnouncementSectionFromJson.fromJson(sectionMap);
        if (section != null) {
          sections.add(section);
        }
      }
    }
    return FeedAnnouncementDraft(
      title: title,
      description: _nullableJsonString(json['description']),
      titleStyle: FeedAnnouncementTextStyle.fromJson(
        _jsonMap(json['titleStyle']),
      ),
      descriptionStyle: FeedAnnouncementTextStyle.fromJson(
        _jsonMap(json['descriptionStyle']),
      ),
      color: normalizeAnnouncementHexColor(
        _jsonString(json['color'], fallback: defaultAnnouncementAccent),
      ),
      sections: sections,
      footer: _nullableJsonString(json['footer']),
      footerStyle: FeedAnnouncementTextStyle.fromJson(
        _jsonMap(json['footerStyle']),
      ),
    );
  }

  final String title;
  final String? description;
  final FeedAnnouncementTextStyle? titleStyle;
  final FeedAnnouncementTextStyle? descriptionStyle;
  final String color;
  final List<FeedAnnouncementSection> sections;
  final String? footer;
  final FeedAnnouncementTextStyle? footerStyle;

  bool get canSubmit => title.trim().isNotEmpty;

  FeedAnnouncementDraft copyWith({
    String? title,
    Object? description = _sentinel,
    Object? titleStyle = _sentinel,
    Object? descriptionStyle = _sentinel,
    String? color,
    List<FeedAnnouncementSection>? sections,
    Object? footer = _sentinel,
    Object? footerStyle = _sentinel,
  }) {
    return FeedAnnouncementDraft(
      title: title ?? this.title,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      titleStyle: identical(titleStyle, _sentinel)
          ? this.titleStyle
          : titleStyle as FeedAnnouncementTextStyle?,
      descriptionStyle: identical(descriptionStyle, _sentinel)
          ? this.descriptionStyle
          : descriptionStyle as FeedAnnouncementTextStyle?,
      color: color == null ? this.color : normalizeAnnouncementHexColor(color),
      sections: sections ?? this.sections,
      footer: identical(footer, _sentinel) ? this.footer : footer as String?,
      footerStyle: identical(footerStyle, _sentinel)
          ? this.footerStyle
          : footerStyle as FeedAnnouncementTextStyle?,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'title': title.trim()};
    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
      json['description'] = trimmedDescription;
    }
    final titleStyleJson = titleStyle?.toJson();
    if (titleStyleJson != null) {
      json['titleStyle'] = titleStyleJson;
    }
    final descriptionStyleJson = descriptionStyle?.toJson();
    if (descriptionStyleJson != null) {
      json['descriptionStyle'] = descriptionStyleJson;
    }
    json['color'] = normalizeAnnouncementHexColor(color);
    final sectionJson = [
      for (final section in sections)
        if (section.hasContent) section.toJson(),
    ];
    if (sectionJson.isNotEmpty) {
      json['sections'] = sectionJson;
    }
    final trimmedFooter = footer?.trim();
    if (trimmedFooter != null && trimmedFooter.isNotEmpty) {
      json['footer'] = trimmedFooter;
    }
    final footerStyleJson = footerStyle?.toJson();
    if (footerStyleJson != null) {
      json['footerStyle'] = footerStyleJson;
    }
    return json;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

enum FeedAnnouncementTextSize {
  xs('xs'),
  sm('sm'),
  md('md'),
  lg('lg'),
  xl('xl');

  const FeedAnnouncementTextSize(this.wireName);

  final String wireName;

  static FeedAnnouncementTextSize? fromJson(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    for (final size in values) {
      if (size.wireName == normalized) {
        return size;
      }
    }
    return null;
  }
}

enum FeedAnnouncementTextWeight {
  normal('normal'),
  medium('medium'),
  semibold('semibold'),
  bold('bold');

  const FeedAnnouncementTextWeight(this.wireName);

  final String wireName;

  static FeedAnnouncementTextWeight? fromJson(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    for (final weight in values) {
      if (weight.wireName == normalized) {
        return weight;
      }
    }
    return null;
  }
}

final class FeedAnnouncementTextStyle {
  const FeedAnnouncementTextStyle({
    this.color,
    this.size,
    this.fontSize,
    this.weight,
    this.italic,
    this.strikethrough,
  });

  factory FeedAnnouncementTextStyle.fromParts({
    String? color,
    FeedAnnouncementTextSize? size,
    double? fontSize,
    FeedAnnouncementTextWeight? weight,
    bool? italic,
    bool? strikethrough,
  }) {
    return FeedAnnouncementTextStyle(
      color: normalizeOptionalAnnouncementHexColor(color),
      size: size,
      fontSize: normalizeAnnouncementFontSize(fontSize),
      weight: weight,
      italic: italic == true ? true : null,
      strikethrough: strikethrough == true ? true : null,
    );
  }

  static FeedAnnouncementTextStyle? fromJson(Map<String, Object?>? json) {
    if (json == null) {
      return null;
    }
    final style = FeedAnnouncementTextStyle.fromParts(
      color: _nullableJsonString(json['color']),
      size: FeedAnnouncementTextSize.fromJson(json['size']),
      fontSize: _fontSizeFromJson(json['fontSize']),
      weight: FeedAnnouncementTextWeight.fromJson(json['weight']),
      italic: _jsonBool(json['italic']),
      strikethrough: _jsonBool(json['strikethrough']),
    );
    return style.hasContent ? style : null;
  }

  final String? color;
  final FeedAnnouncementTextSize? size;
  final double? fontSize;
  final FeedAnnouncementTextWeight? weight;
  final bool? italic;
  final bool? strikethrough;

  bool get hasContent =>
      color != null ||
      size != null ||
      fontSize != null ||
      weight != null ||
      italic == true ||
      strikethrough == true;

  FeedAnnouncementTextStyle copyWith({
    Object? color = _sentinel,
    Object? size = _sentinel,
    Object? fontSize = _sentinel,
    Object? weight = _sentinel,
    Object? italic = _sentinel,
    Object? strikethrough = _sentinel,
  }) {
    return FeedAnnouncementTextStyle.fromParts(
      color: identical(color, _sentinel) ? this.color : color as String?,
      size: identical(size, _sentinel)
          ? this.size
          : size as FeedAnnouncementTextSize?,
      fontSize: identical(fontSize, _sentinel)
          ? this.fontSize
          : fontSize as double?,
      weight: identical(weight, _sentinel)
          ? this.weight
          : weight as FeedAnnouncementTextWeight?,
      italic: identical(italic, _sentinel) ? this.italic : italic as bool?,
      strikethrough: identical(strikethrough, _sentinel)
          ? this.strikethrough
          : strikethrough as bool?,
    );
  }

  Map<String, Object?>? toJson() {
    if (!hasContent) {
      return null;
    }
    final normalizedColor = normalizeOptionalAnnouncementHexColor(color);
    final json = <String, Object?>{};
    if (normalizedColor != null) {
      json['color'] = normalizedColor;
    }
    if (size != null) {
      json['size'] = size!.wireName;
    }
    if (fontSize != null) {
      json['fontSize'] = fontSize;
    }
    if (weight != null) {
      json['weight'] = weight!.wireName;
    }
    if (italic == true) {
      json['italic'] = true;
    }
    if (strikethrough == true) {
      json['strikethrough'] = true;
    }
    return json;
  }
}

sealed class FeedAnnouncementSection {
  const FeedAnnouncementSection();

  bool get hasContent;

  Map<String, Object?> toJson();
}

abstract final class FeedAnnouncementSectionFromJson {
  static FeedAnnouncementSection? fromJson(Map<String, Object?> json) {
    final type = _jsonString(json['type']).trim().toLowerCase();
    return switch (type) {
      'text' => _textSectionFromJson(json),
      'richtext' || 'richText' => _richTextSectionFromJson(json),
      'code' => _codeSectionFromJson(json),
      'heading' => _headingSectionFromJson(json),
      'divider' => const FeedAnnouncementDividerSection(),
      'list' => _listSectionFromJson(json),
      'button' => _buttonSectionFromJson(json),
      'youtube' || 'video' => _youtubeSectionFromJson(json),
      'chart' => _chartSectionFromJson(json),
      _ => null,
    };
  }
}

final class FeedAnnouncementListSection extends FeedAnnouncementSection {
  const FeedAnnouncementListSection({
    required this.items,
    this.ordered = false,
    this.style,
  });

  final List<String> items;
  final bool ordered;
  final FeedAnnouncementTextStyle? style;

  @override
  bool get hasContent => items.any((item) => item.trim().isNotEmpty);

  FeedAnnouncementListSection copyWith({
    List<String>? items,
    bool? ordered,
    Object? style = _sentinel,
  }) {
    return FeedAnnouncementListSection(
      items: items ?? this.items,
      ordered: ordered ?? this.ordered,
      style: identical(style, _sentinel)
          ? this.style
          : style as FeedAnnouncementTextStyle?,
    );
  }

  @override
  Map<String, Object?> toJson() {
    final styleJson = style?.toJson();
    final json = <String, Object?>{
      'type': 'list',
      'items': [
        for (final item in items)
          if (item.trim().isNotEmpty) item.trim(),
      ],
      'ordered': ordered,
    };
    if (styleJson != null) {
      json['style'] = styleJson;
    }
    return json;
  }
}

final class FeedAnnouncementRichTextSpan {
  const FeedAnnouncementRichTextSpan({required this.text, this.style});

  final String text;
  final FeedAnnouncementTextStyle? style;

  bool get hasContent => text.trim().isNotEmpty;

  FeedAnnouncementRichTextSpan copyWith({
    String? text,
    Object? style = _sentinel,
  }) {
    return FeedAnnouncementRichTextSpan(
      text: text ?? this.text,
      style: identical(style, _sentinel)
          ? this.style
          : style as FeedAnnouncementTextStyle?,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'text': text};
    final styleJson = style?.toJson();
    if (styleJson != null) {
      json['style'] = styleJson;
    }
    return json;
  }
}

final class FeedAnnouncementRichTextSection extends FeedAnnouncementSection {
  const FeedAnnouncementRichTextSection({required this.spans, this.style});

  final List<FeedAnnouncementRichTextSpan> spans;
  final FeedAnnouncementTextStyle? style;

  @override
  bool get hasContent => spans.any((span) => span.hasContent);

  FeedAnnouncementRichTextSection copyWith({
    List<FeedAnnouncementRichTextSpan>? spans,
    Object? style = _sentinel,
  }) {
    return FeedAnnouncementRichTextSection(
      spans: spans ?? this.spans,
      style: identical(style, _sentinel)
          ? this.style
          : style as FeedAnnouncementTextStyle?,
    );
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'type': 'richText',
      'spans': [
        for (final span in spans)
          if (span.text.isNotEmpty) span.toJson(),
      ],
    };
    final styleJson = style?.toJson();
    if (styleJson != null) {
      json['style'] = styleJson;
    }
    return json;
  }
}

final class FeedAnnouncementTextSection extends FeedAnnouncementSection {
  const FeedAnnouncementTextSection({required this.content, this.color});

  final String content;
  final String? color;

  @override
  bool get hasContent => content.trim().isNotEmpty;

  FeedAnnouncementTextSection copyWith({String? content, Object? color}) {
    return FeedAnnouncementTextSection(
      content: content ?? this.content,
      color: color == null
          ? this.color
          : color is String
          ? normalizeAnnouncementHexColor(color)
          : null,
    );
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{'type': 'text', 'content': content.trim()};
    if (color != null) {
      json['color'] = normalizeAnnouncementHexColor(color!);
    }
    return json;
  }
}

final class FeedAnnouncementCodeSection extends FeedAnnouncementSection {
  const FeedAnnouncementCodeSection({
    required this.content,
    this.language = 'text',
  });

  final String content;
  final String language;

  @override
  bool get hasContent => content.trim().isNotEmpty;

  FeedAnnouncementCodeSection copyWith({String? content, String? language}) {
    return FeedAnnouncementCodeSection(
      content: content ?? this.content,
      language: _safeLabel(language ?? this.language, fallback: 'text'),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'code',
      'content': content.trim(),
      'language': _safeLabel(language, fallback: 'text'),
    };
  }
}

final class FeedAnnouncementHeadingSection extends FeedAnnouncementSection {
  const FeedAnnouncementHeadingSection({required this.content, this.level = 2});

  final String content;
  final int level;

  @override
  bool get hasContent => content.trim().isNotEmpty;

  FeedAnnouncementHeadingSection copyWith({String? content, int? level}) {
    return FeedAnnouncementHeadingSection(
      content: content ?? this.content,
      level: (level ?? this.level).clamp(1, 3),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'heading',
      'content': content.trim(),
      'level': level.clamp(1, 3),
    };
  }
}

final class FeedAnnouncementDividerSection extends FeedAnnouncementSection {
  const FeedAnnouncementDividerSection();

  @override
  bool get hasContent => true;

  @override
  Map<String, Object?> toJson() {
    return {'type': 'divider'};
  }
}

final class FeedAnnouncementButtonSection extends FeedAnnouncementSection {
  const FeedAnnouncementButtonSection({required this.label, required this.url});

  final String label;
  final String url;

  @override
  bool get hasContent =>
      label.trim().isNotEmpty && normalizeAnnouncementUrl(url) != null;

  FeedAnnouncementButtonSection copyWith({String? label, String? url}) {
    return FeedAnnouncementButtonSection(
      label: label ?? this.label,
      url: url ?? this.url,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'button',
      'label': label.trim(),
      'action': {'type': 'externalUrl', 'url': normalizeAnnouncementUrl(url)},
    };
  }
}

final class FeedAnnouncementYouTubeSection extends FeedAnnouncementSection {
  const FeedAnnouncementYouTubeSection({required this.url, this.title});

  final String url;
  final String? title;

  String? get videoId => extractYouTubeVideoId(url);

  @override
  bool get hasContent => videoId != null;

  FeedAnnouncementYouTubeSection copyWith({
    String? url,
    Object? title = _sentinel,
  }) {
    return FeedAnnouncementYouTubeSection(
      url: url ?? this.url,
      title: identical(title, _sentinel) ? this.title : title as String?,
    );
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'type': 'video',
      'url': normalizeAnnouncementUrl(url),
      'videoId': videoId,
    };
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      json['title'] = trimmedTitle;
    }
    return json;
  }
}

enum FeedAnnouncementChartKind {
  bar('bar'),
  line('line'),
  donut('donut'),
  metrics('metrics'),
  progress('progress'),
  sparkline('sparkline');

  const FeedAnnouncementChartKind(this.wireName);

  final String wireName;

  String get editorName => wireName;

  static FeedAnnouncementChartKind fromEditorValue(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '-');
    return switch (normalized) {
      'line' || 'line-chart' || 'trend' => FeedAnnouncementChartKind.line,
      'donut' || 'donut-chart' || 'pie' => FeedAnnouncementChartKind.donut,
      'metric' ||
      'metrics' ||
      'metric-cards' ||
      'kpi' => FeedAnnouncementChartKind.metrics,
      'progress' ||
      'progress-bars' ||
      'completion' => FeedAnnouncementChartKind.progress,
      'spark' ||
      'sparkline' ||
      'mini-line' => FeedAnnouncementChartKind.sparkline,
      _ => FeedAnnouncementChartKind.bar,
    };
  }
}

final class FeedAnnouncementChartSection extends FeedAnnouncementSection {
  const FeedAnnouncementChartSection({
    required this.data,
    this.title,
    this.kind = FeedAnnouncementChartKind.bar,
  });

  final String data;
  final String? title;
  final FeedAnnouncementChartKind kind;

  List<FeedAnnouncementChartPoint> get points =>
      parseAnnouncementChartData(data);

  @override
  bool get hasContent => points.isNotEmpty;

  FeedAnnouncementChartSection copyWith({
    String? data,
    Object? title = _sentinel,
    FeedAnnouncementChartKind? kind,
  }) {
    return FeedAnnouncementChartSection(
      data: data ?? this.data,
      title: identical(title, _sentinel) ? this.title : title as String?,
      kind: kind ?? this.kind,
    );
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'type': 'chart',
      'kind': kind.wireName,
      'points': [for (final point in points) point.toJson()],
    };
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      json['title'] = trimmedTitle;
    }
    return json;
  }
}

final class FeedAnnouncementChartPoint {
  const FeedAnnouncementChartPoint({required this.label, required this.value});

  final String label;
  final double value;

  Map<String, Object?> toJson() {
    return {'label': label, 'value': value};
  }
}

String normalizeAnnouncementHexColor(String value) {
  final trimmed = value.trim();
  if (_hexColor.hasMatch(trimmed)) {
    return trimmed.toLowerCase();
  }
  return defaultAnnouncementAccent;
}

String? normalizeOptionalAnnouncementHexColor(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final prefixed = trimmed.startsWith('#') ? trimmed : '#$trimmed';
  if (_hexColor.hasMatch(prefixed)) {
    return prefixed.toLowerCase();
  }
  return null;
}

String? normalizeAnnouncementUrl(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https' || uri.host.trim().isEmpty) {
    return null;
  }
  return uri.toString();
}

String? extractYouTubeVideoId(String value) {
  return extractWorkspaceYouTubeVideoId(value);
}

List<FeedAnnouncementChartPoint> parseAnnouncementChartData(String value) {
  final points = <FeedAnnouncementChartPoint>[];
  for (final rawLine in value.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    final separator = line.contains(':') ? ':' : ',';
    final parts = line.split(separator);
    if (parts.length < 2) {
      continue;
    }
    final label = parts.first.trim();
    final parsedValue = double.tryParse(
      parts.sublist(1).join(separator).trim(),
    );
    if (label.isEmpty || parsedValue == null || parsedValue.isNaN) {
      continue;
    }
    points.add(FeedAnnouncementChartPoint(label: label, value: parsedValue));
  }
  return points;
}

FeedAnnouncementTextSection? _textSectionFromJson(Map<String, Object?> json) {
  final section = FeedAnnouncementTextSection(
    content: _jsonString(json['content']),
    color: _nullableJsonString(json['color']),
  );
  return section.hasContent ? section : null;
}

FeedAnnouncementRichTextSection? _richTextSectionFromJson(
  Map<String, Object?> json,
) {
  final spans = <FeedAnnouncementRichTextSpan>[];
  final rawSpans = json['spans'];
  if (rawSpans is List) {
    for (final rawSpan in rawSpans) {
      final spanMap = _jsonMap(rawSpan);
      if (spanMap == null) {
        continue;
      }
      final span = FeedAnnouncementRichTextSpan(
        text: _jsonString(spanMap['text']),
        style: FeedAnnouncementTextStyle.fromJson(_jsonMap(spanMap['style'])),
      );
      if (span.text.isNotEmpty) {
        spans.add(span);
      }
    }
  }
  final section = FeedAnnouncementRichTextSection(
    spans: spans,
    style: FeedAnnouncementTextStyle.fromJson(_jsonMap(json['style'])),
  );
  return section.hasContent ? section : null;
}

FeedAnnouncementCodeSection? _codeSectionFromJson(Map<String, Object?> json) {
  final section = FeedAnnouncementCodeSection(
    content: _jsonString(json['content']),
    language: _safeLabel(_jsonString(json['language']), fallback: 'text'),
  );
  return section.hasContent ? section : null;
}

FeedAnnouncementHeadingSection? _headingSectionFromJson(
  Map<String, Object?> json,
) {
  final rawLevel = json['level'];
  final section = FeedAnnouncementHeadingSection(
    content: _jsonString(json['content']),
    level: rawLevel is num ? rawLevel.round().clamp(1, 3).toInt() : 2,
  );
  return section.hasContent ? section : null;
}

FeedAnnouncementListSection? _listSectionFromJson(Map<String, Object?> json) {
  final items = <String>[];
  final rawItems = json['items'];
  if (rawItems is List) {
    for (final rawItem in rawItems) {
      final item = _jsonString(rawItem).trim();
      if (item.isNotEmpty) {
        items.add(item);
      }
    }
  }
  final section = FeedAnnouncementListSection(
    items: items,
    ordered: _jsonBool(json['ordered']) == true,
    style: FeedAnnouncementTextStyle.fromJson(_jsonMap(json['style'])),
  );
  return section.hasContent ? section : null;
}

FeedAnnouncementButtonSection? _buttonSectionFromJson(
  Map<String, Object?> json,
) {
  final label = _jsonString(json['label']);
  var url = _nullableJsonString(json['url']);
  final action = _jsonMap(json['action']);
  if (action != null) {
    final actionType = _jsonString(action['type']).trim();
    if (actionType == 'externalUrl') {
      url = _nullableJsonString(action['url']);
    }
  }
  if (url == null) {
    return null;
  }
  final section = FeedAnnouncementButtonSection(label: label, url: url);
  return section.hasContent ? section : null;
}

FeedAnnouncementYouTubeSection? _youtubeSectionFromJson(
  Map<String, Object?> json,
) {
  final url =
      _nullableJsonString(json['url']) ??
      _youtubeWatchUrl(_nullableJsonString(json['videoId']));
  if (url == null) {
    return null;
  }
  final section = FeedAnnouncementYouTubeSection(
    url: url,
    title: _nullableJsonString(json['title']),
  );
  return section.hasContent ? section : null;
}

FeedAnnouncementChartSection? _chartSectionFromJson(Map<String, Object?> json) {
  final points = <FeedAnnouncementChartPoint>[];
  final rawPoints = json['points'];
  if (rawPoints is List) {
    for (final rawPoint in rawPoints) {
      final pointMap = _jsonMap(rawPoint);
      if (pointMap == null) {
        continue;
      }
      final label = _jsonString(pointMap['label']).trim();
      final rawValue = pointMap['value'];
      if (label.isEmpty || rawValue is! num || !rawValue.isFinite) {
        continue;
      }
      points.add(
        FeedAnnouncementChartPoint(label: label, value: rawValue.toDouble()),
      );
    }
  }
  final section = FeedAnnouncementChartSection(
    data: _chartDataFromPoints(points),
    title: _nullableJsonString(json['title']),
    kind: FeedAnnouncementChartKind.fromEditorValue(_jsonString(json['kind'])),
  );
  return section.hasContent ? section : null;
}

String _chartDataFromPoints(List<FeedAnnouncementChartPoint> points) {
  return points
      .map((point) => '${point.label}: ${_formatChartValue(point.value)}')
      .join('\n');
}

String _formatChartValue(double value) {
  if (value.isFinite && value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toString();
}

Map<String, Object?>? _jsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    final mapped = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is String) {
        mapped[key] = entry.value;
      }
    }
    return mapped;
  }
  return null;
}

String _jsonString(Object? value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

String? _nullableJsonString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool? _jsonBool(Object? value) {
  return value is bool ? value : null;
}

double? normalizeAnnouncementFontSize(double? value) {
  if (value == null || !value.isFinite) {
    return null;
  }
  final clamped = value.clamp(minAnnouncementFontSize, maxAnnouncementFontSize);
  return (clamped * 10).roundToDouble() / 10;
}

double? _fontSizeFromJson(Object? value) {
  if (value is! num || !value.isFinite) {
    return null;
  }
  return normalizeAnnouncementFontSize(value.toDouble());
}

String? _youtubeWatchUrl(String? videoId) {
  if (videoId == null || _cleanYouTubeId(videoId) == null) {
    return null;
  }
  return 'https://www.youtube.com/watch?v=$videoId';
}

String _safeLabel(String value, {required String fallback}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > 32) {
    return fallback;
  }
  final safe = trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9_#+.-]'), '');
  return safe.isEmpty ? fallback : safe;
}

String? _cleanYouTubeId(String value) {
  final trimmed = value.trim();
  if (RegExp(r'^[a-zA-Z0-9_-]{6,32}$').hasMatch(trimmed)) {
    return trimmed;
  }
  return null;
}

const Object _sentinel = Object();
