part of 'user_settings_workspace.dart';

class _SecuritySettingsTab extends StatelessWidget {
  const _SecuritySettingsTab({
    required this.currentUser,
    required this.repositoryAvailable,
    required this.status,
    required this.step,
    required this.setup,
    required this.backupCodes,
    required this.password,
    required this.code,
    required this.disablePassword,
    required this.disableCode,
    required this.regeneratePassword,
    required this.regenerateCode,
    required this.busyAction,
    required this.error,
    required this.success,
    required this.onRefreshStatus,
    required this.onStartSetupStep,
    required this.onPasswordChanged,
    required this.onCodeChanged,
    required this.onDisablePasswordChanged,
    required this.onDisableCodeChanged,
    required this.onRegeneratePasswordChanged,
    required this.onRegenerateCodeChanged,
    required this.onStartSetup,
    required this.onScannedSetup,
    required this.onBackToQr,
    required this.onVerifySetup,
    required this.onShowDisable,
    required this.onDisable,
    required this.onShowRegenerate,
    required this.onRegenerate,
    required this.onDone,
    required this.onCancel,
  });

  final VerdantUser currentUser;
  final bool repositoryAvailable;
  final TwoFactorStatus? status;
  final _TwoFactorSettingsStep step;
  final TwoFactorSetup? setup;
  final List<String> backupCodes;
  final String password;
  final String code;
  final String disablePassword;
  final String disableCode;
  final String regeneratePassword;
  final String regenerateCode;
  final String? busyAction;
  final String? error;
  final String? success;
  final Future<void> Function() onRefreshStatus;
  final VoidCallback onStartSetupStep;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onCodeChanged;
  final ValueChanged<String> onDisablePasswordChanged;
  final ValueChanged<String> onDisableCodeChanged;
  final ValueChanged<String> onRegeneratePasswordChanged;
  final ValueChanged<String> onRegenerateCodeChanged;
  final Future<void> Function(String password) onStartSetup;
  final VoidCallback onScannedSetup;
  final VoidCallback onBackToQr;
  final Future<void> Function() onVerifySetup;
  final VoidCallback onShowDisable;
  final Future<void> Function() onDisable;
  final VoidCallback onShowRegenerate;
  final Future<void> Function() onRegenerate;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final twoFactorEnabled = status?.enabled ?? currentUser.totpEnabled;
    final isLoading = busyAction == '2fa-status';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsSectionLabel(title: 'Security'),
        const SizedBox(height: 16),
        _twoFactorContent(context, twoFactorEnabled, isLoading),
        const _SettingsDivider(),
        _StatusSettingsRow(
          icon: Icons.mark_email_read_outlined,
          label: 'Email Verification',
          value: currentUser.emailVerified ? 'Verified' : 'Unverified',
          detail: currentUser.emailVerified
              ? 'This account email has been verified by the backend.'
              : 'Verify your email before relying on account recovery.',
          positive: currentUser.emailVerified,
        ),
      ],
    );
  }

  Widget _twoFactorContent(
    BuildContext context,
    bool twoFactorEnabled,
    bool isLoading,
  ) {
    final colors = VerdantThemeColors.of(context);
    final busy = busyAction?.startsWith('2fa-') == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 20,
              color: twoFactorEnabled ? colors.accentStrong : colors.text,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Two-Factor Authentication',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    twoFactorEnabled
                        ? 'A verification code is required for sign in.'
                        : 'Add an authenticator code before new sign-ins can complete.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _SecurityStatusBadge(
              label: twoFactorEnabled ? 'Enabled' : 'Disabled',
              positive: twoFactorEnabled,
              loading: isLoading,
            ),
          ],
        ),
        if (!repositoryAvailable) ...[
          const SizedBox(height: 12),
          const _SettingsInfoBanner(
            message:
                'Security actions are unavailable until this network session is connected.',
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          _SettingsError(message: error!),
        ],
        if (success != null) ...[
          const SizedBox(height: 12),
          _SettingsSuccess(message: success!),
        ],
        const SizedBox(height: 14),
        switch (step) {
          _TwoFactorSettingsStep.status => _TwoFactorStatusActions(
            enabled: twoFactorEnabled,
            remainingBackupCodes: status?.remainingBackupCodes,
            busy: busy,
            onEnable: repositoryAvailable ? onStartSetupStep : null,
            onRefresh: repositoryAvailable ? onRefreshStatus : null,
            onDisable: repositoryAvailable && twoFactorEnabled
                ? onShowDisable
                : null,
            onRegenerate: repositoryAvailable && twoFactorEnabled
                ? onShowRegenerate
                : null,
          ),
          _TwoFactorSettingsStep.password => _TwoFactorPasswordForm(
            password: password,
            busy: busyAction == '2fa-setup',
            onPasswordChanged: onPasswordChanged,
            onSubmit: onStartSetup,
            onCancel: onCancel,
          ),
          _TwoFactorSettingsStep.qr => _TwoFactorQrStep(
            setup: setup,
            onContinue: setup == null ? null : onScannedSetup,
            onCancel: onCancel,
          ),
          _TwoFactorSettingsStep.verify => _TwoFactorCodeForm(
            keyPrefix: 'user-settings-2fa-verify',
            label: 'Enter verification code',
            detail:
                'Enter the 6-digit code from your authenticator app to confirm setup.',
            code: code,
            busy: busyAction == '2fa-verify',
            primaryLabel: 'Verify & Enable',
            onCodeChanged: onCodeChanged,
            onPrimary: code.trim().length == 6 ? onVerifySetup : null,
            onCancel: onBackToQr,
          ),
          _TwoFactorSettingsStep.backupCodes => _TwoFactorBackupCodesStep(
            backupCodes: backupCodes,
            onDone: onDone,
          ),
          _TwoFactorSettingsStep.disable => _TwoFactorPasswordCodeForm(
            keyPrefix: 'user-settings-2fa-disable',
            label: 'Disable Two-Factor Authentication',
            detail: 'Enter your password and an authenticator or backup code.',
            password: disablePassword,
            code: disableCode,
            busy: busyAction == '2fa-disable',
            primaryLabel: 'Disable 2FA',
            danger: true,
            onPasswordChanged: onDisablePasswordChanged,
            onCodeChanged: onDisableCodeChanged,
            onPrimary:
                disablePassword.isNotEmpty && disableCode.trim().isNotEmpty
                ? onDisable
                : null,
            onCancel: onCancel,
          ),
          _TwoFactorSettingsStep.regenerate => _TwoFactorPasswordCodeForm(
            keyPrefix: 'user-settings-2fa-regenerate',
            label: 'Regenerate Backup Codes',
            detail:
                'Generate new backup codes. Existing backup codes stop working.',
            password: regeneratePassword,
            code: regenerateCode,
            busy: busyAction == '2fa-regenerate',
            primaryLabel: 'Regenerate',
            danger: false,
            onPasswordChanged: onRegeneratePasswordChanged,
            onCodeChanged: onRegenerateCodeChanged,
            onPrimary:
                regeneratePassword.isNotEmpty &&
                    regenerateCode.trim().length == 6
                ? onRegenerate
                : null,
            onCancel: onCancel,
          ),
        },
      ],
    );
  }
}

class _SecurityStatusBadge extends StatelessWidget {
  const _SecurityStatusBadge({
    required this.label,
    required this.positive,
    required this.loading,
  });

  final String label;
  final bool positive;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final tone = positive ? colors.accentStrong : colors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: positive ? colors.actionMuted : colors.panelRaised,
        border: Border.all(
          color: positive ? colors.accent : colors.borderStrong,
        ),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) ...[
            const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tone,
              fontWeight: VerdantFontWeights.semibold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoFactorStatusActions extends StatelessWidget {
  const _TwoFactorStatusActions({
    required this.enabled,
    required this.remainingBackupCodes,
    required this.busy,
    required this.onEnable,
    required this.onRefresh,
    required this.onDisable,
    required this.onRegenerate,
  });

  final bool enabled;
  final int? remainingBackupCodes;
  final bool busy;
  final VoidCallback? onEnable;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onDisable;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SmallSettingsButton(
            key: const ValueKey('user-settings-2fa-enable-button'),
            label: 'Enable Two-Factor Authentication',
            icon: Icons.shield_outlined,
            busy: busy,
            onPressed: onEnable,
          ),
          _SmallSettingsButton(
            label: 'Refresh Status',
            icon: Icons.refresh,
            busy: busy,
            onPressed: onRefresh == null ? null : () => onRefresh!(),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (remainingBackupCodes != null) ...[
          Text(
            'Backup codes remaining: $remainingBackupCodes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SmallSettingsButton(
              key: const ValueKey('user-settings-2fa-regenerate-button'),
              label: 'Regenerate Backup Codes',
              icon: Icons.refresh,
              busy: busy,
              onPressed: onRegenerate,
            ),
            _SmallSettingsButton(
              key: const ValueKey('user-settings-2fa-disable-button'),
              label: 'Disable 2FA',
              icon: Icons.lock_open_outlined,
              busy: busy,
              onPressed: onDisable,
            ),
          ],
        ),
      ],
    );
  }
}

class _TwoFactorPasswordForm extends StatelessWidget {
  const _TwoFactorPasswordForm({
    required this.password,
    required this.busy,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  final String password;
  final bool busy;
  final ValueChanged<String> onPasswordChanged;
  final Future<void> Function(String password) onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _TwoFactorPasswordFormBody(
      initialPassword: password,
      busy: busy,
      onPasswordChanged: onPasswordChanged,
      onSubmit: onSubmit,
      onCancel: onCancel,
    );
  }
}

class _TwoFactorPasswordFormBody extends StatefulWidget {
  const _TwoFactorPasswordFormBody({
    required this.initialPassword,
    required this.busy,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  final String initialPassword;
  final bool busy;
  final ValueChanged<String> onPasswordChanged;
  final Future<void> Function(String password) onSubmit;
  final VoidCallback onCancel;

  @override
  State<_TwoFactorPasswordFormBody> createState() =>
      _TwoFactorPasswordFormBodyState();
}

class _TwoFactorPasswordFormBodyState
    extends State<_TwoFactorPasswordFormBody> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String get _password => _controller.text;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPassword);
    _focusNode = FocusNode(debugLabel: 'user-settings-2fa-password-field');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.busy) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _requestPasswordFocus() {
    if (widget.busy) {
      return;
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsFormLabel(
          label: 'Verify your identity',
          detail: 'Enter your password to begin 2FA setup.',
        ),
        TextField(
          key: const ValueKey('user-settings-2fa-password-field'),
          controller: _controller,
          focusNode: _focusNode,
          enabled: !widget.busy,
          obscureText: true,
          autofocus: true,
          textInputAction: TextInputAction.done,
          enableSuggestions: false,
          autocorrect: false,
          onTap: _requestPasswordFocus,
          onChanged: (value) {
            widget.onPasswordChanged(value);
            setState(() {});
          },
          onSubmitted: widget.busy ? null : (_) => widget.onSubmit(_password),
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        const SizedBox(height: 10),
        _SettingsFormActions(
          primaryKey: const ValueKey(
            'user-settings-2fa-password-continue-button',
          ),
          busy: widget.busy,
          primaryLabel: 'Continue',
          onPrimary: widget.busy ? null : () => widget.onSubmit(_password),
          onCancel: widget.onCancel,
        ),
      ],
    );
  }
}

class _TwoFactorQrStep extends StatelessWidget {
  const _TwoFactorQrStep({
    required this.setup,
    required this.onContinue,
    required this.onCancel,
  });

  final TwoFactorSetup? setup;
  final VoidCallback? onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final data = setup;
    if (data == null) {
      return const _SettingsInfoBanner(
        message: 'Start setup again to receive a new authenticator secret.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsFormLabel(
          label: 'Scan QR Code',
          detail:
              'Scan the QR code with an authenticator app, or enter the secret manually.',
        ),
        _TwoFactorQrImage(qrDataUrl: data.qrDataUrl),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border.all(color: colors.borderStrong),
            borderRadius: VerdantRadii.sharp,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SelectableText(
              data.secret,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SettingsFormActions(
          busy: false,
          primaryLabel: "I've scanned the code",
          onPrimary: onContinue == null ? null : () async => onContinue!(),
          onCancel: onCancel,
        ),
      ],
    );
  }
}

class _TwoFactorQrImage extends StatelessWidget {
  const _TwoFactorQrImage({required this.qrDataUrl});

  final String qrDataUrl;

  @override
  Widget build(BuildContext context) {
    final comma = qrDataUrl.indexOf(',');
    Uint8List? bytes;
    if (comma > -1) {
      try {
        bytes = base64Decode(qrDataUrl.substring(comma + 1));
      } catch (_) {
        bytes = null;
      }
    }
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: VerdantRadii.sharp,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: bytes == null
              ? const SizedBox(
                  width: 148,
                  height: 148,
                  child: Center(
                    child: Icon(Icons.qr_code_2, size: 72, color: Colors.black),
                  ),
                )
              : Image.memory(bytes, width: 148, height: 148),
        ),
      ),
    );
  }
}

class _TwoFactorCodeForm extends StatelessWidget {
  const _TwoFactorCodeForm({
    required this.keyPrefix,
    required this.label,
    required this.detail,
    required this.code,
    required this.busy,
    required this.primaryLabel,
    required this.onCodeChanged,
    required this.onPrimary,
    required this.onCancel,
  });

  final String keyPrefix;
  final String label;
  final String detail;
  final String code;
  final bool busy;
  final String primaryLabel;
  final ValueChanged<String> onCodeChanged;
  final Future<void> Function()? onPrimary;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsFormLabel(label: label, detail: detail),
        TextField(
          key: ValueKey('$keyPrefix-code-field'),
          enabled: !busy,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          onChanged: (value) {
            onCodeChanged(value.replaceAll(RegExp(r'\D'), '').trim());
          },
          decoration: const InputDecoration(
            counterText: '',
            hintText: '000000',
          ),
        ),
        const SizedBox(height: 10),
        _SettingsFormActions(
          busy: busy,
          primaryLabel: primaryLabel,
          onPrimary: onPrimary,
          onCancel: onCancel,
        ),
      ],
    );
  }
}

class _TwoFactorPasswordCodeForm extends StatelessWidget {
  const _TwoFactorPasswordCodeForm({
    required this.keyPrefix,
    required this.label,
    required this.detail,
    required this.password,
    required this.code,
    required this.busy,
    required this.primaryLabel,
    required this.danger,
    required this.onPasswordChanged,
    required this.onCodeChanged,
    required this.onPrimary,
    required this.onCancel,
  });

  final String keyPrefix;
  final String label;
  final String detail;
  final String password;
  final String code;
  final bool busy;
  final String primaryLabel;
  final bool danger;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onCodeChanged;
  final Future<void> Function()? onPrimary;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsFormLabel(label: label, detail: detail),
        TextField(
          key: ValueKey('$keyPrefix-password-field'),
          enabled: !busy,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: onPasswordChanged,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: ValueKey('$keyPrefix-code-field'),
          enabled: !busy,
          maxLength: 20,
          textAlign: TextAlign.center,
          onChanged: (value) => onCodeChanged(value.trim()),
          decoration: const InputDecoration(
            counterText: '',
            hintText: 'Authenticator or backup code',
          ),
        ),
        const SizedBox(height: 10),
        _SettingsFormActions(
          busy: busy,
          primaryLabel: primaryLabel,
          onPrimary: onPrimary,
          onCancel: onCancel,
        ),
        if (danger) ...[
          const SizedBox(height: 8),
          Text(
            'New sign-ins will no longer require an authenticator code.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF7A9C)),
          ),
        ],
      ],
    );
  }
}

class _TwoFactorBackupCodesStep extends StatelessWidget {
  const _TwoFactorBackupCodesStep({
    required this.backupCodes,
    required this.onDone,
  });

  final List<String> backupCodes;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsFormLabel(
          label: 'Save your backup codes',
          detail:
              'Store these somewhere safe. Each backup code can only be used once.',
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border.all(color: colors.borderStrong),
            borderRadius: VerdantRadii.sharp,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final backupCode in backupCodes)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.panelRaised,
                      border: Border.all(color: colors.border),
                      borderRadius: VerdantRadii.sharp,
                    ),
                    child: SelectableText(
                      backupCode,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SmallSettingsButton(
          label: 'Done',
          icon: Icons.check,
          busy: false,
          onPressed: onDone,
        ),
      ],
    );
  }
}
