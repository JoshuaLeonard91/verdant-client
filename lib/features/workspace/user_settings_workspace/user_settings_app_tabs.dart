part of 'user_settings_workspace.dart';

class _GeneralSettingsTab extends StatelessWidget {
  const _GeneralSettingsTab({
    required this.preferences,
    required this.onChanged,
  });

  final UserSettingsPreferences preferences;
  final ValueChanged<UserSettingsPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Window Behavior', trailing: 'Local'),
        const SizedBox(height: 10),
        _SettingsPanel(
          child: _SettingsSwitchRow(
            key: const ValueKey('user-settings-close-to-tray-switch'),
            icon: Icons.move_to_inbox_outlined,
            label: 'Minimize to tray on close',
            detail:
                'Keep Verdant running in the tray when the main window closes.',
            value: preferences.closeToTray,
            onChanged: (value) {
              onChanged(preferences.copyWith(closeToTray: value));
            },
          ),
        ),
      ],
    );
  }
}

class _AppearanceSettingsTab extends StatelessWidget {
  const _AppearanceSettingsTab({
    required this.preferences,
    required this.onChanged,
  });

  final UserSettingsPreferences preferences;
  final ValueChanged<UserSettingsPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsSectionLabel(title: 'Appearance'),
        const SizedBox(height: 16),
        _AppearancePreferenceHeader(
          icon: Icons.palette_outlined,
          label: 'Theme',
          detail: 'Adjust the workspace palette used by settings and panels.',
          value: preferences.theme.label,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in UserSettingsThemePreference.values)
              _SettingsOptionButton(
                key: ValueKey('user-settings-theme-${option.value}'),
                label: option.label,
                selected: preferences.theme == option,
                onPressed: () {
                  onChanged(preferences.copyWith(theme: option));
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        _AppearancePreview(preferences: preferences),
        const _SettingsDivider(),
        _AppearancePreferenceHeader(
          icon: Icons.view_agenda_outlined,
          label: 'Interface Density',
          detail: 'Choose how tightly workspace controls are packed.',
          value: preferences.density.label,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in UserSettingsDensityPreference.values)
              _SettingsOptionButton(
                key: ValueKey('user-settings-density-${option.value}'),
                label: option.label,
                selected: preferences.density == option,
                onPressed: () {
                  onChanged(preferences.copyWith(density: option));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _AppearancePreferenceHeader extends StatelessWidget {
  const _AppearancePreferenceHeader({
    required this.icon,
    required this.label,
    required this.detail,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.accentStrong),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.actionMuted,
            border: Border.all(color: colors.accent),
            borderRadius: VerdantRadii.sharp,
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.accentStrong,
              fontWeight: VerdantFontWeights.semibold,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview({required this.preferences});

  final UserSettingsPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final theme = preferences.theme;
    final colors = switch (theme) {
      UserSettingsThemePreference.light => (
        key: const ValueKey('user-settings-appearance-preview-light'),
        background: VerdantThemeColors.light.background,
        panel: VerdantThemeColors.light.panelRaised,
        text: VerdantThemeColors.light.text,
        muted: VerdantThemeColors.light.textMuted,
      ),
      UserSettingsThemePreference.dark => (
        key: const ValueKey('user-settings-appearance-preview-dark'),
        background: VerdantThemeColors.dark.background,
        panel: VerdantThemeColors.dark.panelRaised,
        text: VerdantThemeColors.dark.text,
        muted: VerdantThemeColors.dark.textMuted,
      ),
    };
    final activeColors = VerdantThemeColors.of(context);
    return DecoratedBox(
      key: colors.key,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: activeColors.borderStrong),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width:
                  preferences.density == UserSettingsDensityPreference.compact
                  ? 38
                  : 46,
              height:
                  preferences.density == UserSettingsDensityPreference.compact
                  ? 38
                  : 46,
              decoration: BoxDecoration(
                color: colors.panel,
                border: Border.all(color: activeColors.accent),
                borderRadius: VerdantRadii.sharp,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: activeColors.accentStrong,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${theme.label} theme',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${preferences.density.label} interface density',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SettingsSelectOption {
  const _SettingsSelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

const _voiceInputDeviceOptions = [
  _SettingsSelectOption(value: '', label: 'Default'),
  _SettingsSelectOption(
    value: 'communications-input',
    label: 'Communications Microphone',
  ),
  _SettingsSelectOption(value: 'system-input', label: 'System Microphone'),
];

const _voiceOutputDeviceOptions = [
  _SettingsSelectOption(value: '', label: 'Default'),
  _SettingsSelectOption(
    value: 'communications-output',
    label: 'Communications Speakers',
  ),
  _SettingsSelectOption(value: 'system-output', label: 'System Speakers'),
];

String _validVoiceInputDeviceId(String value) {
  return _voiceInputDeviceOptions.any((option) => option.value == value)
      ? value
      : '';
}

String _validVoiceOutputDeviceId(String value) {
  return _voiceOutputDeviceOptions.any((option) => option.value == value)
      ? value
      : '';
}

class _VoiceAudioSettingsTab extends StatelessWidget {
  const _VoiceAudioSettingsTab({
    required this.preferences,
    required this.onChanged,
  });

  final UserSettingsPreferences preferences;
  final ValueChanged<UserSettingsPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final typography = VerdantThemeTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Voice & Audio', trailing: 'Local'),
        const SizedBox(height: 10),
        _SettingsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingsSelectRow(
                key: const ValueKey('user-settings-input-device-select'),
                label: 'Input Device',
                value: _validVoiceInputDeviceId(preferences.voiceInputDeviceId),
                options: _voiceInputDeviceOptions,
                onChanged: (value) {
                  onChanged(preferences.copyWith(voiceInputDeviceId: value));
                },
              ),
              const _SettingsDivider(),
              _SettingsSelectRow(
                key: const ValueKey('user-settings-output-device-select'),
                label: 'Output Device',
                value: _validVoiceOutputDeviceId(
                  preferences.voiceOutputDeviceId,
                ),
                options: _voiceOutputDeviceOptions,
                onChanged: (value) {
                  onChanged(preferences.copyWith(voiceOutputDeviceId: value));
                },
              ),
              const _SettingsDivider(),
              Text('Input Volume', style: typography.settingsSectionLabel),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      key: const ValueKey('user-settings-voice-volume'),
                      value: preferences.voiceInputVolume.toDouble(),
                      min: 0,
                      max: 200,
                      divisions: 20,
                      label: '${preferences.voiceInputVolume}%',
                      onChanged: (value) {
                        onChanged(
                          preferences.copyWith(voiceInputVolume: value.round()),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      '${preferences.voiceInputVolume}%',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const _SettingsDivider(),
              _SettingsSwitchRow(
                key: const ValueKey('user-settings-push-to-talk-switch'),
                icon: Icons.keyboard_outlined,
                label: 'Push to Talk',
                detail:
                    'Require a key press before transmitting voice in channels.',
                value: preferences.pushToTalk,
                onChanged: (value) {
                  onChanged(preferences.copyWith(pushToTalk: value));
                },
              ),
              if (preferences.pushToTalk) ...[
                const SizedBox(height: 12),
                _ReadOnlySettingsRow(
                  label: 'Push-to-talk key',
                  value: preferences.pushToTalkKey,
                ),
              ],
              const _SettingsDivider(),
              _SettingsSwitchRow(
                icon: Icons.noise_control_off_outlined,
                label: 'Noise Suppression',
                detail: 'Reduce background noise from your microphone.',
                value: preferences.noiseSuppression,
                onChanged: (value) {
                  onChanged(preferences.copyWith(noiseSuppression: value));
                },
              ),
              const _SettingsDivider(),
              _SettingsSwitchRow(
                icon: Icons.speaker_notes_off_outlined,
                label: 'Echo Cancellation',
                detail: 'Reduce speaker feedback while voice chat is active.',
                value: preferences.echoCancellation,
                onChanged: (value) {
                  onChanged(preferences.copyWith(echoCancellation: value));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationsSettingsTab extends StatelessWidget {
  const _NotificationsSettingsTab({
    required this.controller,
    required this.preferences,
    required this.soundPreviewBusy,
    required this.soundPreviewError,
    required this.onChanged,
    required this.onPlayNotificationSound,
  });

  final UserSettingsNotificationsController controller;
  final UserSettingsPreferences preferences;
  final bool soundPreviewBusy;
  final String? soundPreviewError;
  final ValueChanged<UserSettingsPreferences> onChanged;
  final Future<void> Function() onPlayNotificationSound;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final globalPreference = controller.globalPreference;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Notifications',
              trailing: controller.loading
                  ? 'Loading'
                  : controller.saving
                  ? 'Saving'
                  : null,
            ),
            const SizedBox(height: 10),
            if (controller.error != null) ...[
              _SettingsError(message: controller.error!),
              const SizedBox(height: 10),
            ],
            _SettingsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsSwitchRow(
                    key: const ValueKey('user-settings-mute-network'),
                    icon: Icons.notifications_off_outlined,
                    label: 'Mute this network',
                    detail:
                        'Stop notification delivery for this account on the selected backend.',
                    value: globalPreference.muted,
                    onChanged: (value) {
                      controller.updateGlobalPreference(muted: value);
                    },
                  ),
                  const _SettingsDivider(),
                  _SettingsSwitchRow(
                    key: const ValueKey('user-settings-desktop-notifications'),
                    icon: Icons.notifications_outlined,
                    label: 'Desktop Notifications',
                    detail:
                        'Allow the selected backend to send notification-worthy activity to this client.',
                    value: globalPreference.desktopEnabled,
                    onChanged: (value) {
                      controller.updateGlobalPreference(desktopEnabled: value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsSwitchRow(
                    key: const ValueKey('user-settings-notification-sounds'),
                    icon: Icons.volume_up_outlined,
                    label: 'Notification Sound',
                    detail:
                        'Play a local sound for notification-worthy events on this device.',
                    value: preferences.notificationSounds,
                    onChanged: (value) {
                      onChanged(
                        preferences.copyWith(notificationSounds: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SmallSettingsButton(
                    key: const ValueKey(
                      'user-settings-play-notification-sound',
                    ),
                    label: 'Play sound',
                    icon: Icons.play_arrow_rounded,
                    busy: soundPreviewBusy,
                    onPressed: soundPreviewBusy
                        ? null
                        : () {
                            onPlayNotificationSound();
                          },
                  ),
                  if (soundPreviewError != null) ...[
                    const SizedBox(height: 12),
                    _SettingsError(message: soundPreviewError!),
                  ],
                  const SizedBox(height: 12),
                  const _SettingsInfoBanner(
                    message:
                        'Notification delivery settings are saved on the selected backend. Sound playback is local to this device.',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AboutSettingsTab extends StatelessWidget {
  const _AboutSettingsTab({required this.mediaPolicy});

  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'About', trailing: 'Flutter'),
        const SizedBox(height: 10),
        _SettingsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verdant', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Flutter desktop experiment. Tauri remains the behavior reference while this settings surface is ported.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const _SettingsDivider(),
              _ReadOnlySettingsRow(
                label: 'API Origin',
                value: mediaPolicy.apiOrigin ?? 'Unknown',
              ),
              const _SettingsDivider(),
              _ReadOnlySettingsRow(label: 'Client', value: 'Flutter desktop'),
            ],
          ),
        ),
      ],
    );
  }
}
