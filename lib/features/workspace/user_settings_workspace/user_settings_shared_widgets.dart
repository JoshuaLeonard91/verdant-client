part of 'user_settings_workspace.dart';

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: colors.border),
    );
  }
}

class _StatusSettingsRow extends StatelessWidget {
  const _StatusSettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.positive,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final tone = positive ? colors.accentStrong : colors.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: tone),
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
            color: positive ? colors.actionMuted : colors.panelRaised,
            border: Border.all(
              color: positive ? colors.accent : colors.borderStrong,
            ),
            borderRadius: VerdantRadii.sharp,
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tone,
              fontWeight: VerdantFontWeights.semibold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colors.action,
          activeTrackColor: colors.actionMuted,
          inactiveThumbColor: colors.textMuted,
          inactiveTrackColor: colors.panelHover,
        ),
      ],
    );
  }
}

class _SettingsOptionButton extends StatelessWidget {
  const _SettingsOptionButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox(
      width: 140,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? colors.actionText : colors.text,
          backgroundColor: selected ? colors.action : colors.panelRaised,
          side: BorderSide(
            color: selected ? colors.action : colors.borderStrong,
          ),
          shape: const RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? colors.actionText : colors.text,
            fontWeight: VerdantFontWeights.semibold,
          ),
        ),
      ),
    );
  }
}

class _SettingsInfoBanner extends StatelessWidget {
  const _SettingsInfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.actionMuted,
        border: Border.all(color: colors.action),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: colors.accentStrong),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlySettingsRow extends StatelessWidget {
  const _ReadOnlySettingsRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _SettingsTextValue(label: label, value: value),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: colors.borderStrong),
              borderRadius: VerdantRadii.sharp,
            ),
            child: Text(
              trailing!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _SettingsSelectRow extends StatelessWidget {
  const _SettingsSelectRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final List<_SettingsSelectOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.settingsSectionLabel),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(),
          dropdownColor: colors.panelRaised,
          iconEnabledColor: colors.textMuted,
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              ),
          ],
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ],
    );
  }
}

class _ActionSettingsRow extends StatelessWidget {
  const _ActionSettingsRow({
    required this.label,
    required this.value,
    required this.onPressed,
    this.actionLabel = 'Edit',
    this.multiLine = false,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;
  final String actionLabel;
  final bool multiLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: multiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _SettingsTextValue(
            label: label,
            value: value,
            multiLine: multiLine,
            mutedValue: value == 'Not set' || value == 'No description set',
          ),
        ),
        const SizedBox(width: 12),
        _SmallSettingsButton(
          label: actionLabel,
          icon: Icons.edit_outlined,
          busy: false,
          onPressed: onPressed,
        ),
      ],
    );
  }
}

class _SettingsTextValue extends StatelessWidget {
  const _SettingsTextValue({
    required this.label,
    required this.value,
    this.multiLine = false,
    this.mutedValue = false,
  });

  final String label;
  final String value;
  final bool multiLine;
  final bool mutedValue;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.settingsSectionLabel),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: multiLine ? 4 : 1,
          overflow: multiLine ? TextOverflow.fade : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: mutedValue ? colors.textMuted : colors.text,
          ),
        ),
      ],
    );
  }
}

class _EditableTextSetting extends StatefulWidget {
  const _EditableTextSetting({
    required this.label,
    required this.value,
    required this.maxLength,
    required this.minLines,
    required this.maxLines,
    required this.busy,
    required this.saveLabel,
    required this.onChanged,
    required this.onCancel,
    required this.onSave,
  });

  final String label;
  final String value;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final bool busy;
  final String saveLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  @override
  State<_EditableTextSetting> createState() => _EditableTextSettingState();
}

class _EditableTextSettingState extends State<_EditableTextSetting> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_EditableTextSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = VerdantThemeTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: typography.settingsSectionLabel),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          enabled: !widget.busy,
          onChanged: widget.onChanged,
          decoration: const InputDecoration(counterText: ''),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SmallSettingsButton(
              label: widget.saveLabel,
              icon: Icons.check,
              busy: widget.busy,
              onPressed: widget.busy ? null : () => widget.onSave(),
            ),
            _SmallSettingsButton(
              label: 'Cancel',
              icon: Icons.close,
              busy: false,
              onPressed: widget.busy ? null : widget.onCancel,
            ),
          ],
        ),
      ],
    );
  }
}

class _EmailChangeForm extends StatelessWidget {
  const _EmailChangeForm({
    required this.currentEmail,
    required this.newEmail,
    required this.password,
    required this.code,
    required this.confirming,
    required this.has2fa,
    required this.busy,
    required this.onCurrentEmailChanged,
    required this.onNewEmailChanged,
    required this.onPasswordChanged,
    required this.onCodeChanged,
    required this.onCancel,
    required this.onStart,
    required this.onConfirm,
  });

  final String currentEmail;
  final String newEmail;
  final String password;
  final String code;
  final bool confirming;
  final bool has2fa;
  final bool busy;
  final ValueChanged<String> onCurrentEmailChanged;
  final ValueChanged<String> onNewEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onCancel;
  final Future<void> Function() onStart;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    if (confirming) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsFormLabel(
            label: 'Verify Email Change',
            detail: has2fa
                ? 'Enter the email code or your authenticator code.'
                : 'Enter the code sent to your current email.',
          ),
          TextField(
            key: const ValueKey('account-email-code-field'),
            enabled: !busy,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: onCodeChanged,
            decoration: const InputDecoration(
              counterText: '',
              hintText: '000000',
            ),
          ),
          const SizedBox(height: 10),
          _SettingsFormActions(
            busy: busy,
            primaryLabel: 'Confirm Change',
            onPrimary: code.trim().length < 6 || busy ? null : onConfirm,
            onCancel: onCancel,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsFormLabel(
          label: 'Change Email',
          detail: 'A verification code will be sent to your current email.',
        ),
        TextField(
          key: const ValueKey('account-current-email-field'),
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          onChanged: onCurrentEmailChanged,
          decoration: const InputDecoration(hintText: 'Current email address'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('account-new-email-field'),
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          onChanged: onNewEmailChanged,
          decoration: const InputDecoration(hintText: 'New email address'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('account-email-password-field'),
          enabled: !busy,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: onPasswordChanged,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        const SizedBox(height: 10),
        _SettingsFormActions(
          busy: busy,
          primaryLabel: 'Send Verification Code',
          onPrimary:
              currentEmail.trim().isEmpty ||
                  newEmail.trim().isEmpty ||
                  password.isEmpty ||
                  busy
              ? null
              : onStart,
          onCancel: onCancel,
        ),
      ],
    );
  }
}

class _PasswordChangeForm extends StatelessWidget {
  const _PasswordChangeForm({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.showCurrentPassword,
    required this.showNewPassword,
    required this.busy,
    required this.onCurrentPasswordChanged,
    required this.onNewPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onCancel,
    required this.onChangePassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final bool showCurrentPassword;
  final bool showNewPassword;
  final bool busy;
  final ValueChanged<String> onCurrentPasswordChanged;
  final ValueChanged<String> onNewPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onCancel;
  final Future<void> Function() onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsFormLabel(
          label: 'Change Password',
          detail:
              'Changing your password may require other sessions to sign in again.',
        ),
        TextField(
          key: const ValueKey('account-current-password-field'),
          enabled: !busy,
          obscureText: !showCurrentPassword,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: onCurrentPasswordChanged,
          decoration: InputDecoration(
            hintText: 'Current password',
            suffixIcon: IconButton(
              tooltip: showCurrentPassword ? 'Hide password' : 'Show password',
              onPressed: onToggleCurrentPassword,
              icon: Icon(
                showCurrentPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('account-new-password-field'),
          enabled: !busy,
          obscureText: !showNewPassword,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: onNewPasswordChanged,
          decoration: InputDecoration(
            hintText: 'New password',
            suffixIcon: IconButton(
              tooltip: showNewPassword ? 'Hide password' : 'Show password',
              onPressed: onToggleNewPassword,
              icon: Icon(
                showNewPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('account-confirm-password-field'),
          enabled: !busy,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: onConfirmPasswordChanged,
          decoration: const InputDecoration(hintText: 'Confirm new password'),
        ),
        const SizedBox(height: 10),
        _SettingsFormActions(
          busy: busy,
          primaryLabel: 'Change Password',
          onPrimary:
              currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty ||
                  busy
              ? null
              : onChangePassword,
          onCancel: onCancel,
        ),
      ],
    );
  }
}

class _SettingsFormLabel extends StatelessWidget {
  const _SettingsFormLabel({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final typography = VerdantThemeTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: typography.settingsSectionLabel),
          const SizedBox(height: 5),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SettingsFormActions extends StatelessWidget {
  const _SettingsFormActions({
    required this.busy,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onCancel,
    this.primaryKey,
  });

  final bool busy;
  final String primaryLabel;
  final Future<void> Function()? onPrimary;
  final VoidCallback onCancel;
  final Key? primaryKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SmallSettingsButton(
          key: primaryKey,
          label: primaryLabel,
          icon: Icons.check,
          busy: busy,
          onPressed: onPrimary == null ? null : () => onPrimary!(),
        ),
        _SmallSettingsButton(
          label: 'Cancel',
          icon: Icons.close,
          busy: false,
          onPressed: busy ? null : onCancel,
        ),
      ],
    );
  }
}

class _ProfileBannerFallback extends StatelessWidget {
  const _ProfileBannerFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.66),
            colors.panelHover.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

Color _profileVisualColorFor(String name) {
  const palette = [
    Color(0xFFE94560),
    Color(0xFF0F3460),
    Color(0xFF43B581),
    Color(0xFFFAA61A),
    Color(0xFF7289DA),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE74C3C),
    Color(0xFF3498DB),
  ];
  var hash = 0;
  for (final codeUnit in name.codeUnits) {
    hash = codeUnit + ((hash << 5) - hash);
  }
  return palette[hash.abs() % palette.length];
}

Color? _profileHexColor(String? value) {
  if (value == null || !value.startsWith('#') || value.length != 7) {
    return null;
  }
  final parsed = int.tryParse(value.substring(1), radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}

int _colorToArgbInt(Color color) => color.toARGB32();

String _colorToProfileHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontWeight: VerdantFontWeights.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.actionMuted,
              border: Border.all(color: colors.accent),
              borderRadius: VerdantRadii.sharp,
            ),
            child: Text(
              trailing!,
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

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colors.textMuted,
        fontWeight: VerdantFontWeights.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _AccessibilityScaleCard extends StatelessWidget {
  const _AccessibilityScaleCard({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final normalized = normalizeWorkspaceTextScale(value);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workspace Text Size',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a fixed workspace scale for chat, side panels, DMs, settings, and user surfaces. The server rail keeps its fixed density.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in workspaceTextScaleOptions)
                  _ScaleOptionButton(
                    option: option,
                    selected: option.value == normalized,
                    onPressed: () => onChanged(option.value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleOptionButton extends StatelessWidget {
  const _ScaleOptionButton({
    required this.option,
    required this.selected,
    required this.onPressed,
  });

  final WorkspaceTextScaleOption option;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox(
      width: 92,
      height: 42,
      child: OutlinedButton(
        key: ValueKey('accessibility-text-scale-${option.label}'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? colors.actionText : colors.text,
          backgroundColor: selected ? colors.action : colors.panelRaised,
          side: BorderSide(
            color: selected ? colors.action : colors.borderStrong,
          ),
          shape: const RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
        ),
        child: Text(
          option.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? colors.actionText : colors.text,
            fontWeight: VerdantFontWeights.semibold,
          ),
        ),
      ),
    );
  }
}

class _MemberListBannerCard extends StatelessWidget {
  const _MemberListBannerCard({
    required this.currentUser,
    required this.mediaPolicy,
    required this.enabled,
    required this.imageUploadsEnabled,
    required this.canManage,
    required this.bannerUrl,
    required this.bannerCrop,
    required this.busyAction,
    required this.error,
    required this.onSelect,
    required this.onPosition,
    required this.onRemove,
  });

  final VerdantUser currentUser;
  final ServerMediaPolicy mediaPolicy;
  final bool enabled;
  final bool imageUploadsEnabled;
  final bool canManage;
  final String? bannerUrl;
  final BannerCrop? bannerCrop;
  final String? busyAction;
  final String? error;
  final VoidCallback onSelect;
  final VoidCallback onPosition;
  final VoidCallback onRemove;

  bool get _hasBanner => bannerUrl != null;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member List Banner',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'A compact banner behind your name in Active and All Members lists.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!enabled || !imageUploadsEnabled) ...[
              const SizedBox(height: 8),
              Text(
                !enabled
                    ? 'Disabled by the current network entitlements.'
                    : 'Image uploads are disabled on this network.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFFC15E),
                  fontWeight: VerdantFontWeights.bold,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _MemberListBannerPreview(
              currentUser: currentUser,
              mediaPolicy: mediaPolicy,
              enabled: enabled,
              bannerUrl: bannerUrl,
              bannerCrop: bannerCrop,
            ),
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
                  key: const ValueKey('member-list-banner-add-button'),
                  label: _hasBanner
                      ? 'Replace Member List Banner'
                      : 'Add Member List Banner',
                  icon: Icons.upload_outlined,
                  busy: busyAction == 'upload',
                  onPressed: canManage ? onSelect : null,
                ),
                _SmallSettingsButton(
                  key: const ValueKey('member-list-banner-position-button'),
                  label: 'Position',
                  icon: Icons.open_with,
                  busy: busyAction == 'position',
                  onPressed: canManage && _hasBanner ? onPosition : null,
                ),
                if (_hasBanner)
                  _SmallSettingsButton(
                    key: const ValueKey('member-list-banner-remove-button'),
                    label: 'Remove',
                    icon: Icons.delete_outline,
                    busy: busyAction == 'remove',
                    onPressed: canManage ? onRemove : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberListBannerPreview extends StatelessWidget {
  const _MemberListBannerPreview({
    required this.currentUser,
    required this.mediaPolicy,
    required this.enabled,
    required this.bannerUrl,
    required this.bannerCrop,
  });

  final VerdantUser currentUser;
  final ServerMediaPolicy mediaPolicy;
  final bool enabled;
  final String? bannerUrl;
  final BannerCrop? bannerCrop;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final bannerUri = safeServerMediaUri(bannerUrl, policy: mediaPolicy);
    return SizedBox(
      height: 66,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border.all(color: colors.borderStrong),
          borderRadius: VerdantRadii.sharp,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bannerUri != null)
              SafeServerMediaImage(
                uri: bannerUri,
                policy: mediaPolicy,
                surface: ServerMediaSurface.image,
                retainWhenUnfocused: true,
                fallback: const SizedBox.shrink(),
                builder: (context, imageProvider) {
                  return CroppedServerBannerImage(
                    imageProvider: imageProvider,
                    crop: bannerCrop,
                  );
                },
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: bannerUri == null ? 0 : 0.38,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ServerMediaIcon(
                    name: currentUser.displayLabel,
                    iconUrl: currentUser.avatarUrl,
                    mediaPolicy: mediaPolicy,
                    size: 40,
                    animate: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          enabled
                              ? bannerUri == null
                                    ? 'No banner selected'
                                    : 'Visible in member lists'
                              : 'Disabled on this instance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.message});

  final String message;
  static const _errorColor = Color(0xFFFF7A9C);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _errorColor.withValues(alpha: 0.12),
        border: Border.all(color: _errorColor),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: _errorColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSuccess extends StatelessWidget {
  const _SettingsSuccess({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.actionMuted,
        border: Border.all(color: colors.action),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: colors.accentStrong,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallSettingsButton extends StatelessWidget {
  const _SmallSettingsButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220, minHeight: 36),
      child: OutlinedButton(
        onPressed: busy ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
