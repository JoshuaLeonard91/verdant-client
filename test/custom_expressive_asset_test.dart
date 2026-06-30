import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/server_custom_emojis.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/shared/custom_expressive_asset.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';

void main() {
  test('custom expression helpers share emoji and sticker constraints', () {
    expect(
      customExpressionMaxBytes(CustomExpressiveAssetKind.emoji),
      customEmojiMaxBytes,
    );
    expect(
      customExpressionMaxBytes(CustomExpressiveAssetKind.sticker),
      customStickerMaxBytes,
    );

    expect(normalizeCustomEmojiName(':wave:'), 'wave');
    expect(normalizeCustomStickerName(':party_sticker:'), 'party_sticker');
    expect(validateCustomEmojiName('wave_2'), isNull);
    expect(validateCustomStickerName('party_sticker'), isNull);
    expect(validateCustomStickerName(''), 'Sticker name is required.');
    expect(
      validateCustomExpressionName(
        kind: CustomExpressiveAssetKind.emoji,
        value: 'no spaces',
      ),
      'Use 2-32 letters, numbers, or underscores.',
    );
  });

  test('custom expression image validation is shared across asset kinds', () {
    expect(isCustomExpressionImageFileName('emoji.webp'), isTrue);
    expect(isCustomExpressionImageFileName('sticker.gif'), isTrue);
    expect(isCustomExpressionImageFileName('notes.txt'), isFalse);
    expect(customExpressionFileExtension('Sticker.PNG'), 'png');
  });

  test('animated custom expression detection includes gif and webp urls', () {
    expect(
      isAnimatedCustomExpressionImageUrl('https://cdn.test/emojis/a.gif'),
      isTrue,
    );
    expect(
      isAnimatedCustomExpressionImageUrl(
        'https://cdn.test/emojis/catslam.webp?width=48',
      ),
      isTrue,
    );
    expect(
      isAnimatedCustomExpressionImageUrl('https://cdn.test/emojis/static.png'),
      isFalse,
    );
  });

  test('server custom emoji catalog drops malformed backend ids', () {
    final settings = WorkspaceSeed.sample.serverSettings.copyWith(
      emojis: const [
        ServerSettingsListItemSeed(
          id: 'bad/id/extra',
          title: ':bad:',
          subtitle: 'Created by test',
          trailing: 'Today',
          avatarUrl: 'https://cdn.pryzmapp.com/emojis/bad.webp',
        ),
        ServerSettingsListItemSeed(
          id: 'emoji-good',
          title: ':good:',
          subtitle: 'Created by test',
          trailing: 'Today',
          avatarUrl: 'https://cdn.pryzmapp.com/emojis/good.webp',
        ),
      ],
    );

    final emojis = serverCustomEmojisFromSettings(settings);

    expect(emojis.map((emoji) => emoji.name), ['good']);
  });

  test('server custom sticker catalog drops malformed backend ids', () {
    final settings = WorkspaceSeed.sample.serverSettings.copyWith(
      stickers: const [
        ServerSettingsListItemSeed(
          id: 'bad/id/extra',
          title: ':bad_sticker:',
          subtitle: 'Created by test',
          trailing: 'Today',
          avatarUrl: 'https://cdn.pryzmapp.com/stickers/bad.webp',
        ),
        ServerSettingsListItemSeed(
          id: 'sticker-good',
          title: ':good_sticker:',
          subtitle: 'Created by test',
          trailing: 'Today',
          avatarUrl: 'https://cdn.pryzmapp.com/stickers/good.webp',
        ),
      ],
    );

    final stickers = serverCustomStickersFromSettings(settings);
    final groups = serverCustomStickerGroupsFromSettings(settings);

    expect(stickers.map((sticker) => sticker.name), ['good_sticker']);
    expect(groups.single.stickers.single.name, 'good_sticker');
    expect(
      resolveServerCustomSticker(':good_sticker:', stickers)?.id,
      'sticker-good',
    );
  });
}
