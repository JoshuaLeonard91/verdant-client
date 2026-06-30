import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_content_models.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_feed_builder_controller.dart';

void main() {
  test('builder controller emits backend announcement schema only', () {
    final controller = AnnouncementFeedBuilderController();
    addTearDown(controller.dispose);

    controller.titleController.text = 'Client 0.0.260 released';
    controller.descriptionController.text = 'Release notes stay structured.';
    controller.setAccentColor('#22c55e');
    controller.addHeadingSection('Highlights');
    controller.addTextSection('<script>alert(1)</script> stays literal text');
    controller.addDividerSection();

    final json = controller.draft.toJson();

    expect(json.keys, ['title', 'description', 'color', 'sections']);
    expect(json['title'], 'Client 0.0.260 released');
    expect(json['description'], 'Release notes stay structured.');
    expect(json['color'], '#22c55e');
    expect(json['sections'], [
      {'type': 'heading', 'content': 'Highlights', 'level': 2},
      {
        'type': 'text',
        'content': '<script>alert(1)</script> stays literal text',
      },
      {'type': 'divider'},
    ]);
  });

  test('draft validity follows backend title requirement', () {
    final empty = FeedAnnouncementDraft.empty();
    expect(empty.canSubmit, isFalse);

    final titled = empty.copyWith(title: 'Maintenance window');
    expect(titled.canSubmit, isTrue);
  });

  test('advanced blocks emit constrained structured schema', () {
    final controller = AnnouncementFeedBuilderController();
    addTearDown(controller.dispose);

    controller.titleController.text = 'Builder blocks';
    controller.addCodeSection('final count = 42;');
    controller.addListSection(items: ['Prepare build', 'Notify members']);
    controller.addListSection(
      items: ['Stage release', 'Publish release'],
      ordered: true,
    );
    controller.addChartSection('Active users: 42\nMessages: 128');
    controller.addYouTubeSection('https://www.youtube.com/watch?v=k1_ODDevbY8');
    controller.addButtonSection('Read notes', 'https://verdant.chat');

    final json = controller.draft.toJson();

    expect(json.keys, ['title', 'color', 'sections']);
    expect(json['sections'], [
      {'type': 'code', 'content': 'final count = 42;', 'language': 'js'},
      {
        'type': 'list',
        'items': ['Prepare build', 'Notify members'],
        'ordered': false,
      },
      {
        'type': 'list',
        'items': ['Stage release', 'Publish release'],
        'ordered': true,
      },
      {
        'type': 'chart',
        'kind': 'bar',
        'points': [
          {'label': 'Active users', 'value': 42.0},
          {'label': 'Messages', 'value': 128.0},
        ],
      },
      {
        'type': 'video',
        'url': 'https://www.youtube.com/watch?v=k1_ODDevbY8',
        'videoId': 'k1_ODDevbY8',
      },
      {
        'type': 'button',
        'label': 'Read notes',
        'action': {'type': 'externalUrl', 'url': 'https://verdant.chat'},
      },
    ]);
  });

  test('rich text blocks emit flat styled spans', () {
    final controller = AnnouncementFeedBuilderController();
    addTearDown(controller.dispose);

    controller.titleController.text = 'Rich text';
    controller.addRichTextSection('Important notice');
    controller.applyRichTextSelectionStyle(
      sectionIndex: 0,
      selection: const TextSelection(baseOffset: 0, extentOffset: 10),
      style: const FeedAnnouncementTextStyle(
        weight: FeedAnnouncementTextWeight.bold,
        italic: true,
        strikethrough: true,
      ),
    );
    controller.applyRichTextSelectionStyle(
      sectionIndex: 0,
      selection: const TextSelection(baseOffset: 10, extentOffset: 16),
      style: const FeedAnnouncementTextStyle(color: '#ff005b', fontSize: 16),
    );

    final json = controller.draft.toJson();

    expect(json['sections'], [
      {
        'type': 'richText',
        'spans': [
          {
            'text': 'Important ',
            'style': {'weight': 'bold', 'italic': true, 'strikethrough': true},
          },
          {
            'text': 'notice',
            'style': {'color': '#ff005b', 'fontSize': 16.0},
          },
        ],
      },
    ]);
  });

  test('rich text JSON preserves whitespace boundary spans', () {
    const section = FeedAnnouncementRichTextSection(
      spans: [
        FeedAnnouncementRichTextSpan(text: 'Highlight'),
        FeedAnnouncementRichTextSpan(text: ' '),
        FeedAnnouncementRichTextSpan(
          text: 'important',
          style: FeedAnnouncementTextStyle(color: '#ff005b'),
        ),
        FeedAnnouncementRichTextSpan(text: ' '),
        FeedAnnouncementRichTextSpan(
          text: 'parts',
          style: FeedAnnouncementTextStyle(
            weight: FeedAnnouncementTextWeight.bold,
          ),
        ),
      ],
    );
    final draft = const FeedAnnouncementDraft(
      title: 'Whitespace',
      color: '#1ee3b6',
      sections: [section],
    );

    final json = draft.toJson();
    final hydrated = FeedAnnouncementDraft.fromJson(json);
    final hydratedSection =
        hydrated.sections.single as FeedAnnouncementRichTextSection;

    expect(
      richTextPlainText(hydratedSection.spans),
      'Highlight important parts',
    );
    expect(json['sections'], [
      {
        'type': 'richText',
        'spans': [
          {'text': 'Highlight'},
          {'text': ' '},
          {
            'text': 'important',
            'style': {'color': '#ff005b'},
          },
          {'text': ' '},
          {
            'text': 'parts',
            'style': {'weight': 'bold'},
          },
        ],
      },
    ]);
  });

  test('rich text edits preserve existing styled ranges', () {
    final controller = AnnouncementFeedBuilderController();
    addTearDown(controller.dispose);

    controller.titleController.text = 'Rich text';
    controller.addRichTextSection('Important notice');
    controller.applyRichTextSelectionStyle(
      sectionIndex: 0,
      selection: const TextSelection(baseOffset: 0, extentOffset: 9),
      style: const FeedAnnouncementTextStyle(
        weight: FeedAnnouncementTextWeight.bold,
        color: '#ff005b',
      ),
    );

    controller.updateRichTextContent(
      sectionIndex: 0,
      text: 'Important notice today',
    );

    var section =
        controller.draft.sections.single as FeedAnnouncementRichTextSection;
    expect(section.spans[0].text, 'Important');
    expect(section.spans[0].style?.weight, FeedAnnouncementTextWeight.bold);
    expect(section.spans[0].style?.color, '#ff005b');
    expect(richTextPlainText(section.spans), 'Important notice today');

    controller.updateRichTextContent(
      sectionIndex: 0,
      text: 'Very Important notice today',
    );

    section =
        controller.draft.sections.single as FeedAnnouncementRichTextSection;
    expect(richTextPlainText(section.spans), 'Very Important notice today');
    expect(
      section.spans.any(
        (span) =>
            span.text.contains('Important') &&
            span.style?.weight == FeedAnnouncementTextWeight.bold &&
            span.style?.color == '#ff005b',
      ),
      isTrue,
    );
  });

  test('rich text blocks hydrate structured backend spans', () {
    final section = FeedAnnouncementSectionFromJson.fromJson({
      'type': 'richText',
      'spans': [
        {
          'text': 'Styled',
          'style': {'color': '#22c55e', 'weight': 'semibold'},
        },
        {'text': ' text'},
      ],
    });

    expect(section, isA<FeedAnnouncementRichTextSection>());
    final richText = section! as FeedAnnouncementRichTextSection;
    expect(richText.spans, hasLength(2));
    expect(richText.spans.first.text, 'Styled');
    expect(richText.spans.first.style?.color, '#22c55e');
    expect(
      richText.spans.first.style?.weight,
      FeedAnnouncementTextWeight.semibold,
    );
    expect(richText.toJson(), {
      'type': 'richText',
      'spans': [
        {
          'text': 'Styled',
          'style': {'color': '#22c55e', 'weight': 'semibold'},
        },
        {'text': ' text'},
      ],
    });
  });

  test('video blocks hydrate legacy youtube type aliases', () {
    final section = FeedAnnouncementSectionFromJson.fromJson({
      'type': 'youtube',
      'url': 'https://www.youtube.com/watch?v=k1_ODDevbY8',
      'videoId': 'k1_ODDevbY8',
    });

    expect(section, isA<FeedAnnouncementYouTubeSection>());
    final json = section!.toJson();
    expect(json['type'], 'video');
    expect(json['videoId'], 'k1_ODDevbY8');
  });

  test('builder controller emits explicit title summary and footer styles', () {
    final controller = AnnouncementFeedBuilderController();
    addTearDown(controller.dispose);

    controller.titleController.text = 'Styled announcement';
    controller.descriptionController.text = 'Summary copy';
    controller.footerController.text = 'Release team';
    controller.setTitleStyle(
      const FeedAnnouncementTextStyle(
        color: '#ff5500',
        fontSize: 17.5,
        weight: FeedAnnouncementTextWeight.bold,
        italic: true,
      ),
    );
    controller.setDescriptionStyle(
      const FeedAnnouncementTextStyle(
        fontSize: 13,
        weight: FeedAnnouncementTextWeight.medium,
      ),
    );
    controller.setFooterStyle(
      const FeedAnnouncementTextStyle(
        color: '#7c3aed',
        fontSize: 11,
        weight: FeedAnnouncementTextWeight.bold,
        strikethrough: true,
      ),
    );

    final json = controller.draft.toJson();

    expect(json['titleStyle'], {
      'color': '#ff5500',
      'fontSize': 17.5,
      'weight': 'bold',
      'italic': true,
    });
    expect(json['descriptionStyle'], {'fontSize': 13.0, 'weight': 'medium'});
    expect(json['footerStyle'], {
      'color': '#7c3aed',
      'fontSize': 11.0,
      'weight': 'bold',
      'strikethrough': true,
    });

    final restored = FeedAnnouncementDraft.fromJson(json);
    expect(restored.titleStyle?.color, '#ff5500');
    expect(restored.titleStyle?.fontSize, 17.5);
    expect(restored.titleStyle?.weight, FeedAnnouncementTextWeight.bold);
    expect(restored.titleStyle?.italic, isTrue);
    expect(restored.descriptionStyle?.fontSize, 13);
    expect(restored.footerStyle?.weight, FeedAnnouncementTextWeight.bold);
    expect(restored.footerStyle?.strikethrough, isTrue);
  });

  test('chart editor supports explicit chart kinds', () {
    final controller = AnnouncementFeedBuilderController();
    addTearDown(controller.dispose);

    controller.titleController.text = 'Analytics';
    controller.addChartSection('type: line\ntitle: Trend\nMon: 4\nTue: 8');
    controller.addChartSection(
      'type: donut\ntitle: Reader split\nDesktop: 58\nMobile: 24',
    );
    controller.addChartSection(
      'type: metrics\ntitle: KPIs\nViews: 1240\nReports: 0',
    );
    controller.addChartSection(
      'type: progress\ntitle: Checklist\nDesign: 80\nBackend: 45',
    );
    controller.addChartSection(
      'type: sparkline\ntitle: Latency\nMon: 42\nTue: 36\nWed: 31',
    );

    final json = controller.draft.toJson();

    expect(json['sections'], [
      {
        'type': 'chart',
        'kind': 'line',
        'points': [
          {'label': 'Mon', 'value': 4.0},
          {'label': 'Tue', 'value': 8.0},
        ],
        'title': 'Trend',
      },
      {
        'type': 'chart',
        'kind': 'donut',
        'points': [
          {'label': 'Desktop', 'value': 58.0},
          {'label': 'Mobile', 'value': 24.0},
        ],
        'title': 'Reader split',
      },
      {
        'type': 'chart',
        'kind': 'metrics',
        'points': [
          {'label': 'Views', 'value': 1240.0},
          {'label': 'Reports', 'value': 0.0},
        ],
        'title': 'KPIs',
      },
      {
        'type': 'chart',
        'kind': 'progress',
        'points': [
          {'label': 'Design', 'value': 80.0},
          {'label': 'Backend', 'value': 45.0},
        ],
        'title': 'Checklist',
      },
      {
        'type': 'chart',
        'kind': 'sparkline',
        'points': [
          {'label': 'Mon', 'value': 42.0},
          {'label': 'Tue', 'value': 36.0},
          {'label': 'Wed', 'value': 31.0},
        ],
        'title': 'Latency',
      },
    ]);
  });

  test('youtube blocks accept only validated youtube video routes', () {
    expect(
      extractYouTubeVideoId('https://www.youtube.com/watch?v=k1_ODDevbY8'),
      'k1_ODDevbY8',
    );
    expect(
      extractYouTubeVideoId('https://youtu.be/k1_ODDevbY8?t=12'),
      'k1_ODDevbY8',
    );
    expect(
      extractYouTubeVideoId('https://www.youtube.com/embed/k1_ODDevbY8'),
      'k1_ODDevbY8',
    );
    expect(
      extractYouTubeVideoId('https://www.youtube.com/shorts/k1_ODDevbY8'),
      'k1_ODDevbY8',
    );
    expect(
      extractYouTubeVideoId('https://www.youtube.com/live/k1_ODDevbY8'),
      'k1_ODDevbY8',
    );
    expect(extractYouTubeVideoId('https://example.com/k1_ODDevbY8'), isNull);
    expect(
      extractYouTubeVideoId(
        'https://www.youtube.com/watch?v=<script>alert(1)</script>',
      ),
      isNull,
    );
  });
}
