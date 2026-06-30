import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import '../../auth/auth_models.dart';
import '../bottom_rail_workspace/bottom_rail_models.dart';
import '../server_settings_workspace/banner_crop_dialog.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_loader.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../server_settings_workspace/server_settings_service.dart';
import '../shared/workspace_entitlements.dart';
import '../workspace_local_id.dart';
import 'user_settings_context.dart';
import 'user_settings_notification_sound.dart';
import 'user_settings_notifications.dart';
import 'user_settings_preferences.dart';
import 'user_settings_sessions.dart';
import 'workspace_accessibility_settings.dart';
part 'user_settings_navigation.dart';
part 'user_settings_accessibility_tab.dart';
part 'user_settings_security_tabs.dart';
part 'user_settings_network_tabs.dart';
part 'user_settings_app_tabs.dart';
part 'user_settings_profile_tabs.dart';
part 'user_settings_shared_widgets.dart';

const double _memberListBannerAspectRatio = 6.2;
const double _profileBannerAspectRatio = 3.1;
const _profileBannerBaseColorOptions = [
  Color(0xFF2EC4B6),
  Color(0xFF7C5CFF),
  Color(0xFFE94560),
  Color(0xFFFF8A3D),
  Color(0xFF3498DB),
  Color(0xFF43B581),
  Color(0xFFB980FF),
  Color(0xFFFAA61A),
];

enum _TwoFactorSettingsStep {
  status,
  password,
  qr,
  verify,
  backupCodes,
  disable,
  regenerate,
}

final _imageTypeGroup = XTypeGroup(
  label: 'Images',
  extensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
  mimeTypes: const ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
);

enum _UserSettingsGroup { account, app, product }

enum _UserSettingsCategory {
  profile(
    key: 'profile',
    label: 'Profile',
    icon: Icons.person_outline,
    title: 'Profile',
    group: _UserSettingsGroup.account,
  ),
  account(
    key: 'account',
    label: 'Account',
    icon: Icons.account_circle_outlined,
    title: 'Account',
    group: _UserSettingsGroup.account,
  ),
  security(
    key: 'security',
    label: 'Security',
    icon: Icons.security_outlined,
    title: 'Security',
    group: _UserSettingsGroup.account,
  ),
  sessions(
    key: 'sessions',
    label: 'Sessions',
    icon: Icons.devices_outlined,
    title: 'Sessions',
    group: _UserSettingsGroup.account,
  ),
  network(
    key: 'network',
    label: 'Network',
    icon: Icons.public_outlined,
    title: 'Network',
    group: _UserSettingsGroup.app,
  ),
  general(
    key: 'general',
    label: 'General',
    icon: Icons.settings_outlined,
    title: 'General',
    group: _UserSettingsGroup.app,
  ),
  appearance(
    key: 'appearance',
    label: 'Appearance',
    icon: Icons.palette_outlined,
    title: 'Appearance',
    group: _UserSettingsGroup.app,
  ),
  accessibility(
    key: 'accessibility',
    label: 'Accessibility',
    icon: Icons.text_fields,
    title: 'Accessibility',
    group: _UserSettingsGroup.app,
  ),
  voice(
    key: 'voice',
    label: 'Voice & Audio',
    icon: Icons.mic_none_outlined,
    title: 'Voice & Audio',
    group: _UserSettingsGroup.app,
  ),
  notifications(
    key: 'notifications',
    label: 'Notifications',
    icon: Icons.notifications_none_outlined,
    title: 'Notifications',
    group: _UserSettingsGroup.app,
  ),
  about(
    key: 'about',
    label: 'About',
    icon: Icons.info_outline,
    title: 'About',
    group: _UserSettingsGroup.product,
  );

  const _UserSettingsCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.title,
    required this.group,
  });

  final String key;
  final String label;
  final IconData icon;
  final String title;
  final _UserSettingsGroup group;
}

class UserSettingsWorkspace extends StatefulWidget {
  const UserSettingsWorkspace({
    required this.currentUser,
    required this.currentUserMedia,
    required this.mediaPolicy,
    required this.entitlements,
    required this.repository,
    this.settingsContexts = const [],
    required this.accessibilitySettings,
    required this.preferencesStore,
    required this.networkRecords,
    required this.activeNetworkId,
    required this.homeNetworkId,
    required this.onPreferencesChanged,
    required this.onAccessibilityChanged,
    required this.onProfileUpdated,
    required this.onSetNetworkUsername,
    required this.onRetryNetwork,
    required this.onRemoveNetwork,
    required this.onClose,
    this.notificationSoundPreview =
        const SystemUserSettingsNotificationSoundPreview(),
    super.key,
  });

  final VerdantUser currentUser;
  final ServerSettingsCurrentUserMedia? currentUserMedia;
  final ServerMediaPolicy mediaPolicy;
  final WorkspaceEntitlements entitlements;
  final UserSettingsRepository? repository;
  final List<UserSettingsContext> settingsContexts;
  final WorkspaceAccessibilitySettings accessibilitySettings;
  final UserSettingsPreferencesStore preferencesStore;
  final List<RailNetworkRecord> networkRecords;
  final String activeNetworkId;
  final String homeNetworkId;
  final ValueChanged<UserSettingsPreferences> onPreferencesChanged;
  final ValueChanged<WorkspaceAccessibilitySettings> onAccessibilityChanged;
  final Future<void> Function() onProfileUpdated;
  final ValueChanged<RailNetworkRecord> onSetNetworkUsername;
  final ValueChanged<RailNetworkRecord> onRetryNetwork;
  final ValueChanged<RailNetworkRecord> onRemoveNetwork;
  final VoidCallback onClose;
  final UserSettingsNotificationSoundPreview notificationSoundPreview;

  @override
  State<UserSettingsWorkspace> createState() => _UserSettingsWorkspaceState();
}

class _UserSettingsWorkspaceState extends State<UserSettingsWorkspace> {
  final _mediaLoader = ServerMediaLoader();
  final _scrollController = ScrollController();
  late UserSettingsSessionsController _sessionsController;
  late UserSettingsNotificationsController _notificationsController;
  _UserSettingsCategory _activeCategory = _UserSettingsCategory.profile;
  String? _avatarUrl;
  String? _profileBannerUrl;
  Color? _profileBannerBaseColor;
  BannerCrop? _profileBannerCrop;
  String? _memberListBannerUrl;
  BannerCrop? _memberListBannerCrop;
  String? _busyAction;
  String? _profileError;
  String? _profileFieldsError;
  String? _accountError;
  String? _accountSuccess;
  String? _error;
  String? _notificationSoundPreviewError;
  UserSettingsPreferences _preferences = const UserSettingsPreferences();
  String _displayNameDraft = '';
  String _bioDraft = '';
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  String _currentEmail = '';
  String _newEmail = '';
  String _emailPassword = '';
  String _emailCode = '';
  String _twoFactorPassword = '';
  String _twoFactorCode = '';
  String _twoFactorDisablePassword = '';
  String _twoFactorDisableCode = '';
  String _twoFactorRegeneratePassword = '';
  String _twoFactorRegenerateCode = '';
  TwoFactorStatus? _twoFactorStatus;
  TwoFactorSetup? _twoFactorSetup;
  List<String> _twoFactorBackupCodes = const [];
  _TwoFactorSettingsStep _twoFactorStep = _TwoFactorSettingsStep.status;
  bool _editingDisplayName = false;
  bool _editingBio = false;
  bool _changingPassword = false;
  bool _changingEmail = false;
  bool _confirmingEmail = false;
  bool _emailHas2fa = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _twoFactorStatusLoaded = false;
  bool _notificationSoundPreviewBusy = false;
  String? _securityError;
  String? _securitySuccess;
  late String _selectedSettingsNetworkId;
  late String _selectedContextSignature;

  bool get _canManageProfileVisuals =>
      _settingsRepository != null &&
      _settingsEntitlements.imageUploads &&
      _busyAction == null;

  bool get _canManageMemberListBanner =>
      _settingsRepository != null &&
      _settingsEntitlements.memberListBanner &&
      _settingsEntitlements.imageUploads &&
      _busyAction == null;

  List<UserSettingsContext> get _settingsContexts {
    final fallback = _fallbackSettingsContext();
    final contextsByNetworkId = <String, UserSettingsContext>{
      fallback.networkId: fallback,
    };
    for (final context in widget.settingsContexts) {
      contextsByNetworkId[context.networkId] = context;
    }
    return contextsByNetworkId.values.toList(growable: false);
  }

  UserSettingsContext get _settingsContext {
    final contexts = _settingsContexts;
    for (final context in contexts) {
      if (context.networkId == _selectedSettingsNetworkId) {
        return context;
      }
    }
    for (final context in contexts) {
      if (context.networkId == widget.activeNetworkId) {
        return context;
      }
    }
    return contexts.first;
  }

  VerdantUser get _settingsUser => _settingsContext.currentUser;

  ServerSettingsCurrentUserMedia? get _settingsUserMedia =>
      _settingsContext.currentUserMedia;

  ServerMediaPolicy get _settingsMediaPolicy => _settingsContext.mediaPolicy;

  WorkspaceEntitlements get _settingsEntitlements =>
      _settingsContext.entitlements;

  UserSettingsRepository? get _settingsRepository =>
      _settingsContext.backendAvailable ? _settingsContext.repository : null;

  UserSettingsContext _fallbackSettingsContext() {
    return UserSettingsContext(
      networkId: widget.activeNetworkId,
      networkName: _networkNameFor(widget.activeNetworkId),
      apiOrigin:
          _apiOriginForNetwork(widget.activeNetworkId) ??
          widget.mediaPolicy.apiOrigin ??
          '',
      currentUser: widget.currentUser,
      currentUserMedia: widget.currentUserMedia,
      mediaPolicy: widget.mediaPolicy,
      entitlements: widget.entitlements,
      repository: widget.repository,
      signedIn: widget.repository != null,
    );
  }

  String _networkNameFor(String networkId) {
    for (final record in widget.networkRecords) {
      if (record.networkId == networkId) {
        return record.networkName;
      }
    }
    return 'Current Network';
  }

  String? _apiOriginForNetwork(String networkId) {
    for (final record in widget.networkRecords) {
      if (sameWorkspaceNetworkId(record.networkId, networkId)) {
        return record.apiOrigin;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedSettingsNetworkId = widget.activeNetworkId;
    _selectedContextSignature = _settingsContextSignature(_settingsContext);
    _sessionsController = UserSettingsSessionsController(
      repository: _settingsRepository,
    );
    _notificationsController = UserSettingsNotificationsController(
      repository: _settingsRepository,
    );
    _seedProfileFields();
    _seedProfileMedia();
    _seedMemberListBanner();
    unawaited(_loadPreferences());
  }

  @override
  void didUpdateWidget(UserSettingsWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeNetworkId != widget.activeNetworkId) {
      _selectedSettingsNetworkId = widget.activeNetworkId;
    } else if (!_settingsContexts.any(
      (context) => context.networkId == _selectedSettingsNetworkId,
    )) {
      _selectedSettingsNetworkId = widget.activeNetworkId;
    }
    final contextSignature = _settingsContextSignature(_settingsContext);
    if (contextSignature != _selectedContextSignature) {
      _selectedContextSignature = contextSignature;
      _resetContextOwnedState();
      _seedProfileMedia();
      _seedProfileFields();
      _seedMemberListBanner();
    }
    if (!identical(_sessionsController.repository, _settingsRepository)) {
      _sessionsController.dispose();
      _sessionsController = UserSettingsSessionsController(
        repository: _settingsRepository,
      );
      if (_activeCategory == _UserSettingsCategory.sessions) {
        unawaited(_sessionsController.load());
      }
    }
    if (!identical(_notificationsController.repository, _settingsRepository)) {
      _notificationsController.dispose();
      _notificationsController = UserSettingsNotificationsController(
        repository: _settingsRepository,
      );
      if (_activeCategory == _UserSettingsCategory.notifications) {
        unawaited(_notificationsController.load());
      }
    }
  }

  @override
  void dispose() {
    _sessionsController.dispose();
    _notificationsController.dispose();
    _mediaLoader.close();
    _scrollController.dispose();
    super.dispose();
  }

  String _settingsContextSignature(UserSettingsContext context) {
    return [
      context.networkId,
      context.apiOrigin,
      context.signedIn.toString(),
      context.currentUser.id,
      context.currentUser.username,
      context.currentUser.displayName ?? '',
      context.currentUser.email,
      context.currentUser.avatarUrl ?? '',
      context.currentUser.bannerUrl ?? '',
      context.currentUser.bannerBaseColor ?? '',
      context.currentUser.memberListBannerUrl ?? '',
      context.currentUser.bio ?? '',
      context.currentUser.totpEnabled.toString(),
      context.currentUserMedia?.displayName ?? '',
      context.currentUserMedia?.avatarUrl ?? '',
      context.currentUserMedia?.bannerUrl ?? '',
      context.currentUserMedia?.bannerBaseColor?.toARGB32().toString() ?? '',
      context.currentUserMedia?.memberListBannerUrl ?? '',
    ].join('\u001F');
  }

  void _resetContextOwnedState() {
    _busyAction = null;
    _profileError = null;
    _profileFieldsError = null;
    _accountError = null;
    _accountSuccess = null;
    _error = null;
    _securityError = null;
    _securitySuccess = null;
    _notificationSoundPreviewError = null;
    _notificationSoundPreviewBusy = false;
    _editingDisplayName = false;
    _editingBio = false;
    _changingPassword = false;
    _changingEmail = false;
    _confirmingEmail = false;
    _emailHas2fa = false;
    _showCurrentPassword = false;
    _showNewPassword = false;
    _currentPassword = '';
    _newPassword = '';
    _confirmPassword = '';
    _currentEmail = '';
    _newEmail = '';
    _emailPassword = '';
    _emailCode = '';
    _twoFactorPassword = '';
    _twoFactorCode = '';
    _twoFactorDisablePassword = '';
    _twoFactorDisableCode = '';
    _twoFactorRegeneratePassword = '';
    _twoFactorRegenerateCode = '';
    _twoFactorStatus = null;
    _twoFactorSetup = null;
    _twoFactorBackupCodes = const [];
    _twoFactorStep = _TwoFactorSettingsStep.status;
    _twoFactorStatusLoaded = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        key: const ValueKey('user-settings-workspace'),
        decoration: BoxDecoration(
          color: colors.panelRaised,
          border: Border(left: BorderSide(color: colors.border)),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAA000000),
              blurRadius: 22,
              offset: Offset(-10, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 192,
              child: _UserSettingsNavigation(
                activeCategory: _activeCategory,
                onCategorySelected: _selectCategory,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _UserSettingsHeader(
                    activeCategory: _activeCategory,
                    settingsContext: _settingsContext,
                    homeNetworkId: widget.homeNetworkId,
                    onClose: widget.onClose,
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SmoothSingleChildScrollView(
                        controller: _scrollController,
                        primary: false,
                        child: KeyedSubtree(
                          key: ValueKey(
                            'user-settings-content-${_activeCategory.key}',
                          ),
                          child: _buildActiveCategory(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCategory(_UserSettingsCategory category) {
    if (_activeCategory == category) {
      return;
    }
    setState(() => _activeCategory = category);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    if (category == _UserSettingsCategory.security) {
      unawaited(_loadTwoFactorStatusIfNeeded());
    }
    if (category == _UserSettingsCategory.sessions) {
      unawaited(_sessionsController.load());
    }
    if (category == _UserSettingsCategory.notifications) {
      unawaited(_notificationsController.load());
    }
  }

  Widget _buildActiveCategory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: switch (_activeCategory) {
        _UserSettingsCategory.accessibility => _AccessibilitySettingsTab(
          accessibilitySettings: widget.accessibilitySettings,
          onAccessibilityChanged: widget.onAccessibilityChanged,
        ),
        _UserSettingsCategory.account => _AccountSettingsTab(
          currentUser: _settingsUser,
          currentEmail: _currentEmail,
          newEmail: _newEmail,
          emailPassword: _emailPassword,
          emailCode: _emailCode,
          changingEmail: _changingEmail,
          confirmingEmail: _confirmingEmail,
          emailHas2fa: _emailHas2fa,
          currentPassword: _currentPassword,
          newPassword: _newPassword,
          confirmPassword: _confirmPassword,
          changingPassword: _changingPassword,
          showCurrentPassword: _showCurrentPassword,
          showNewPassword: _showNewPassword,
          busyAction: _busyAction,
          error: _accountError,
          success: _accountSuccess,
          onCurrentEmailChanged: (value) =>
              setState(() => _currentEmail = value),
          onNewEmailChanged: (value) => setState(() => _newEmail = value),
          onEmailPasswordChanged: (value) =>
              setState(() => _emailPassword = value),
          onEmailCodeChanged: (value) => setState(() => _emailCode = value),
          onBeginEmailChange: () {
            setState(() {
              _changingEmail = true;
              _confirmingEmail = false;
              _currentEmail = '';
              _newEmail = '';
              _emailPassword = '';
              _emailCode = '';
              _accountError = null;
              _accountSuccess = null;
            });
          },
          onCancelEmailChange: _resetEmailChange,
          onStartEmailChange: _startEmailChange,
          onConfirmEmailChange: _confirmEmailChange,
          onCurrentPasswordChanged: (value) =>
              setState(() => _currentPassword = value),
          onNewPasswordChanged: (value) => setState(() => _newPassword = value),
          onConfirmPasswordChanged: (value) =>
              setState(() => _confirmPassword = value),
          onBeginPasswordChange: () {
            setState(() {
              _changingPassword = true;
              _currentPassword = '';
              _newPassword = '';
              _confirmPassword = '';
              _accountError = null;
              _accountSuccess = null;
            });
          },
          onCancelPasswordChange: _resetPasswordChange,
          onChangePassword: _changePassword,
          onToggleCurrentPassword: () =>
              setState(() => _showCurrentPassword = !_showCurrentPassword),
          onToggleNewPassword: () =>
              setState(() => _showNewPassword = !_showNewPassword),
        ),
        _UserSettingsCategory.security => _SecuritySettingsTab(
          currentUser: _settingsUser,
          repositoryAvailable: _settingsRepository != null,
          status: _twoFactorStatus,
          step: _twoFactorStep,
          setup: _twoFactorSetup,
          backupCodes: _twoFactorBackupCodes,
          password: _twoFactorPassword,
          code: _twoFactorCode,
          disablePassword: _twoFactorDisablePassword,
          disableCode: _twoFactorDisableCode,
          regeneratePassword: _twoFactorRegeneratePassword,
          regenerateCode: _twoFactorRegenerateCode,
          busyAction: _busyAction,
          error: _securityError,
          success: _securitySuccess,
          onRefreshStatus: () => _loadTwoFactorStatusIfNeeded(force: true),
          onStartSetupStep: () {
            setState(() {
              _twoFactorStep = _TwoFactorSettingsStep.password;
              _securityError = null;
              _securitySuccess = null;
            });
          },
          onPasswordChanged: (value) =>
              setState(() => _twoFactorPassword = value),
          onCodeChanged: (value) => setState(() => _twoFactorCode = value),
          onDisablePasswordChanged: (value) =>
              setState(() => _twoFactorDisablePassword = value),
          onDisableCodeChanged: (value) =>
              setState(() => _twoFactorDisableCode = value),
          onRegeneratePasswordChanged: (value) =>
              setState(() => _twoFactorRegeneratePassword = value),
          onRegenerateCodeChanged: (value) =>
              setState(() => _twoFactorRegenerateCode = value),
          onStartSetup: _startTwoFactorSetup,
          onScannedSetup: () {
            setState(() {
              _twoFactorStep = _TwoFactorSettingsStep.verify;
              _securityError = null;
            });
          },
          onBackToQr: () {
            setState(() {
              _twoFactorStep = _TwoFactorSettingsStep.qr;
              _securityError = null;
            });
          },
          onVerifySetup: _verifyTwoFactorSetup,
          onShowDisable: () {
            setState(() {
              _twoFactorStep = _TwoFactorSettingsStep.disable;
              _securityError = null;
              _securitySuccess = null;
            });
          },
          onDisable: _disableTwoFactor,
          onShowRegenerate: () {
            setState(() {
              _twoFactorStep = _TwoFactorSettingsStep.regenerate;
              _securityError = null;
              _securitySuccess = null;
            });
          },
          onRegenerate: _regenerateTwoFactorBackupCodes,
          onDone: () {
            _resetTwoFactorState(keepStatus: true);
            unawaited(_loadTwoFactorStatusIfNeeded(force: true));
          },
          onCancel: () {
            _resetTwoFactorState(keepStatus: true);
          },
        ),
        _UserSettingsCategory.sessions => _SessionsSettingsTab(
          controller: _sessionsController,
        ),
        _UserSettingsCategory.network => _NetworkSettingsTab(
          mediaPolicy: widget.mediaPolicy,
          networkRecords: widget.networkRecords,
          activeNetworkId: widget.activeNetworkId,
          homeNetworkId: widget.homeNetworkId,
          onSetNetworkUsername: widget.onSetNetworkUsername,
          onRetryNetwork: widget.onRetryNetwork,
          onRemoveNetwork: widget.onRemoveNetwork,
        ),
        _UserSettingsCategory.general => _GeneralSettingsTab(
          preferences: _preferences,
          onChanged: _updatePreferences,
        ),
        _UserSettingsCategory.appearance => _AppearanceSettingsTab(
          preferences: _preferences,
          onChanged: _updatePreferences,
        ),
        _UserSettingsCategory.voice => _VoiceAudioSettingsTab(
          preferences: _preferences,
          onChanged: _updatePreferences,
        ),
        _UserSettingsCategory.notifications => _NotificationsSettingsTab(
          controller: _notificationsController,
          preferences: _preferences,
          soundPreviewBusy: _notificationSoundPreviewBusy,
          soundPreviewError: _notificationSoundPreviewError,
          onChanged: _updatePreferences,
          onPlayNotificationSound: _playNotificationSoundPreview,
        ),
        _UserSettingsCategory.about => _AboutSettingsTab(
          mediaPolicy: _settingsMediaPolicy,
        ),
        _UserSettingsCategory.profile => _ProfileSettingsTab(
          currentUser: _settingsUser,
          currentUserMedia: _settingsUserMedia,
          mediaPolicy: _settingsMediaPolicy,
          displayNameDraft: _displayNameDraft,
          bioDraft: _bioDraft,
          editingDisplayName: _editingDisplayName,
          editingBio: _editingBio,
          busyAction: _busyAction,
          profileFieldsError: _profileFieldsError,
          onDisplayNameChanged: (value) =>
              setState(() => _displayNameDraft = value),
          onBioChanged: (value) => setState(() => _bioDraft = value),
          onEditDisplayName: () {
            setState(() {
              _editingDisplayName = true;
              _profileFieldsError = null;
            });
          },
          onCancelDisplayName: () {
            setState(() {
              _editingDisplayName = false;
              _profileFieldsError = null;
            });
            _seedProfileFields();
          },
          onSaveDisplayName: _saveDisplayName,
          onEditBio: () {
            setState(() {
              _editingBio = true;
              _profileFieldsError = null;
            });
          },
          onCancelBio: () {
            setState(() {
              _editingBio = false;
              _profileFieldsError = null;
            });
            _seedProfileFields();
          },
          onSaveBio: _saveBio,
          identityCard: _ProfileIdentityCard(
            currentUser: _settingsUser,
            currentUserMedia: _settingsUserMedia,
            mediaPolicy: _settingsMediaPolicy,
            enabled: _settingsEntitlements.imageUploads,
            canManage: _canManageProfileVisuals,
            animatedAvatarEnabled: _settingsEntitlements.animatedAvatar,
            animatedBannerEnabled: _settingsEntitlements.animatedBanner,
            avatarUrl: _avatarUrl,
            bannerUrl: _profileBannerUrl,
            bannerBaseColor: _profileBannerBaseColor,
            bannerCrop: _profileBannerCrop,
            busyAction: _busyAction,
            error: _profileError,
            onSelectAvatar: _selectProfileAvatar,
            onRemoveAvatar: _removeProfileAvatar,
            onSelectBanner: _selectProfileBanner,
            onBannerBaseColorChanged: (color) {
              unawaited(_setProfileBannerBaseColor(color));
            },
            onPositionBanner: _positionProfileBanner,
            onRemoveBanner: _removeProfileBanner,
          ),
          memberListBannerCard: _MemberListBannerCard(
            currentUser: _settingsUser,
            mediaPolicy: _settingsMediaPolicy,
            enabled: _settingsEntitlements.memberListBanner,
            imageUploadsEnabled: _settingsEntitlements.imageUploads,
            canManage: _canManageMemberListBanner,
            bannerUrl: _memberListBannerUrl,
            bannerCrop: _memberListBannerCrop,
            busyAction: _busyAction,
            error: _error,
            onSelect: _selectMemberListBanner,
            onPosition: _positionMemberListBanner,
            onRemove: _removeMemberListBanner,
          ),
        ),
      },
    );
  }

  void _seedProfileMedia() {
    _avatarUrl = _settingsUserMedia?.avatarUrl ?? _settingsUser.avatarUrl;
    _profileBannerUrl =
        _settingsUserMedia?.bannerUrl ?? _settingsUser.bannerUrl;
    _profileBannerBaseColor =
        _settingsUserMedia?.bannerBaseColor ??
        _profileHexColor(_settingsUser.bannerBaseColor) ??
        (_preferences.profileBannerBaseColor == null
            ? null
            : Color(_preferences.profileBannerBaseColor!));
    _profileBannerCrop = _settingsUserMedia?.bannerCrop;
  }

  void _seedProfileFields() {
    if (!_editingDisplayName) {
      _displayNameDraft =
          _settingsUserMedia?.displayName ?? _settingsUser.displayName ?? '';
    }
    if (!_editingBio) {
      _bioDraft = _settingsUserMedia?.bio ?? _settingsUser.bio ?? '';
    }
  }

  void _seedMemberListBanner() {
    _memberListBannerUrl =
        _settingsUserMedia?.memberListBannerUrl ??
        _settingsUser.memberListBannerUrl;
    _memberListBannerCrop = _settingsUserMedia?.memberListBannerCrop;
  }

  Future<void> _loadPreferences() async {
    final preferences = await widget.preferencesStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _preferences = preferences;
      _profileBannerBaseColor ??= preferences.profileBannerBaseColor == null
          ? null
          : Color(preferences.profileBannerBaseColor!);
    });
  }

  void _updatePreferences(UserSettingsPreferences preferences) {
    setState(() => _preferences = preferences);
    widget.onPreferencesChanged(preferences);
    unawaited(widget.preferencesStore.save(preferences));
  }

  Future<void> _playNotificationSoundPreview() async {
    if (_notificationSoundPreviewBusy) {
      return;
    }
    setState(() {
      _notificationSoundPreviewBusy = true;
      _notificationSoundPreviewError = null;
    });
    try {
      await widget.notificationSoundPreview.play();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationSoundPreviewError =
            'Notification sound could not be played on this device.';
      });
    } finally {
      if (mounted) {
        setState(() => _notificationSoundPreviewBusy = false);
      }
    }
  }

  void _resetTwoFactorState({required bool keepStatus}) {
    setState(() {
      _twoFactorPassword = '';
      _twoFactorCode = '';
      _twoFactorDisablePassword = '';
      _twoFactorDisableCode = '';
      _twoFactorRegeneratePassword = '';
      _twoFactorRegenerateCode = '';
      _twoFactorSetup = null;
      _twoFactorBackupCodes = const [];
      _twoFactorStep = _TwoFactorSettingsStep.status;
      _securityError = null;
      _securitySuccess = null;
      if (!keepStatus) {
        _twoFactorStatus = null;
        _twoFactorStatusLoaded = false;
      }
    });
  }

  Future<void> _loadTwoFactorStatusIfNeeded({bool force = false}) async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    if (!force && _twoFactorStatusLoaded) {
      return;
    }
    setState(() {
      _busyAction = '2fa-status';
      _securityError = null;
    });
    try {
      final status = await repository.loadTwoFactorStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _twoFactorStatus = status;
        _twoFactorStatusLoaded = true;
        _busyAction = null;
      });
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _securityError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _securityError = 'Two factor status could not be loaded';
      });
    }
  }

  Future<void> _startTwoFactorSetup(String password) async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    await _runTwoFactorAction('2fa-setup', () async {
      final setup = await repository.startTwoFactorSetup(
        currentPassword: password,
      );
      _twoFactorPassword = '';
      _twoFactorSetup = setup;
      _twoFactorStep = _TwoFactorSettingsStep.qr;
    });
  }

  Future<void> _verifyTwoFactorSetup() async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    await _runTwoFactorAction('2fa-verify', () async {
      final verified = await repository.verifyTwoFactorSetup(
        code: _twoFactorCode,
      );
      _twoFactorCode = '';
      _twoFactorSetup = null;
      _twoFactorBackupCodes = verified.backupCodes;
      _twoFactorStatus = TwoFactorStatus(
        enabled: verified.enabled,
        enabledAt: DateTime.now().toUtc(),
        remainingBackupCodes: verified.backupCodes.length,
      );
      _twoFactorStatusLoaded = true;
      _twoFactorStep = _TwoFactorSettingsStep.backupCodes;
      _securitySuccess = 'Two-factor authentication enabled';
    }, refreshProfile: true);
  }

  Future<void> _disableTwoFactor() async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    await _runTwoFactorAction('2fa-disable', () async {
      await repository.disableTwoFactor(
        currentPassword: _twoFactorDisablePassword,
        code: _twoFactorDisableCode,
      );
      _twoFactorDisablePassword = '';
      _twoFactorDisableCode = '';
      _twoFactorStatus = const TwoFactorStatus(
        enabled: false,
        enabledAt: null,
        remainingBackupCodes: 0,
      );
      _twoFactorStatusLoaded = true;
      _twoFactorStep = _TwoFactorSettingsStep.status;
      _securitySuccess = 'Two-factor authentication disabled';
    }, refreshProfile: true);
  }

  Future<void> _regenerateTwoFactorBackupCodes() async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    await _runTwoFactorAction('2fa-regenerate', () async {
      final regenerated = await repository.regenerateTwoFactorBackupCodes(
        currentPassword: _twoFactorRegeneratePassword,
        totpCode: _twoFactorRegenerateCode,
      );
      _twoFactorRegeneratePassword = '';
      _twoFactorRegenerateCode = '';
      _twoFactorBackupCodes = regenerated.backupCodes;
      _twoFactorStatus = TwoFactorStatus(
        enabled: true,
        enabledAt: _twoFactorStatus?.enabledAt ?? DateTime.now().toUtc(),
        remainingBackupCodes: regenerated.backupCodes.length,
      );
      _twoFactorStatusLoaded = true;
      _twoFactorStep = _TwoFactorSettingsStep.backupCodes;
      _securitySuccess = 'Backup codes regenerated';
    });
  }

  Future<void> _runTwoFactorAction(
    String action,
    Future<void> Function() task, {
    bool refreshProfile = false,
  }) async {
    setState(() {
      _busyAction = action;
      _securityError = null;
      _securitySuccess = null;
    });
    try {
      await task();
      if (refreshProfile) {
        await widget.onProfileUpdated();
      }
      if (!mounted) {
        return;
      }
      setState(() => _busyAction = null);
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _securityError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _securityError = 'Security settings could not be updated';
      });
    }
  }

  Future<void> _saveDisplayName() async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    await _runProfileFieldAction('display-name-save', () async {
      final updated = await repository.updateCurrentUserProfile(
        patch: UserProfilePatch(displayName: _displayNameDraft),
      );
      _displayNameDraft = updated.displayName ?? '';
      _editingDisplayName = false;
    });
  }

  Future<void> _saveBio() async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    await _runProfileFieldAction('bio-save', () async {
      final updated = await repository.updateCurrentUserProfile(
        patch: UserProfilePatch(bio: _bioDraft),
      );
      _bioDraft = updated.bio ?? '';
      _editingBio = false;
    });
  }

  Future<void> _runProfileFieldAction(
    String action,
    Future<void> Function() task,
  ) async {
    setState(() {
      _busyAction = action;
      _profileFieldsError = null;
    });
    try {
      await task();
      await widget.onProfileUpdated();
      if (!mounted) {
        return;
      }
      setState(() => _busyAction = null);
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _profileFieldsError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _profileFieldsError = 'Profile could not be updated';
      });
    }
  }

  void _resetPasswordChange() {
    setState(() {
      _changingPassword = false;
      _currentPassword = '';
      _newPassword = '';
      _confirmPassword = '';
      _showCurrentPassword = false;
      _showNewPassword = false;
      _accountError = null;
    });
  }

  Future<void> _changePassword() async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    if (_newPassword != _confirmPassword) {
      setState(() => _accountError = 'Passwords do not match');
      return;
    }
    if (_newPassword.length < 8) {
      setState(() => _accountError = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _busyAction = 'password-change';
      _accountError = null;
      _accountSuccess = null;
    });
    try {
      await repository.changeCurrentUserPassword(
        currentPassword: _currentPassword,
        newPassword: _newPassword,
      );
      await widget.onProfileUpdated();
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _changingPassword = false;
        _currentPassword = '';
        _newPassword = '';
        _confirmPassword = '';
        _accountSuccess = 'Password changed successfully.';
      });
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _accountError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _accountError = 'Password could not be changed';
      });
    }
  }

  void _resetEmailChange() {
    setState(() {
      _changingEmail = false;
      _confirmingEmail = false;
      _emailHas2fa = false;
      _currentEmail = '';
      _newEmail = '';
      _emailPassword = '';
      _emailCode = '';
      _accountError = null;
    });
  }

  Future<void> _startEmailChange() async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    setState(() {
      _busyAction = 'email-change-start';
      _accountError = null;
      _accountSuccess = null;
    });
    try {
      final started = await repository.startCurrentUserEmailChange(
        currentEmail: _currentEmail,
        newEmail: _newEmail,
        currentPassword: _emailPassword,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _emailHas2fa = started.has2fa;
        _confirmingEmail = true;
      });
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _accountError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _accountError = 'Email change could not be started';
      });
    }
  }

  Future<void> _confirmEmailChange() async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    setState(() {
      _busyAction = 'email-change-confirm';
      _accountError = null;
    });
    try {
      await repository.confirmCurrentUserEmailChange(code: _emailCode);
      await widget.onProfileUpdated();
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _changingEmail = false;
        _confirmingEmail = false;
        _emailCode = '';
        _accountSuccess = 'Email changed successfully.';
      });
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _accountError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _accountError = 'Email could not be changed';
      });
    }
  }

  Future<void> _selectProfileAvatar() async {
    final repository = _settingsRepository;
    if (repository == null || !_canManageProfileVisuals) {
      return;
    }
    final file = await openFile(acceptedTypeGroups: [_imageTypeGroup]);
    if (file == null) {
      return;
    }
    final validationError = await _validateImageFile(
      file,
      label: 'Avatar',
      animatedEnabled: _settingsEntitlements.animatedAvatar,
    );
    if (validationError != null) {
      if (mounted) {
        setState(() => _profileError = validationError);
      }
      return;
    }

    await _runProfileAction('avatar-upload', () async {
      final updated = await repository.uploadUserAvatar(
        upload: ServerSettingsUpload(path: file.path, fileName: file.name),
      );
      _avatarUrl = updated.avatarUrl;
    });
  }

  Future<void> _removeProfileAvatar() async {
    final repository = _settingsRepository;
    if (repository == null || !_canManageProfileVisuals || _avatarUrl == null) {
      return;
    }
    await _runProfileAction('avatar-remove', () async {
      await repository.deleteUserAvatar();
      _avatarUrl = null;
    });
  }

  Future<void> _selectProfileBanner() async {
    final repository = _settingsRepository;
    if (repository == null || !_canManageProfileVisuals) {
      return;
    }
    final file = await openFile(acceptedTypeGroups: [_imageTypeGroup]);
    if (file == null) {
      return;
    }
    final validationError = await _validateImageFile(
      file,
      label: 'Profile banner',
      animatedEnabled: _settingsEntitlements.animatedBanner,
    );
    if (validationError != null) {
      if (mounted) {
        setState(() => _profileError = validationError);
      }
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    final crop = await showBannerCropDialog(
      context: context,
      title: 'Position Profile Banner',
      imageProvider: MemoryImage(bytes),
      initialCrop: null,
      aspectRatio: _profileBannerAspectRatio,
    );
    if (crop == null) {
      return;
    }

    await _runProfileAction('profile-banner-upload', () async {
      final uploaded = await repository.uploadUserProfileBanner(
        upload: ServerSettingsUpload(path: file.path, fileName: file.name),
      );
      final positioned = await repository.updateUserProfileBannerCrop(
        crop: crop,
      );
      _profileBannerUrl = positioned.bannerUrl ?? uploaded.bannerUrl;
      _profileBannerCrop = positioned.bannerCrop ?? uploaded.bannerCrop;
    });
  }

  Future<void> _positionProfileBanner() async {
    final repository = _settingsRepository;
    if (repository == null ||
        !_canManageProfileVisuals ||
        _profileBannerUrl == null) {
      return;
    }
    final bannerUri = safeServerMediaUri(
      _profileBannerUrl,
      policy: _settingsMediaPolicy,
    );
    if (bannerUri == null) {
      setState(() {
        _profileError =
            'Profile banner URL is outside this network media policy';
      });
      return;
    }

    Uint8List bytes;
    setState(() {
      _busyAction = 'profile-banner-position';
      _profileError = null;
    });
    try {
      bytes = await _mediaLoader.load(bannerUri, policy: _settingsMediaPolicy);
    } on ServerMediaLoadException catch (error) {
      if (mounted) {
        setState(() {
          _busyAction = null;
          _profileError = error.message;
        });
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _busyAction = null;
          _profileError = 'Profile banner could not be loaded';
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _busyAction = null);
    }

    if (!mounted) {
      return;
    }
    final crop = await showBannerCropDialog(
      context: context,
      title: 'Position Profile Banner',
      imageProvider: MemoryImage(bytes),
      initialCrop: _profileBannerCrop,
      aspectRatio: _profileBannerAspectRatio,
    );
    if (crop == null) {
      return;
    }

    await _runProfileAction('profile-banner-position', () async {
      final update = await repository.updateUserProfileBannerCrop(crop: crop);
      _profileBannerUrl = update.bannerUrl ?? _profileBannerUrl;
      _profileBannerCrop = update.bannerCrop ?? crop;
    });
  }

  Future<void> _removeProfileBanner() async {
    final repository = _settingsRepository;
    if (repository == null ||
        !_canManageProfileVisuals ||
        _profileBannerUrl == null) {
      return;
    }
    await _runProfileAction('profile-banner-remove', () async {
      await repository.deleteUserProfileBanner();
      _profileBannerUrl = null;
      _profileBannerCrop = null;
    });
  }

  Future<void> _setProfileBannerBaseColor(Color color) async {
    final repository = _settingsRepository;
    if (repository == null || _busyAction != null) {
      return;
    }
    final next = _preferences.copyWith(
      profileBannerBaseColor: _colorToArgbInt(color),
    );
    setState(() {
      _preferences = next;
      _profileBannerBaseColor = color;
    });
    await widget.preferencesStore.save(next);
    widget.onPreferencesChanged(next);
    await _runProfileFieldAction('profile-banner-base-color-save', () async {
      await repository.updateCurrentUserProfile(
        patch: UserProfilePatch(bannerBaseColor: _colorToProfileHex(color)),
      );
    });
  }

  Future<String?> _validateImageFile(
    XFile file, {
    required String label,
    required bool animatedEnabled,
  }) async {
    final maxUploadBytes = _settingsEntitlements.maxUploadBytes;
    if (maxUploadBytes != null) {
      final fileLength = await file.length();
      if (fileLength > maxUploadBytes) {
        return '$label is too large. Choose an image under '
            '${_formatFileSize(maxUploadBytes)}.';
      }
    }
    final extension = file.name.split('.').last.toLowerCase();
    if (extension == 'gif' && !animatedEnabled) {
      return '$label animated images are disabled on this network.';
    }
    return null;
  }

  Future<void> _runProfileAction(
    String action,
    Future<void> Function() task,
  ) async {
    setState(() {
      _busyAction = action;
      _profileError = null;
    });
    try {
      await task();
      await widget.onProfileUpdated();
      if (!mounted) {
        return;
      }
      setState(() => _busyAction = null);
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _profileError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _profileError = 'Profile media could not be updated';
      });
    }
  }

  Future<void> _selectMemberListBanner() async {
    final repository = _settingsRepository;
    if (repository == null || !_canManageMemberListBanner) {
      return;
    }
    final file = await openFile(acceptedTypeGroups: [_imageTypeGroup]);
    if (file == null) {
      return;
    }
    final maxUploadBytes = _settingsEntitlements.maxUploadBytes;
    if (maxUploadBytes != null) {
      final fileLength = await file.length();
      if (fileLength > maxUploadBytes) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error =
              'Member list banner is too large. Choose an image under '
              '${_formatFileSize(maxUploadBytes)}.';
        });
        return;
      }
    }
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    final crop = await showBannerCropDialog(
      context: context,
      title: 'Position Member List Banner',
      imageProvider: MemoryImage(bytes),
      initialCrop: null,
      aspectRatio: _memberListBannerAspectRatio,
    );
    if (crop == null) {
      return;
    }

    await _runBannerAction('upload', () async {
      final uploaded = await repository.uploadMemberListBanner(
        upload: ServerSettingsUpload(path: file.path, fileName: file.name),
      );
      final positioned = await repository.updateMemberListBannerCrop(
        crop: crop,
      );
      _memberListBannerUrl =
          positioned.memberListBannerUrl ?? uploaded.memberListBannerUrl;
      _memberListBannerCrop =
          positioned.memberListBannerCrop ?? uploaded.memberListBannerCrop;
    });
  }

  Future<void> _positionMemberListBanner() async {
    final repository = _settingsRepository;
    if (repository == null ||
        !_canManageMemberListBanner ||
        _memberListBannerUrl == null) {
      return;
    }
    final bannerUri = safeServerMediaUri(
      _memberListBannerUrl,
      policy: _settingsMediaPolicy,
    );
    if (bannerUri == null) {
      setState(() {
        _error = 'Member list banner URL is outside this network media policy';
      });
      return;
    }

    Uint8List bytes;
    setState(() {
      _busyAction = 'position';
      _error = null;
    });
    try {
      bytes = await _mediaLoader.load(bannerUri, policy: _settingsMediaPolicy);
    } on ServerMediaLoadException catch (error) {
      if (mounted) {
        setState(() {
          _busyAction = null;
          _error = error.message;
        });
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _busyAction = null;
          _error = 'Member list banner could not be loaded';
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _busyAction = null);
    }

    if (!mounted) {
      return;
    }
    final crop = await showBannerCropDialog(
      context: context,
      title: 'Position Member List Banner',
      imageProvider: MemoryImage(bytes),
      initialCrop: _memberListBannerCrop,
      aspectRatio: _memberListBannerAspectRatio,
    );
    if (crop == null) {
      return;
    }

    await _runBannerAction('position', () async {
      final update = await repository.updateMemberListBannerCrop(crop: crop);
      _memberListBannerUrl = update.memberListBannerUrl ?? _memberListBannerUrl;
      _memberListBannerCrop = update.memberListBannerCrop ?? crop;
    });
  }

  Future<void> _removeMemberListBanner() async {
    final repository = _settingsRepository;
    if (repository == null ||
        !_canManageMemberListBanner ||
        _memberListBannerUrl == null) {
      return;
    }
    await _runBannerAction('remove', () async {
      await repository.deleteMemberListBanner();
      _memberListBannerUrl = null;
      _memberListBannerCrop = null;
    });
  }

  Future<void> _runBannerAction(
    String action,
    Future<void> Function() task,
  ) async {
    setState(() {
      _busyAction = action;
      _error = null;
    });
    try {
      await task();
      await widget.onProfileUpdated();
      if (!mounted) {
        return;
      }
      setState(() => _busyAction = null);
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyAction = null;
        _error = 'Member list banner could not be updated';
      });
    }
  }
}

String _formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(megabytes >= 10 ? 0 : 1)} MB';
  }
  if (bytes >= 1024) {
    final kilobytes = bytes / 1024;
    return '${kilobytes.toStringAsFixed(kilobytes >= 10 ? 0 : 1)} KB';
  }
  return '$bytes bytes';
}

String _maskedEmail(String email) {
  final trimmed = email.trim();
  final at = trimmed.indexOf('@');
  if (at <= 1) {
    return '********@******';
  }
  return '${trimmed.substring(0, 1)}******${trimmed.substring(at)}';
}
