part of 'workspace_shell.dart';

enum _NetworkAuthMode { signIn, register }

enum _NetworkSignInStep { credentials, twoFactor, verification }

final class _NetworkAuthDialogResult {
  const _NetworkAuthDialogResult({required this.mode, required this.user});

  final _NetworkAuthMode mode;
  final VerdantUser user;
}

class _NetworkSignInDialog extends StatefulWidget {
  const _NetworkSignInDialog({
    required this.networkName,
    required this.apiOrigin,
    required this.initialMode,
    required this.authService,
    required this.instanceMetadataService,
    required this.credentialStore,
  });

  final String networkName;
  final String apiOrigin;
  final _NetworkAuthMode initialMode;
  final AuthService authService;
  final InstanceMetadataService instanceMetadataService;
  final AuthCredentialStore credentialStore;

  @override
  State<_NetworkSignInDialog> createState() => _NetworkSignInDialogState();
}

class _NetworkSignInDialogState extends State<_NetworkSignInDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  late _NetworkAuthMode _mode;
  var _step = _NetworkSignInStep.credentials;
  var _busy = false;
  var _legalAccepted = false;
  String? _error;
  String? _twoFactorTicket;
  String? _verificationSessionToken;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final isCodeStep = _step != _NetworkSignInStep.credentials;
    final isRegister = _mode == _NetworkAuthMode.register && !isCodeStep;
    final title = switch (_step) {
      _NetworkSignInStep.credentials =>
        isRegister
            ? 'Create account on ${widget.networkName}'
            : 'Sign in to ${widget.networkName}',
      _NetworkSignInStep.twoFactor => 'Enter two-factor code',
      _NetworkSignInStep.verification => 'Enter verification code',
    };
    final submitLabel = switch (_step) {
      _NetworkSignInStep.credentials =>
        isRegister ? 'Create Account' : 'Sign In',
      _NetworkSignInStep.twoFactor => 'Verify',
      _NetworkSignInStep.verification => 'Verify',
    };
    final submitKey = isRegister
        ? const ValueKey('network-register-submit')
        : const ValueKey('network-signin-submit');

    final maxDialogHeight = (MediaQuery.sizeOf(context).height - 48)
        .clamp(320.0, 680.0)
        .toDouble();

    return Dialog(
      key: const ValueKey('network-auth-dialog'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: maxDialogHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.borderStrong),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.actionMuted,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.actionHover),
                          ),
                          child: PhosphorIcon(
                            isRegister
                                ? PhosphorIconsRegular.userCirclePlus
                                : PhosphorIconsRegular.signIn,
                            size: 22,
                            color: colors.action,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: colors.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.background,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Text(
                                  widget.apiOrigin,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!isCodeStep) ...[
                      const SizedBox(height: 18),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            _authModeButton(
                              key: const ValueKey(
                                'network-register-show-signin',
                              ),
                              label: 'Sign in',
                              selected: !isRegister,
                              onPressed: _busy
                                  ? null
                                  : () => _switchMode(_NetworkAuthMode.signIn),
                            ),
                            const SizedBox(width: 4),
                            _authModeButton(
                              key: const ValueKey(
                                'network-signin-show-register',
                              ),
                              label: 'Create account',
                              selected: isRegister,
                              onPressed: _busy
                                  ? null
                                  : () =>
                                        _switchMode(_NetworkAuthMode.register),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (!isCodeStep) ...[
                      TextField(
                        key: ValueKey(
                          isRegister
                              ? 'network-register-email-field'
                              : 'network-signin-email-field',
                        ),
                        controller: _emailController,
                        enabled: !_busy,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _authInputDecoration(
                          context,
                          label: 'Email',
                          hint: 'you@example.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: ValueKey(
                          isRegister
                              ? 'network-register-password-field'
                              : 'network-signin-password-field',
                        ),
                        controller: _passwordController,
                        enabled: !_busy,
                        autocorrect: false,
                        enableSuggestions: false,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: _authInputDecoration(
                          context,
                          label: 'Password',
                          hint: 'Enter password',
                        ),
                      ),
                      if (isRegister) ...[
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey(
                            'network-register-confirm-password-field',
                          ),
                          controller: _confirmPasswordController,
                          enabled: !_busy,
                          autocorrect: false,
                          enableSuggestions: false,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: _authInputDecoration(
                            context,
                            label: 'Confirm password',
                            hint: 'Repeat password',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _legalConsentRow(context),
                      ],
                    ] else
                      TextField(
                        key: const ValueKey('network-signin-code-field'),
                        controller: _codeController,
                        enabled: !_busy,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: _authInputDecoration(
                          context,
                          label: 'Code',
                          hint: '000000',
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF451A1F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF7F1D1D)),
                        ),
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFFFFB4BD)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        FilledButton(
                          key: submitKey,
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(114, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(submitLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authModeButton({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback? onPressed,
  }) {
    final colors = VerdantThemeColors.of(context);
    return Expanded(
      child: Material(
        key: key,
        color: selected ? colors.actionMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: selected ? null : onPressed,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? colors.action : colors.textMuted,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _authInputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
  }) {
    final colors = VerdantThemeColors.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: colors.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.action, width: 1.3),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
    );
  }

  Widget _legalConsentRow(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const ValueKey('network-register-legal-checkbox'),
        borderRadius: BorderRadius.circular(12),
        onTap: _busy
            ? null
            : () {
                setState(() {
                  _legalAccepted = !_legalAccepted;
                  if (_legalAccepted) {
                    _error = null;
                  }
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: _legalAccepted,
                  onChanged: _busy
                      ? null
                      : (value) {
                          setState(() {
                            _legalAccepted = value ?? false;
                            if (_legalAccepted) {
                              _error = null;
                            }
                          });
                        },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'I accept the Terms and Privacy Policy for this network.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final outcome = switch (_step) {
        _NetworkSignInStep.credentials =>
          _mode == _NetworkAuthMode.register
              ? await _register()
              : await widget.authService.login(
                  apiOrigin: widget.apiOrigin,
                  email: sanitizeEmailInput(_emailController.text),
                  password: _passwordController.text,
                ),
        _NetworkSignInStep.twoFactor =>
          await widget.authService.submitTwoFactor(
            apiOrigin: widget.apiOrigin,
            ticket: _twoFactorTicket ?? '',
            code: _codeController.text,
          ),
        _NetworkSignInStep.verification =>
          await widget.authService.verifySession(
            apiOrigin: widget.apiOrigin,
            sessionToken: _verificationSessionToken ?? '',
            code: _codeController.text,
          ),
      };
      await _applyOutcome(outcome);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _mode == _NetworkAuthMode.register
              ? 'Network account creation failed'
              : 'Network sign-in failed';
        });
      }
    }
  }

  Future<AuthLoginOutcome> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      throw const AuthException('Passwords do not match');
    }
    if (!_legalAccepted) {
      throw const AuthException(
        'Review and accept Terms and Privacy before creating an account',
      );
    }
    final registrationPolicy = await widget.instanceMetadataService
        .fetchRegistrationPolicy(apiOrigin: widget.apiOrigin);
    if (!registrationPolicy.allowsAccountCreation) {
      throw AuthException(_accountCreationBlockedMessage(registrationPolicy));
    }
    return widget.authService.register(
      apiOrigin: widget.apiOrigin,
      email: sanitizeEmailInput(_emailController.text),
      password: _passwordController.text,
      termsAccepted: _legalAccepted,
      privacyAccepted: _legalAccepted,
    );
  }

  void _switchMode(_NetworkAuthMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
      _error = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _codeController.clear();
      _legalAccepted = false;
      _twoFactorTicket = null;
      _verificationSessionToken = null;
    });
  }

  Future<void> _applyOutcome(AuthLoginOutcome outcome) async {
    final normalizedOrigin = normalizeBackendApiOrigin(widget.apiOrigin);
    switch (outcome) {
      case AuthLoginSuccess(:final session, :final credentials):
        if (session.apiOrigin != normalizedOrigin ||
            credentials.normalizedApiOrigin != normalizedOrigin) {
          throw const AuthException('Auth response targeted another network');
        }
        await widget.credentialStore.save(credentials.withUser(session.user));
        if (mounted) {
          Navigator.of(
            context,
          ).pop(_NetworkAuthDialogResult(mode: _mode, user: session.user));
        }
      case AuthLoginRequiresTwoFactor(:final ticket):
        if (ticket.trim().isEmpty) {
          throw const AuthException('Two-factor challenge was missing');
        }
        if (mounted) {
          setState(() {
            _step = _NetworkSignInStep.twoFactor;
            _twoFactorTicket = ticket;
            _verificationSessionToken = null;
            _codeController.clear();
            _busy = false;
          });
        }
      case AuthLoginRequiresVerification(:final sessionToken):
        if (sessionToken.trim().isEmpty) {
          throw const AuthException('Verification session was missing');
        }
        if (mounted) {
          setState(() {
            _step = _NetworkSignInStep.verification;
            _verificationSessionToken = sessionToken;
            _twoFactorTicket = null;
            _codeController.clear();
            _busy = false;
          });
        }
    }
  }
}

class _NetworkUsernameDialog extends StatefulWidget {
  const _NetworkUsernameDialog({
    required this.networkName,
    required this.apiOrigin,
  });

  final String networkName;
  final String apiOrigin;

  @override
  State<_NetworkUsernameDialog> createState() => _NetworkUsernameDialogState();
}

class _NetworkUsernameDialogState extends State<_NetworkUsernameDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return AlertDialog(
      backgroundColor: colors.panel,
      title: const Text('Choose username'),
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.networkName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.apiOrigin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('network-username-field'),
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Letters, numbers, and underscores',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This username belongs only to this network.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF808A)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        FilledButton(
          key: const ValueKey('network-username-submit'),
          onPressed: _submit,
          child: const Text('Save Username'),
        ),
      ],
    );
  }

  void _submit() {
    final username = sanitizeUsernameInput(_controller.text, maxLength: 32);
    if (username.isEmpty) {
      setState(() => _error = 'Enter a username');
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(username)) {
      setState(
        () => _error =
            'Username may only contain letters, numbers, and underscores',
      );
      return;
    }
    Navigator.of(context).pop(username);
  }
}

String _accountCreationBlockedMessage(InstanceRegistrationPolicy policy) {
  return switch (policy) {
    InstanceRegistrationPolicy.invite =>
      'This network is invite-only for new accounts',
    InstanceRegistrationPolicy.disabled =>
      'Account creation is disabled on this network',
    InstanceRegistrationPolicy.unknown =>
      'Could not check account creation for this network',
    InstanceRegistrationPolicy.public => 'Account creation failed',
  };
}

List<MemberSeed> _mergeChatMembers(
  List<MemberSeed> serverMembers,
  List<MemberSeed> activeMembers,
) {
  if (activeMembers.isEmpty) {
    return serverMembers;
  }
  final merged = <MemberSeed>[];
  final unkeyed = <MemberSeed>[];

  for (final member in activeMembers) {
    if (_chatMemberIdParts(member.id) == null) {
      unkeyed.add(member);
      continue;
    }
    final existingIndex = _chatMemberMergeIndex(merged, member);
    if (existingIndex < 0) {
      merged.add(member);
    } else {
      merged[existingIndex] = _mergeChatMemberProfile(
        merged[existingIndex],
        member,
      );
    }
  }

  for (final member in serverMembers) {
    if (_chatMemberIdParts(member.id) == null) {
      unkeyed.add(member);
      continue;
    }
    final existingIndex = _chatMemberMergeIndex(merged, member);
    if (existingIndex < 0) {
      merged.add(member);
    } else {
      merged[existingIndex] = _mergeChatMemberProfile(
        merged[existingIndex],
        member,
      );
    }
  }

  return [...merged, ...unkeyed];
}

MemberSeed _mergeChatMemberProfile(MemberSeed active, MemberSeed server) {
  return active.copyWith(
    id: _preferredChatMemberId(active.id, server.id),
    name: _preferredChatMemberName(active.name, server.name),
    username:
        _nonEmptyChatMemberText(active.username) ??
        _nonEmptyChatMemberText(server.username),
    status:
        _nonEmptyChatMemberText(active.status) ??
        _nonEmptyChatMemberText(server.status) ??
        active.status,
    initials: _nonEmptyChatMemberText(active.initials) ?? server.initials,
    role: active.role == 'Member' ? server.role : active.role,
    roleIds: active.roleIds.isNotEmpty ? active.roleIds : server.roleIds,
    displayColor: active.displayColor ?? server.displayColor,
    avatarUrl: active.avatarUrl ?? server.avatarUrl,
    bannerUrl: active.bannerUrl ?? server.bannerUrl,
    bannerBaseColor: active.bannerBaseColor ?? server.bannerBaseColor,
    bannerCrop: active.bannerCrop ?? server.bannerCrop,
    memberListBannerUrl:
        active.memberListBannerUrl ?? server.memberListBannerUrl,
    memberListBannerCrop:
        active.memberListBannerCrop ?? server.memberListBannerCrop,
    lastMessageAt: active.lastMessageAt ?? server.lastMessageAt,
    isActive: active.isActive,
  );
}

int _chatMemberMergeIndex(List<MemberSeed> members, MemberSeed candidate) {
  for (var index = 0; index < members.length; index += 1) {
    if (_chatMemberIdsMatch(members[index].id, candidate.id)) {
      return index;
    }
  }
  return -1;
}

bool _chatMemberIdsMatch(String? left, String? right) {
  final leftId = _nonEmptyChatMemberText(left);
  final rightId = _nonEmptyChatMemberText(right);
  if (leftId == null || rightId == null) {
    return false;
  }
  if (leftId == rightId) {
    return true;
  }
  final leftParts = _chatMemberIdParts(leftId);
  final rightParts = _chatMemberIdParts(rightId);
  if (leftParts == null || rightParts == null) {
    return false;
  }
  if (leftParts.localId != rightParts.localId) {
    return false;
  }
  final leftNetworkId = leftParts.networkId;
  final rightNetworkId = rightParts.networkId;
  if (leftNetworkId == null || rightNetworkId == null) {
    return true;
  }
  return sameWorkspaceNetworkId(leftNetworkId, rightNetworkId);
}

String? _preferredChatMemberId(String? activeId, String? serverId) {
  final active = _nonEmptyChatMemberText(activeId);
  final server = _nonEmptyChatMemberText(serverId);
  if (active == null) {
    return server;
  }
  if (server == null || active == server) {
    return active;
  }
  final activeParts = _chatMemberIdParts(active);
  final serverParts = _chatMemberIdParts(server);
  if (activeParts == null || serverParts == null) {
    return active;
  }
  if (activeParts.localId == serverParts.localId &&
      activeParts.networkId == null &&
      serverParts.networkId != null) {
    return server;
  }
  return active;
}

({String? networkId, String localId})? _chatMemberIdParts(String? id) {
  final trimmed = _nonEmptyChatMemberText(id);
  if (trimmed == null) {
    return null;
  }
  final slash = trimmed.indexOf('/');
  if (slash > 0 &&
      slash < trimmed.length - 1 &&
      trimmed.indexOf('/', slash + 1) < 0) {
    final networkId = trimmed.substring(0, slash).trim();
    final localId = trimmed.substring(slash + 1).trim();
    if (networkId.isNotEmpty) {
      try {
        return (networkId: networkId, localId: safeWorkspaceLocalId(localId));
      } on FormatException {
        return null;
      }
    }
  }
  try {
    return (networkId: null, localId: safeWorkspaceLocalId(trimmed));
  } on FormatException {
    return null;
  }
}

List<MemberSeed> debugMergeChatMembersForTesting(
  List<MemberSeed> serverMembers,
  List<MemberSeed> activeMembers,
) {
  return _mergeChatMembers(serverMembers, activeMembers);
}

String _preferredChatMemberName(String activeName, String serverName) {
  final active = _nonEmptyChatMemberText(activeName);
  if (active != null && !_looksLikeChatMemberBackendId(active)) {
    return active;
  }
  final server = _nonEmptyChatMemberText(serverName);
  if (server != null && !_looksLikeChatMemberBackendId(server)) {
    return server;
  }
  return active ?? server ?? activeName;
}

String? _nonEmptyChatMemberText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

bool _looksLikeChatMemberBackendId(String value) {
  final trimmed = value.trim();
  return RegExp(r'^\d{12,}$').hasMatch(trimmed) ||
      RegExp(r'^user[_-]?\d{6,}$', caseSensitive: false).hasMatch(trimmed);
}

String _selectedChannelName(WorkspaceSeed seed) {
  for (final channel in seed.channels) {
    if (channel.selected) {
      return channel.name;
    }
  }
  return 'general';
}
