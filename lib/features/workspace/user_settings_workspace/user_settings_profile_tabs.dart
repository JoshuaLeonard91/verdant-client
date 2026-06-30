part of 'user_settings_workspace.dart';

class _ProfileSettingsTab extends StatelessWidget {
  const _ProfileSettingsTab({
    required this.currentUser,
    required this.currentUserMedia,
    required this.mediaPolicy,
    required this.displayNameDraft,
    required this.bioDraft,
    required this.editingDisplayName,
    required this.editingBio,
    required this.busyAction,
    required this.profileFieldsError,
    required this.onDisplayNameChanged,
    required this.onBioChanged,
    required this.onEditDisplayName,
    required this.onCancelDisplayName,
    required this.onSaveDisplayName,
    required this.onEditBio,
    required this.onCancelBio,
    required this.onSaveBio,
    required this.identityCard,
    required this.memberListBannerCard,
  });

  final VerdantUser currentUser;
  final ServerSettingsCurrentUserMedia? currentUserMedia;
  final ServerMediaPolicy mediaPolicy;
  final String displayNameDraft;
  final String bioDraft;
  final bool editingDisplayName;
  final bool editingBio;
  final String? busyAction;
  final String? profileFieldsError;
  final ValueChanged<String> onDisplayNameChanged;
  final ValueChanged<String> onBioChanged;
  final VoidCallback onEditDisplayName;
  final VoidCallback onCancelDisplayName;
  final Future<void> Function() onSaveDisplayName;
  final VoidCallback onEditBio;
  final VoidCallback onCancelBio;
  final Future<void> Function() onSaveBio;
  final Widget identityCard;
  final Widget memberListBannerCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        identityCard,
        const SizedBox(height: 16),
        _ProfileDetailsCard(
          currentUser: currentUser,
          currentUserMedia: currentUserMedia,
          displayNameDraft: displayNameDraft,
          bioDraft: bioDraft,
          editingDisplayName: editingDisplayName,
          editingBio: editingBio,
          busyAction: busyAction,
          error: profileFieldsError,
          onDisplayNameChanged: onDisplayNameChanged,
          onBioChanged: onBioChanged,
          onEditDisplayName: onEditDisplayName,
          onCancelDisplayName: onCancelDisplayName,
          onSaveDisplayName: onSaveDisplayName,
          onEditBio: onEditBio,
          onCancelBio: onCancelBio,
          onSaveBio: onSaveBio,
        ),
        const SizedBox(height: 18),
        memberListBannerCard,
      ],
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.currentUser,
    required this.currentUserMedia,
    required this.mediaPolicy,
    required this.enabled,
    required this.canManage,
    required this.animatedAvatarEnabled,
    required this.animatedBannerEnabled,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.bannerBaseColor,
    required this.bannerCrop,
    required this.busyAction,
    required this.error,
    required this.onSelectAvatar,
    required this.onRemoveAvatar,
    required this.onSelectBanner,
    required this.onBannerBaseColorChanged,
    required this.onPositionBanner,
    required this.onRemoveBanner,
  });

  final VerdantUser currentUser;
  final ServerSettingsCurrentUserMedia? currentUserMedia;
  final ServerMediaPolicy mediaPolicy;
  final bool enabled;
  final bool canManage;
  final bool animatedAvatarEnabled;
  final bool animatedBannerEnabled;
  final String? avatarUrl;
  final String? bannerUrl;
  final Color? bannerBaseColor;
  final BannerCrop? bannerCrop;
  final String? busyAction;
  final String? error;
  final VoidCallback onSelectAvatar;
  final VoidCallback onRemoveAvatar;
  final VoidCallback onSelectBanner;
  final ValueChanged<Color> onBannerBaseColorChanged;
  final VoidCallback onPositionBanner;
  final VoidCallback onRemoveBanner;

  bool get _hasAvatar => avatarUrl != null;

  bool get _hasBanner => bannerUrl != null;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final bannerUri = safeServerMediaUri(bannerUrl, policy: mediaPolicy);
    final username = currentUserMedia?.username ?? currentUser.username;
    final displayName =
        currentUserMedia?.displayName ?? currentUser.displayLabel;
    final fallbackColor =
        bannerBaseColor ?? _profileVisualColorFor(displayName);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: ClipRRect(
        borderRadius: VerdantRadii.sharp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: const ValueKey('profile-banner-preview'),
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerUri == null)
                    _ProfileBannerFallback(color: fallbackColor)
                  else
                    SafeServerMediaImage(
                      uri: bannerUri,
                      policy: mediaPolicy,
                      surface: ServerMediaSurface.serverBanner,
                      retainWhenUnfocused: true,
                      fallback: _ProfileBannerFallback(color: fallbackColor),
                      builder: (context, imageProvider) {
                        return CroppedServerBannerImage(
                          imageProvider: imageProvider,
                          crop: bannerCrop,
                        );
                      },
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xCC000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey(
                          'profile-identity-banner-upload-target',
                        ),
                        onTap: canManage
                            ? (_hasBanner ? onPositionBanner : onSelectBanner)
                            : null,
                        hoverColor: colors.actionMuted.withValues(alpha: 0.38),
                        splashColor: colors.actionMuted.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                  if (busyAction == 'profile-banner-upload' ||
                      busyAction == 'profile-banner-position')
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x99000000),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -24),
                        child: SizedBox(
                          key: const ValueKey('profile-avatar-preview'),
                          width: 76,
                          height: 76,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ServerMediaIcon(
                                name: displayName,
                                iconUrl: avatarUrl,
                                mediaPolicy: mediaPolicy,
                                size: 76,
                                showBorder: true,
                                animate: false,
                              ),
                              ClipRRect(
                                borderRadius: VerdantRadii.sharp,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: const ValueKey(
                                      'profile-identity-avatar-upload-target',
                                    ),
                                    onTap: canManage ? onSelectAvatar : null,
                                    hoverColor: colors.actionMuted.withValues(
                                      alpha: 0.38,
                                    ),
                                    splashColor: colors.actionMuted.withValues(
                                      alpha: 0.24,
                                    ),
                                  ),
                                ),
                              ),
                              if (busyAction == 'avatar-upload' ||
                                  busyAction == 'avatar-remove')
                                const ColoredBox(
                                  color: Color(0x99000000),
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@$username',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!enabled) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Image uploads are disabled on this network.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFFFC15E),
                        fontWeight: VerdantFontWeights.bold,
                      ),
                    ),
                  ],
                  if (!_hasBanner) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Banner Base Color',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: VerdantFontWeights.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final color in _profileBannerBaseColorOptions)
                          _ProfileBannerBaseColorSwatch(
                            color: color,
                            selected:
                                fallbackColor.toARGB32() == color.toARGB32(),
                            onPressed: () => onBannerBaseColorChanged(color),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Used locally when you do not have an uploaded profile banner.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (!animatedAvatarEnabled || !animatedBannerEnabled) ...[
                    const SizedBox(height: 10),
                    Text(
                      [
                        if (!animatedAvatarEnabled) 'Animated avatars disabled',
                        if (!animatedBannerEnabled) 'Animated banners disabled',
                      ].join(' - '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    _SettingsError(message: error!),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SmallSettingsButton(
                        key: const ValueKey('profile-banner-replace-button'),
                        label: _hasBanner
                            ? 'Replace Profile Banner'
                            : 'Add Profile Banner',
                        icon: Icons.upload_outlined,
                        busy: busyAction == 'profile-banner-upload',
                        onPressed: canManage ? onSelectBanner : null,
                      ),
                      _SmallSettingsButton(
                        key: const ValueKey('profile-banner-position-button'),
                        label: 'Position Banner',
                        icon: Icons.open_with,
                        busy: busyAction == 'profile-banner-position',
                        onPressed: canManage && _hasBanner
                            ? onPositionBanner
                            : null,
                      ),
                      if (_hasBanner)
                        _SmallSettingsButton(
                          key: const ValueKey('profile-banner-remove-button'),
                          label: 'Remove Banner',
                          icon: Icons.delete_outline,
                          busy: busyAction == 'profile-banner-remove',
                          onPressed: canManage ? onRemoveBanner : null,
                        ),
                      if (_hasAvatar)
                        _SmallSettingsButton(
                          key: const ValueKey('profile-avatar-remove-button'),
                          label: 'Remove Avatar',
                          icon: Icons.delete_outline,
                          busy: busyAction == 'avatar-remove',
                          onPressed: canManage ? onRemoveAvatar : null,
                        ),
                    ],
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

class _ProfileBannerBaseColorSwatch extends StatelessWidget {
  const _ProfileBannerBaseColorSwatch({
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final value = color.toARGB32().toRadixString(16);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Profile banner base color option',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('profile-banner-base-color-swatch-$value'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.text : colors.border,
                width: selected ? 2.2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: selected ? 0.34 : 0.18),
                  blurRadius: selected ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.currentUser,
    required this.currentUserMedia,
    required this.displayNameDraft,
    required this.bioDraft,
    required this.editingDisplayName,
    required this.editingBio,
    required this.busyAction,
    required this.error,
    required this.onDisplayNameChanged,
    required this.onBioChanged,
    required this.onEditDisplayName,
    required this.onCancelDisplayName,
    required this.onSaveDisplayName,
    required this.onEditBio,
    required this.onCancelBio,
    required this.onSaveBio,
  });

  final VerdantUser currentUser;
  final ServerSettingsCurrentUserMedia? currentUserMedia;
  final String displayNameDraft;
  final String bioDraft;
  final bool editingDisplayName;
  final bool editingBio;
  final String? busyAction;
  final String? error;
  final ValueChanged<String> onDisplayNameChanged;
  final ValueChanged<String> onBioChanged;
  final VoidCallback onEditDisplayName;
  final VoidCallback onCancelDisplayName;
  final Future<void> Function() onSaveDisplayName;
  final VoidCallback onEditBio;
  final VoidCallback onCancelBio;
  final Future<void> Function() onSaveBio;

  @override
  Widget build(BuildContext context) {
    final username = currentUserMedia?.username ?? currentUser.username;
    final displayName =
        currentUserMedia?.displayName ?? currentUser.displayName;
    final bio = currentUserMedia?.bio ?? currentUser.bio;
    return _SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadOnlySettingsRow(
            label: 'Username',
            value: '@$username',
            trailing: 'Permanent',
          ),
          const _SettingsDivider(),
          if (editingDisplayName)
            _EditableTextSetting(
              label: 'Display Name',
              value: displayNameDraft,
              maxLength: 64,
              minLines: 1,
              maxLines: 1,
              busy: busyAction == 'display-name-save',
              saveLabel: 'Save',
              onChanged: onDisplayNameChanged,
              onCancel: onCancelDisplayName,
              onSave: onSaveDisplayName,
            )
          else
            _ActionSettingsRow(
              label: 'Display Name',
              value: displayName?.trim().isNotEmpty == true
                  ? displayName!
                  : 'Not set',
              onPressed: onEditDisplayName,
            ),
          const _SettingsDivider(),
          if (editingBio)
            _EditableTextSetting(
              label: 'Profile Description',
              value: bioDraft,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              busy: busyAction == 'bio-save',
              saveLabel: 'Save',
              onChanged: onBioChanged,
              onCancel: onCancelBio,
              onSave: onSaveBio,
            )
          else
            _ActionSettingsRow(
              label: 'Profile Description',
              value: bio?.trim().isNotEmpty == true
                  ? bio!.trim()
                  : 'No description set',
              onPressed: onEditBio,
              multiLine: true,
            ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _SettingsError(message: error!),
          ],
        ],
      ),
    );
  }
}

class _AccountSettingsTab extends StatelessWidget {
  const _AccountSettingsTab({
    required this.currentUser,
    required this.currentEmail,
    required this.newEmail,
    required this.emailPassword,
    required this.emailCode,
    required this.changingEmail,
    required this.confirmingEmail,
    required this.emailHas2fa,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.changingPassword,
    required this.showCurrentPassword,
    required this.showNewPassword,
    required this.busyAction,
    required this.error,
    required this.success,
    required this.onCurrentEmailChanged,
    required this.onNewEmailChanged,
    required this.onEmailPasswordChanged,
    required this.onEmailCodeChanged,
    required this.onBeginEmailChange,
    required this.onCancelEmailChange,
    required this.onStartEmailChange,
    required this.onConfirmEmailChange,
    required this.onCurrentPasswordChanged,
    required this.onNewPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onBeginPasswordChange,
    required this.onCancelPasswordChange,
    required this.onChangePassword,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
  });

  final VerdantUser currentUser;
  final String currentEmail;
  final String newEmail;
  final String emailPassword;
  final String emailCode;
  final bool changingEmail;
  final bool confirmingEmail;
  final bool emailHas2fa;
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final bool changingPassword;
  final bool showCurrentPassword;
  final bool showNewPassword;
  final String? busyAction;
  final String? error;
  final String? success;
  final ValueChanged<String> onCurrentEmailChanged;
  final ValueChanged<String> onNewEmailChanged;
  final ValueChanged<String> onEmailPasswordChanged;
  final ValueChanged<String> onEmailCodeChanged;
  final VoidCallback onBeginEmailChange;
  final VoidCallback onCancelEmailChange;
  final Future<void> Function() onStartEmailChange;
  final Future<void> Function() onConfirmEmailChange;
  final ValueChanged<String> onCurrentPasswordChanged;
  final ValueChanged<String> onNewPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final VoidCallback onBeginPasswordChange;
  final VoidCallback onCancelPasswordChange;
  final Future<void> Function() onChangePassword;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;

  @override
  Widget build(BuildContext context) {
    final emailBusy =
        busyAction == 'email-change-start' ||
        busyAction == 'email-change-confirm';
    final passwordBusy = busyAction == 'password-change';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Account Access', trailing: 'Private'),
        const SizedBox(height: 10),
        _SettingsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (changingEmail)
                _EmailChangeForm(
                  currentEmail: currentEmail,
                  newEmail: newEmail,
                  password: emailPassword,
                  code: emailCode,
                  confirming: confirmingEmail,
                  has2fa: emailHas2fa,
                  busy: emailBusy,
                  onCurrentEmailChanged: onCurrentEmailChanged,
                  onNewEmailChanged: onNewEmailChanged,
                  onPasswordChanged: onEmailPasswordChanged,
                  onCodeChanged: onEmailCodeChanged,
                  onCancel: onCancelEmailChange,
                  onStart: onStartEmailChange,
                  onConfirm: onConfirmEmailChange,
                )
              else
                _ActionSettingsRow(
                  label: 'Email',
                  value: _maskedEmail(currentUser.email),
                  onPressed: onBeginEmailChange,
                  actionLabel: 'Edit',
                ),
              const _SettingsDivider(),
              if (changingPassword)
                _PasswordChangeForm(
                  currentPassword: currentPassword,
                  newPassword: newPassword,
                  confirmPassword: confirmPassword,
                  showCurrentPassword: showCurrentPassword,
                  showNewPassword: showNewPassword,
                  busy: passwordBusy,
                  onCurrentPasswordChanged: onCurrentPasswordChanged,
                  onNewPasswordChanged: onNewPasswordChanged,
                  onConfirmPasswordChanged: onConfirmPasswordChanged,
                  onToggleCurrentPassword: onToggleCurrentPassword,
                  onToggleNewPassword: onToggleNewPassword,
                  onCancel: onCancelPasswordChange,
                  onChangePassword: onChangePassword,
                )
              else
                _ActionSettingsRow(
                  label: 'Password',
                  value: '**********',
                  onPressed: onBeginPasswordChange,
                  actionLabel: 'Change',
                ),
              if (error != null) ...[
                const SizedBox(height: 12),
                _SettingsError(message: error!),
              ],
              if (success != null) ...[
                const SizedBox(height: 12),
                _SettingsSuccess(message: success!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
