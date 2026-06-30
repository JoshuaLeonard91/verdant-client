import 'package:flutter/widgets.dart';

import 'announcement_content_models.dart';

class AnnouncementFeedBuilderController extends ChangeNotifier {
  AnnouncementFeedBuilderController({FeedAnnouncementDraft? initialDraft})
    : _accentColor = initialDraft == null
          ? defaultAnnouncementAccent
          : normalizeAnnouncementHexColor(initialDraft.color),
      _titleStyle = initialDraft?.titleStyle,
      _descriptionStyle = initialDraft?.descriptionStyle,
      _footerStyle = initialDraft?.footerStyle,
      _sections = [...?initialDraft?.sections] {
    titleController.text = initialDraft?.title ?? '';
    descriptionController.text = initialDraft?.description ?? '';
    footerController.text = initialDraft?.footer ?? '';
    titleController.addListener(_handleTextChanged);
    descriptionController.addListener(_handleTextChanged);
    footerController.addListener(_handleTextChanged);
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController footerController = TextEditingController();
  final List<FeedAnnouncementSection> _sections;
  String _accentColor;
  FeedAnnouncementTextStyle? _titleStyle;
  FeedAnnouncementTextStyle? _descriptionStyle;
  FeedAnnouncementTextStyle? _footerStyle;

  String get accentColor => _accentColor;
  FeedAnnouncementTextStyle? get titleStyle => _titleStyle;
  FeedAnnouncementTextStyle? get descriptionStyle => _descriptionStyle;
  FeedAnnouncementTextStyle? get footerStyle => _footerStyle;

  List<FeedAnnouncementSection> get sections => List.unmodifiable(_sections);

  FeedAnnouncementDraft get draft {
    final description = descriptionController.text.trim();
    final footer = footerController.text.trim();
    return FeedAnnouncementDraft(
      title: titleController.text,
      description: description.isEmpty ? null : description,
      titleStyle: _titleStyle?.hasContent == true ? _titleStyle : null,
      descriptionStyle: _descriptionStyle?.hasContent == true
          ? _descriptionStyle
          : null,
      color: _accentColor,
      sections: sections,
      footer: footer.isEmpty ? null : footer,
      footerStyle: _footerStyle?.hasContent == true ? _footerStyle : null,
    );
  }

  void setAccentColor(String value) {
    final next = normalizeAnnouncementHexColor(value);
    if (next == _accentColor) {
      return;
    }
    _accentColor = next;
    notifyListeners();
  }

  void setTitleStyle(FeedAnnouncementTextStyle? value) {
    _titleStyle = value?.hasContent == true ? value : null;
    notifyListeners();
  }

  void setDescriptionStyle(FeedAnnouncementTextStyle? value) {
    _descriptionStyle = value?.hasContent == true ? value : null;
    notifyListeners();
  }

  void setFooterStyle(FeedAnnouncementTextStyle? value) {
    _footerStyle = value?.hasContent == true ? value : null;
    notifyListeners();
  }

  void addTextSection([String content = 'Write the update details here.']) {
    _sections.add(FeedAnnouncementTextSection(content: content));
    notifyListeners();
  }

  void addRichTextSection([
    String text = 'Highlight important parts of the announcement.',
  ]) {
    _sections.add(
      FeedAnnouncementRichTextSection(
        spans: [FeedAnnouncementRichTextSpan(text: text)],
      ),
    );
    notifyListeners();
  }

  void addCodeSection([String content = 'const message = "Hello Verdant";']) {
    _sections.add(
      FeedAnnouncementCodeSection(content: content, language: 'js'),
    );
    notifyListeners();
  }

  void addHeadingSection([String content = 'Section heading']) {
    _sections.add(FeedAnnouncementHeadingSection(content: content));
    notifyListeners();
  }

  void addListSection({
    List<String> items = const ['First item', 'Second item'],
    bool ordered = false,
  }) {
    _sections.add(FeedAnnouncementListSection(items: items, ordered: ordered));
    notifyListeners();
  }

  void addDividerSection() {
    _sections.add(const FeedAnnouncementDividerSection());
    notifyListeners();
  }

  void addButtonSection([
    String label = 'Open link',
    String url = 'https://verdant.chat',
  ]) {
    _sections.add(FeedAnnouncementButtonSection(label: label, url: url));
    notifyListeners();
  }

  void addYouTubeSection([
    String url = 'https://www.youtube.com/watch?v=k1_ODDevbY8',
  ]) {
    _sections.add(FeedAnnouncementYouTubeSection(url: url));
    notifyListeners();
  }

  void addChartSection([
    String data =
        'type: bar\ntitle: Sample data\nWeek 1: 42\nWeek 2: 64\nWeek 3: 81',
  ]) {
    _sections.add(
      _chartSectionFromEditor(
        const FeedAnnouncementChartSection(data: ''),
        data,
      ),
    );
    notifyListeners();
  }

  void updateSectionContent(int index, String content) {
    if (index < 0 || index >= _sections.length) {
      return;
    }
    final current = _sections[index];
    _sections[index] = switch (current) {
      FeedAnnouncementTextSection() => current.copyWith(content: content),
      FeedAnnouncementRichTextSection() => current,
      FeedAnnouncementCodeSection() => current.copyWith(content: content),
      FeedAnnouncementHeadingSection() => current.copyWith(content: content),
      FeedAnnouncementListSection() => _listSectionFromEditor(current, content),
      FeedAnnouncementDividerSection() => current,
      FeedAnnouncementButtonSection() => _buttonSectionFromEditor(
        current,
        content,
      ),
      FeedAnnouncementYouTubeSection() => current.copyWith(url: content),
      FeedAnnouncementChartSection() => _chartSectionFromEditor(
        current,
        content,
      ),
    };
    notifyListeners();
  }

  void addRichTextSpan({required int sectionIndex, String text = ''}) {
    _replaceRichTextSection(sectionIndex, (section) {
      return section.copyWith(
        spans: [
          ...section.spans,
          FeedAnnouncementRichTextSpan(text: text),
        ],
      );
    });
  }

  void updateRichTextContent({
    required int sectionIndex,
    required String text,
  }) {
    _replaceRichTextSection(sectionIndex, (section) {
      return section.copyWith(
        spans: _mergeAdjacentRichTextSpans(
          _reflowRichTextSpans(section.spans, text),
        ),
      );
    });
  }

  void applyRichTextSelectionStyle({
    required int sectionIndex,
    required TextSelection selection,
    required FeedAnnouncementTextStyle? style,
  }) {
    if (selection.isCollapsed) {
      return;
    }
    _replaceRichTextSection(sectionIndex, (section) {
      final plainText = richTextPlainText(section.spans);
      final start = selection.start.clamp(0, plainText.length);
      final end = selection.end.clamp(0, plainText.length);
      if (start >= end) {
        return section;
      }
      final nextSpans = _mergeAdjacentRichTextSpans(
        _applyStyleToRichTextRange(
          spans: section.spans,
          start: start,
          end: end,
          style: style?.hasContent == true ? style : null,
        ),
      );
      return section.copyWith(spans: nextSpans);
    });
  }

  void updateRichTextSpan({
    required int sectionIndex,
    required int spanIndex,
    String? text,
    Object? style = _spanStyleSentinel,
  }) {
    _replaceRichTextSection(sectionIndex, (section) {
      if (spanIndex < 0 || spanIndex >= section.spans.length) {
        return section;
      }
      final spans = [...section.spans];
      final currentSpan = spans[spanIndex];
      spans[spanIndex] = identical(style, _spanStyleSentinel)
          ? currentSpan.copyWith(text: text)
          : currentSpan.copyWith(
              text: text,
              style: style as FeedAnnouncementTextStyle?,
            );
      return section.copyWith(spans: spans);
    });
  }

  void removeRichTextSpan({required int sectionIndex, required int spanIndex}) {
    _replaceRichTextSection(sectionIndex, (section) {
      if (spanIndex < 0 || spanIndex >= section.spans.length) {
        return section;
      }
      final spans = [...section.spans]..removeAt(spanIndex);
      return section.copyWith(spans: spans);
    });
  }

  void removeSection(int index) {
    if (index < 0 || index >= _sections.length) {
      return;
    }
    _sections.removeAt(index);
    notifyListeners();
  }

  void _handleTextChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    titleController.removeListener(_handleTextChanged);
    descriptionController.removeListener(_handleTextChanged);
    footerController.removeListener(_handleTextChanged);
    titleController.dispose();
    descriptionController.dispose();
    footerController.dispose();
    super.dispose();
  }

  void _replaceRichTextSection(
    int sectionIndex,
    FeedAnnouncementRichTextSection Function(FeedAnnouncementRichTextSection)
    update,
  ) {
    if (sectionIndex < 0 || sectionIndex >= _sections.length) {
      return;
    }
    final section = _sections[sectionIndex];
    if (section is! FeedAnnouncementRichTextSection) {
      return;
    }
    _sections[sectionIndex] = update(section);
    notifyListeners();
  }
}

String richTextPlainText(List<FeedAnnouncementRichTextSpan> spans) {
  return spans.map((span) => span.text).join();
}

FeedAnnouncementListSection _listSectionFromEditor(
  FeedAnnouncementListSection current,
  String content,
) {
  final items = [
    for (final line in content.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  return current.copyWith(items: items);
}

FeedAnnouncementButtonSection _buttonSectionFromEditor(
  FeedAnnouncementButtonSection current,
  String content,
) {
  final lines = content.split('\n');
  return current.copyWith(
    label: lines.isEmpty || lines.first.trim().isEmpty
        ? current.label
        : lines.first.trim(),
    url: lines.length < 2 || lines[1].trim().isEmpty
        ? current.url
        : lines[1].trim(),
  );
}

FeedAnnouncementChartSection _chartSectionFromEditor(
  FeedAnnouncementChartSection current,
  String content,
) {
  final dataLines = <String>[];
  var title = current.title;
  var kind = current.kind;
  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.toLowerCase().startsWith('title:')) {
      title = line.substring('title:'.length).trim();
      continue;
    }
    if (line.toLowerCase().startsWith('type:') ||
        line.toLowerCase().startsWith('kind:')) {
      final separator = line.indexOf(':');
      kind = FeedAnnouncementChartKind.fromEditorValue(
        line.substring(separator + 1),
      );
      continue;
    }
    dataLines.add(rawLine);
  }
  return current.copyWith(
    title: title?.trim().isEmpty == true ? null : title,
    kind: kind,
    data: dataLines.join('\n').trim(),
  );
}

List<FeedAnnouncementRichTextSpan> _applyStyleToRichTextRange({
  required List<FeedAnnouncementRichTextSpan> spans,
  required int start,
  required int end,
  required FeedAnnouncementTextStyle? style,
}) {
  final next = <FeedAnnouncementRichTextSpan>[];
  var cursor = 0;
  for (final span in spans) {
    final spanStart = cursor;
    final spanEnd = spanStart + span.text.length;
    cursor = spanEnd;

    if (spanEnd <= start || spanStart >= end) {
      next.add(span);
      continue;
    }

    final overlapStart = start.clamp(spanStart, spanEnd);
    final overlapEnd = end.clamp(spanStart, spanEnd);
    final beforeLength = overlapStart - spanStart;
    final selectedLength = overlapEnd - overlapStart;
    final afterStart = beforeLength + selectedLength;

    if (beforeLength > 0) {
      next.add(
        FeedAnnouncementRichTextSpan(
          text: span.text.substring(0, beforeLength),
          style: span.style,
        ),
      );
    }
    if (selectedLength > 0) {
      next.add(
        FeedAnnouncementRichTextSpan(
          text: span.text.substring(beforeLength, afterStart),
          style: style,
        ),
      );
    }
    if (afterStart < span.text.length) {
      next.add(
        FeedAnnouncementRichTextSpan(
          text: span.text.substring(afterStart),
          style: span.style,
        ),
      );
    }
  }
  return next.isEmpty ? [const FeedAnnouncementRichTextSpan(text: '')] : next;
}

List<FeedAnnouncementRichTextSpan> _reflowRichTextSpans(
  List<FeedAnnouncementRichTextSpan> previousSpans,
  String nextText,
) {
  final previousText = richTextPlainText(previousSpans);
  if (previousText == nextText) {
    return previousSpans;
  }
  if (nextText.isEmpty) {
    return [const FeedAnnouncementRichTextSpan(text: '')];
  }

  var prefixLength = 0;
  final prefixLimit = previousText.length < nextText.length
      ? previousText.length
      : nextText.length;
  while (prefixLength < prefixLimit &&
      previousText.codeUnitAt(prefixLength) ==
          nextText.codeUnitAt(prefixLength)) {
    prefixLength += 1;
  }

  var suffixLength = 0;
  while (suffixLength < previousText.length - prefixLength &&
      suffixLength < nextText.length - prefixLength &&
      previousText.codeUnitAt(previousText.length - suffixLength - 1) ==
          nextText.codeUnitAt(nextText.length - suffixLength - 1)) {
    suffixLength += 1;
  }

  final previousMiddleEnd = previousText.length - suffixLength;
  final nextMiddleEnd = nextText.length - suffixLength;
  final nextSpans = <FeedAnnouncementRichTextSpan>[
    ..._sliceRichTextSpans(previousSpans, 0, prefixLength),
  ];

  if (nextMiddleEnd > prefixLength) {
    nextSpans.add(
      FeedAnnouncementRichTextSpan(
        text: nextText.substring(prefixLength, nextMiddleEnd),
        style: _styleForInsertedRichText(
          previousSpans,
          prefixLength,
          suffixLength,
        ),
      ),
    );
  }

  if (suffixLength > 0) {
    nextSpans.addAll(
      _sliceRichTextSpans(
        previousSpans,
        previousMiddleEnd,
        previousText.length,
      ),
    );
  }

  return nextSpans.isEmpty
      ? [FeedAnnouncementRichTextSpan(text: nextText)]
      : nextSpans;
}

List<FeedAnnouncementRichTextSpan> _sliceRichTextSpans(
  List<FeedAnnouncementRichTextSpan> spans,
  int start,
  int end,
) {
  if (start >= end) {
    return const [];
  }
  final sliced = <FeedAnnouncementRichTextSpan>[];
  var cursor = 0;
  for (final span in spans) {
    final spanStart = cursor;
    final spanEnd = spanStart + span.text.length;
    cursor = spanEnd;
    if (spanEnd <= start || spanStart >= end) {
      continue;
    }
    final sliceStart = start.clamp(spanStart, spanEnd) - spanStart;
    final sliceEnd = end.clamp(spanStart, spanEnd) - spanStart;
    if (sliceStart >= sliceEnd) {
      continue;
    }
    sliced.add(
      FeedAnnouncementRichTextSpan(
        text: span.text.substring(sliceStart, sliceEnd),
        style: span.style,
      ),
    );
  }
  return sliced;
}

FeedAnnouncementTextStyle? _styleForInsertedRichText(
  List<FeedAnnouncementRichTextSpan> spans,
  int insertionOffset,
  int preservedSuffixLength,
) {
  if (insertionOffset <= 0) {
    return null;
  }
  return _richTextStyleAt(spans, insertionOffset - 1) ??
      (preservedSuffixLength > 0
          ? _richTextStyleAt(spans, insertionOffset)
          : null);
}

FeedAnnouncementTextStyle? _richTextStyleAt(
  List<FeedAnnouncementRichTextSpan> spans,
  int offset,
) {
  if (offset < 0) {
    return null;
  }
  var cursor = 0;
  for (final span in spans) {
    final end = cursor + span.text.length;
    if (offset >= cursor && offset < end) {
      return span.style;
    }
    cursor = end;
  }
  return spans.isEmpty ? null : spans.last.style;
}

List<FeedAnnouncementRichTextSpan> _mergeAdjacentRichTextSpans(
  List<FeedAnnouncementRichTextSpan> spans,
) {
  final merged = <FeedAnnouncementRichTextSpan>[];
  for (final span in spans) {
    if (span.text.isEmpty) {
      continue;
    }
    if (merged.isNotEmpty && _sameTextStyle(merged.last.style, span.style)) {
      final previous = merged.removeLast();
      merged.add(
        FeedAnnouncementRichTextSpan(
          text: '${previous.text}${span.text}',
          style: previous.style,
        ),
      );
      continue;
    }
    merged.add(span);
  }
  return merged.isEmpty
      ? [const FeedAnnouncementRichTextSpan(text: '')]
      : merged;
}

bool _sameTextStyle(
  FeedAnnouncementTextStyle? a,
  FeedAnnouncementTextStyle? b,
) {
  return a?.toJson().toString() == b?.toJson().toString();
}

const Object _spanStyleSentinel = Object();
