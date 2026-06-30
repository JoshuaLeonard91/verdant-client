import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/smooth_single_child_scroll_view.dart';
import '../../shared/verdant_input_sanitizer.dart';
import '../../theme/verdant_assets.dart';
import '../../theme/verdant_button.dart';
import '../../theme/verdant_theme.dart';
import '../workspace/server_settings_workspace/federated_membership_service.dart';
import 'auth_controller.dart';
import 'auth_credentials.dart';
import 'auth_diagnostics.dart';
import 'auth_models.dart';
import 'auth_service.dart';
import 'instance_identity.dart';
import 'instance_identity_service.dart';
import 'instance_metadata_service.dart';
import 'network_profile_store.dart';

typedef AuthenticatedWorkspaceBuilder =
    Widget Function(
      BuildContext context,
      AuthSession session,
      VoidCallback onLogout,
      Future<NetworkSessionActivationResult> Function({
        required String apiOrigin,
        String? initialServerId,
      })
      onActivateNetwork,
      String? initialServerId,
    );

enum _AuthPanelMode { signIn, register, networkList, addNetwork }

const _federatedCredentialRefreshSkew = Duration(seconds: 30);

class LoginWorkspace extends StatefulWidget {
  const LoginWorkspace({
    super.key,
    required this.authService,
    required this.authenticatedBuilder,
    this.credentialStore,
    this.networkProfileStore,
    this.instanceMetadataService,
    this.instanceIdentityStore,
    this.instanceIdentityManifestService,
    this.federatedMembershipRepositoryFactory,
    this.diagnostics,
    this.profileBadgeLabel,
  });

  final AuthService authService;
  final AuthCredentialStore? credentialStore;
  final NetworkProfileStore? networkProfileStore;
  final InstanceMetadataService? instanceMetadataService;
  final InstanceIdentityStore? instanceIdentityStore;
  final InstanceIdentityManifestService? instanceIdentityManifestService;
  final FederatedMembershipRepository Function(String apiOrigin)?
  federatedMembershipRepositoryFactory;
  final AuthDiagnostics? diagnostics;
  final String? profileBadgeLabel;
  final AuthenticatedWorkspaceBuilder authenticatedBuilder;

  @override
  State<LoginWorkspace> createState() => _LoginWorkspaceState();
}

class _LoginWorkspaceState extends State<LoginWorkspace> {
  late final LoginController _controller;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final _networkNameController = TextEditingController();
  final _networkOriginController = TextEditingController();
  bool _showPassword = false;
  bool _showRegisterPassword = false;
  bool _legalAccepted = false;
  _AuthPanelMode _panelMode = _AuthPanelMode.signIn;
  String? _registerFormError;
  String? _networkFormError;
  String? _pendingInitialServerApiOrigin;
  String? _pendingInitialServerId;
  String? _lastAuthGateDiagnosticSignature;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(
      authService: widget.authService,
      credentialStore: widget.credentialStore,
      networkProfileStore: widget.networkProfileStore,
      instanceMetadataService: widget.instanceMetadataService,
      instanceIdentityStore:
          widget.instanceIdentityStore ?? InstanceIdentityStore(),
      instanceIdentityManifestService:
          widget.instanceIdentityManifestService ??
          HttpInstanceIdentityManifestService(),
      diagnostics: widget.diagnostics,
    );
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _codeController.dispose();
    _networkNameController.dispose();
    _networkOriginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final session = _controller.session;
        _recordAuthGate(session);
        if (session != null) {
          final initialServerId =
              session.apiOrigin == _pendingInitialServerApiOrigin
              ? _pendingInitialServerId
              : null;
          return widget.authenticatedBuilder(
            context,
            session,
            _handleLogout,
            _activateNetworkSession,
            initialServerId,
          );
        }

        return _LoginSurface(
          controller: _controller,
          emailController: _emailController,
          passwordController: _passwordController,
          registerEmailController: _registerEmailController,
          registerPasswordController: _registerPasswordController,
          registerConfirmPasswordController: _registerConfirmPasswordController,
          codeController: _codeController,
          networkNameController: _networkNameController,
          networkOriginController: _networkOriginController,
          mode: _panelMode,
          registerFormError: _registerFormError,
          networkFormError: _networkFormError,
          showPassword: _showPassword,
          showRegisterPassword: _showRegisterPassword,
          legalAccepted: _legalAccepted,
          onTogglePassword: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
          onToggleRegisterPassword: () {
            setState(() {
              _showRegisterPassword = !_showRegisterPassword;
            });
          },
          onToggleLegalAccepted: (value) {
            setState(() {
              _legalAccepted = value;
              if (value) {
                _registerFormError = null;
              }
            });
          },
          onSubmitCredentials: _submitCredentials,
          onSubmitRegistration: _submitRegistration,
          onSubmitCode: _submitCode,
          onShowRegister: _showRegister,
          onShowNetworks: _showNetworkList,
          onShowAddNetwork: _showAddNetwork,
          onSelectNetwork: _selectNetwork,
          onCancelNetworkFlow: _showSignIn,
          onSaveNetwork: _saveNetwork,
          profileBadgeLabel: widget.profileBadgeLabel,
        );
      },
    );
  }

  void _recordAuthGate(AuthSession? session) {
    final signature = [
      session?.networkId ?? 'none',
      session?.credentialKind.wireName ?? 'none',
      _controller.isInitializing,
      _controller.isSubmitting,
      _controller.isActivatingNetworkSession,
      _controller.step.name,
      _controller.error ?? 'none',
      _panelMode.name,
      _controller.selectedNetworkProfile.networkId,
    ].join('|');
    if (signature == _lastAuthGateDiagnosticSignature) {
      return;
    }
    _lastAuthGateDiagnosticSignature = signature;
    widget.diagnostics?.record('auth.gate.render', {
      'surface': session == null
          ? _controller.isInitializing
                ? 'login_initializing'
                : 'login'
          : 'workspace',
      'isInitializing': _controller.isInitializing,
      'isSubmitting': _controller.isSubmitting,
      'isNetworkActivating': _controller.isActivatingNetworkSession,
      'step': _controller.step.name,
      'hasSession': session != null,
      'sessionNetworkId': session?.networkId,
      'sessionApiOrigin': session?.apiOrigin,
      'credentialKind': session?.credentialKind.wireName,
      'selectedNetworkId': _controller.selectedNetworkProfile.networkId,
      'selectedApiOrigin': _controller.selectedNetworkProfile.apiOrigin,
      'panelMode': _panelMode.name,
      'hasError': _controller.error != null,
    });
  }

  Future<void> _submitCredentials() async {
    FocusScope.of(context).unfocus();
    try {
      await _controller.login(
        email: sanitizeEmailInput(_emailController.text),
        password: _passwordController.text,
      );
    } finally {
      if (mounted) {
        _passwordController.clear();
        TextInput.finishAutofillContext(shouldSave: false);
      }
    }
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();
    final password = _registerPasswordController.text;
    final confirm = _registerConfirmPasswordController.text;
    if (password != confirm) {
      setState(() {
        _registerFormError = 'Passwords do not match';
      });
      return;
    }
    if (!_legalAccepted) {
      setState(() {
        _registerFormError =
            'Review and accept Terms and Privacy before creating an account';
      });
      return;
    }

    try {
      await _controller.register(
        email: sanitizeEmailInput(_registerEmailController.text),
        password: password,
        termsAccepted: _legalAccepted,
        privacyAccepted: _legalAccepted,
      );
    } finally {
      if (mounted) {
        _registerPasswordController.clear();
        _registerConfirmPasswordController.clear();
        TextInput.finishAutofillContext(shouldSave: false);
      }
    }
  }

  Future<void> _submitCode() async {
    FocusScope.of(context).unfocus();
    try {
      await _controller.submitCode(_codeController.text);
    } finally {
      if (mounted) {
        _codeController.clear();
        TextInput.finishAutofillContext(shouldSave: false);
      }
    }
  }

  void _showRegister() {
    _clearSecretFields();
    setState(() {
      _registerFormError = null;
      _networkFormError = null;
      _panelMode = _AuthPanelMode.register;
    });
  }

  void _showNetworkList() {
    _clearSecretFields();
    setState(() {
      _registerFormError = null;
      _networkFormError = null;
      _panelMode = _AuthPanelMode.networkList;
    });
  }

  void _showAddNetwork() {
    _clearSecretFields();
    setState(() {
      _networkNameController.clear();
      _networkOriginController.clear();
      _registerFormError = null;
      _networkFormError = null;
      _panelMode = _AuthPanelMode.addNetwork;
    });
  }

  void _showSignIn() {
    setState(() {
      _registerFormError = null;
      _networkFormError = null;
      _panelMode = _AuthPanelMode.signIn;
    });
  }

  Future<void> _selectNetwork(NetworkProfile profile) async {
    await _controller.selectNetworkProfile(profile);
    if (!mounted) {
      return;
    }
    _showSignIn();
  }

  Future<NetworkSessionActivationResult> _activateNetworkSession({
    required String apiOrigin,
    String? initialServerId,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    _pendingInitialServerApiOrigin = normalizedOrigin;
    _pendingInitialServerId = initialServerId;
    AuthCredentialBundle? existingCredentials;
    try {
      existingCredentials = await _controller.credentialStore.read(
        normalizedOrigin,
      );
    } catch (_) {
      existingCredentials = null;
    }
    final hasFederatedCredential =
        existingCredentials?.isFederatedClient == true;
    final shouldRestoreFederatedAccess =
        existingCredentials == null ||
        (hasFederatedCredential &&
            _federatedCredentialNeedsRefresh(existingCredentials));
    var restoredFederatedAccess = false;
    if (shouldRestoreFederatedAccess) {
      restoredFederatedAccess = await _restoreFederatedNetworkAccess(
        targetApiOrigin: normalizedOrigin,
        initialServerId: initialServerId,
      );
      if (hasFederatedCredential && !restoredFederatedAccess) {
        final result = const NetworkSessionActivationResult.unavailable(
          'Federated access could not be restored',
        );
        if (mounted) {
          setState(() {
            _pendingInitialServerApiOrigin = null;
            _pendingInitialServerId = null;
          });
        }
        return result;
      }
    } else if (hasFederatedCredential) {
      _controller.diagnostics.record('federated.access.restore.cached', {
        'targetNetworkId': networkIdFromApiOrigin(normalizedOrigin),
        'targetApiOrigin': normalizedOrigin,
        'expiresAt': existingCredentials.expiresAt?.toUtc().toIso8601String(),
        'refreshSkewMs': _federatedCredentialRefreshSkew.inMilliseconds,
      });
    }

    final result = await _controller.activateNetworkSession(normalizedOrigin);
    if (!mounted) {
      return result;
    }
    if (!result.opened &&
        !restoredFederatedAccess &&
        existingCredentials == null &&
        await _restoreFederatedNetworkAccess(
          targetApiOrigin: normalizedOrigin,
          initialServerId: initialServerId,
        )) {
      final retryResult = await _controller.activateNetworkSession(
        normalizedOrigin,
      );
      if (!mounted) {
        return retryResult;
      }
      if (retryResult.opened) {
        return retryResult;
      }
      setState(() {
        _pendingInitialServerApiOrigin = null;
        _pendingInitialServerId = null;
      });
      return retryResult;
    }
    if (!result.opened) {
      setState(() {
        _pendingInitialServerApiOrigin = null;
        _pendingInitialServerId = null;
      });
    }
    return result;
  }

  bool _federatedCredentialNeedsRefresh(AuthCredentialBundle credentials) {
    if (!credentials.isFederatedClient) {
      return false;
    }
    if (credentials.expiresAt == null) {
      return true;
    }
    return credentials.expiresWithin(_federatedCredentialRefreshSkew);
  }

  Future<bool> _restoreFederatedNetworkAccess({
    required String targetApiOrigin,
    String? initialServerId,
  }) async {
    final targetNetworkId = networkIdFromApiOrigin(targetApiOrigin);
    final homeCandidates = await _federatedHomeAccessCandidates(
      targetApiOrigin: targetApiOrigin,
    );
    if (homeCandidates.isEmpty) {
      _controller.diagnostics.record('federated.access.restore.skip', {
        'targetNetworkId': targetNetworkId,
        'targetApiOrigin': targetApiOrigin,
        'reason': 'no_home_credentials',
      });
      return false;
    }

    _controller.diagnostics.record('federated.access.restore.home_candidates', {
      'targetNetworkId': targetNetworkId,
      'targetApiOrigin': targetApiOrigin,
      'homeCandidateCount': homeCandidates.length,
      'homeCandidateSources': [
        for (final candidate in homeCandidates) candidate.source,
      ],
    });

    for (final homeCandidate in homeCandidates) {
      FederatedMembershipRepository? repository;
      try {
        _controller.diagnostics.record('federated.access.restore.start', {
          'homeNetworkId': homeCandidate.networkId,
          'homeApiOrigin': homeCandidate.apiOrigin,
          'homeSource': homeCandidate.source,
          'targetNetworkId': targetNetworkId,
          'targetApiOrigin': targetApiOrigin,
          'initialServerIdPresent': initialServerId != null,
        });
        repository =
            widget.federatedMembershipRepositoryFactory?.call(
              homeCandidate.apiOrigin,
            ) ??
            HttpFederatedMembershipService(
              apiOrigin: homeCandidate.apiOrigin,
              credentialStore: _controller.credentialStore,
              authService: widget.authService,
            );
        final memberships = await repository.listMemberships();
        final activeTargetMemberships = memberships
            .where(
              (candidate) =>
                  candidate.isActive &&
                  candidate.targetApiOrigin == targetApiOrigin,
            )
            .toList(growable: false);
        _controller.diagnostics.record('federated.access.restore.list.result', {
          'homeNetworkId': homeCandidate.networkId,
          'homeApiOrigin': homeCandidate.apiOrigin,
          'homeSource': homeCandidate.source,
          'targetNetworkId': targetNetworkId,
          'targetApiOrigin': targetApiOrigin,
          'membershipCount': memberships.length,
          'activeTargetMembershipCount': activeTargetMemberships.length,
          'initialServerIdPresent': initialServerId != null,
        });
        FederatedClientMembership? membership;
        for (final candidate in activeTargetMemberships) {
          if (initialServerId != null &&
              candidate.targetServerId != initialServerId) {
            continue;
          }
          membership = candidate;
          break;
        }
        if (membership == null) {
          _controller.diagnostics.record('federated.access.restore.no_match', {
            'homeNetworkId': homeCandidate.networkId,
            'homeApiOrigin': homeCandidate.apiOrigin,
            'homeSource': homeCandidate.source,
            'targetNetworkId': targetNetworkId,
            'targetApiOrigin': targetApiOrigin,
            'activeTargetMembershipCount': activeTargetMemberships.length,
            'initialServerIdPresent': initialServerId != null,
          });
          continue;
        }

        _controller.diagnostics
            .record('federated.access.restore.refresh.start', {
              'homeNetworkId': homeCandidate.networkId,
              'homeApiOrigin': homeCandidate.apiOrigin,
              'homeSource': homeCandidate.source,
              'targetNetworkId': targetNetworkId,
              'targetApiOrigin': targetApiOrigin,
              'targetServerId': membership.targetServerId,
            });
        final capability = await repository.refreshCapability(
          membershipId: membership.id,
        );
        _controller.diagnostics
            .record('federated.access.restore.refresh.result', {
              'homeNetworkId': homeCandidate.networkId,
              'homeApiOrigin': homeCandidate.apiOrigin,
              'homeSource': homeCandidate.source,
              'targetNetworkId': targetNetworkId,
              'targetApiOrigin': targetApiOrigin,
              'targetServerId': membership.targetServerId,
              'capabilityStatus': capability.status.name,
              'serverMatches': capability.serverId == membership.targetServerId,
            });
        if (!capability.isReady ||
            capability.serverId != membership.targetServerId) {
          continue;
        }
        await _controller.credentialStore.save(
          capability.toCredential(targetApiOrigin: membership.targetApiOrigin),
        );
        await _controller.networkProfileStore.saveProfile(
          name: _networkNameForFederatedMembership(membership),
          apiOrigin: membership.targetApiOrigin,
        );
        _controller.diagnostics.record('federated.access.restore.success', {
          'homeNetworkId': homeCandidate.networkId,
          'homeApiOrigin': homeCandidate.apiOrigin,
          'homeSource': homeCandidate.source,
          'targetNetworkId': targetNetworkId,
          'targetApiOrigin': targetApiOrigin,
          'targetServerId': membership.targetServerId,
        });
        return true;
      } on FederatedMembershipException catch (error) {
        _controller.diagnostics.record('federated.access.restore.error', {
          'homeNetworkId': homeCandidate.networkId,
          'homeApiOrigin': homeCandidate.apiOrigin,
          'homeSource': homeCandidate.source,
          'targetNetworkId': targetNetworkId,
          'targetApiOrigin': targetApiOrigin,
          'errorType': error.runtimeType.toString(),
          'statusCode': error.statusCode,
          'code': error.code,
          'isAuthExpired': error.isAuthExpired,
        });
      } catch (error) {
        _controller.diagnostics.record('federated.access.restore.error', {
          'homeNetworkId': homeCandidate.networkId,
          'homeApiOrigin': homeCandidate.apiOrigin,
          'homeSource': homeCandidate.source,
          'targetNetworkId': targetNetworkId,
          'targetApiOrigin': targetApiOrigin,
          'errorType': error.runtimeType.toString(),
        });
      } finally {
        final ownedRepository = repository;
        if (ownedRepository is HttpFederatedMembershipService) {
          ownedRepository.close();
        }
      }
    }
    _controller.diagnostics.record('federated.access.restore.result', {
      'targetNetworkId': targetNetworkId,
      'targetApiOrigin': targetApiOrigin,
      'status': 'not_restored',
      'homeCandidateCount': homeCandidates.length,
    });
    return false;
  }

  Future<List<_FederatedHomeAccessCandidate>> _federatedHomeAccessCandidates({
    required String targetApiOrigin,
  }) async {
    final normalizedTargetOrigin = normalizeBackendApiOrigin(targetApiOrigin);
    final candidates = <_FederatedHomeAccessCandidate>[];
    final seenOrigins = <String>{normalizedTargetOrigin};
    final activeSession = _controller.session;
    if (activeSession != null &&
        activeSession.credentialKind != AuthCredentialKind.federatedClient &&
        seenOrigins.add(activeSession.apiOrigin)) {
      candidates.add(
        _FederatedHomeAccessCandidate(
          networkId: activeSession.networkId,
          apiOrigin: activeSession.apiOrigin,
          source: 'active_session',
        ),
      );
    }

    List<NetworkProfile> profiles;
    try {
      profiles = (await _controller.networkProfileStore.load()).profiles;
    } catch (error) {
      _controller.diagnostics.record('federated.access.restore.home_error', {
        'targetNetworkId': networkIdFromApiOrigin(normalizedTargetOrigin),
        'targetApiOrigin': normalizedTargetOrigin,
        'stage': 'profiles',
        'errorType': error.runtimeType.toString(),
      });
      profiles = const <NetworkProfile>[];
    }

    for (final profile in profiles) {
      final homeApiOrigin = normalizeBackendApiOrigin(profile.apiOrigin);
      if (!seenOrigins.add(homeApiOrigin)) {
        continue;
      }
      AuthCredentialBundle? credentials;
      try {
        credentials = await _controller.credentialStore.read(homeApiOrigin);
      } catch (error) {
        _controller.diagnostics.record('federated.access.restore.home_error', {
          'homeNetworkId': profile.networkId,
          'homeApiOrigin': homeApiOrigin,
          'targetNetworkId': networkIdFromApiOrigin(normalizedTargetOrigin),
          'targetApiOrigin': normalizedTargetOrigin,
          'stage': 'credentials',
          'errorType': error.runtimeType.toString(),
        });
        continue;
      }
      if (credentials == null || credentials.isFederatedClient) {
        _controller.diagnostics.record('federated.access.restore.home_skip', {
          'homeNetworkId': profile.networkId,
          'homeApiOrigin': homeApiOrigin,
          'targetNetworkId': networkIdFromApiOrigin(normalizedTargetOrigin),
          'targetApiOrigin': normalizedTargetOrigin,
          'credentialKind': credentials?.kind.wireName ?? 'none',
        });
        continue;
      }
      candidates.add(
        _FederatedHomeAccessCandidate(
          networkId: profile.networkId,
          apiOrigin: homeApiOrigin,
          source: 'saved_profile',
        ),
      );
    }

    return List.unmodifiable(candidates);
  }

  Future<void> _saveNetwork() async {
    FocusScope.of(context).unfocus();
    try {
      await _controller.addNetworkProfile(
        name: sanitizeDisplayNameInput(_networkNameController.text),
        apiOrigin: sanitizeUrlInput(_networkOriginController.text),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _networkFormError = error.message;
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _networkFormError = 'Could not save this network';
      });
      return;
    }

    if (!mounted) {
      return;
    }
    _showSignIn();
  }

  void _handleLogout() {
    _emailController.clear();
    _registerEmailController.clear();
    _clearSecretFields();
    setState(() {
      _legalAccepted = false;
      _registerFormError = null;
      _networkFormError = null;
      _panelMode = _AuthPanelMode.signIn;
    });
    unawaited(_controller.logout());
  }

  void _clearSecretFields() {
    _passwordController.clear();
    _registerPasswordController.clear();
    _registerConfirmPasswordController.clear();
    _codeController.clear();
  }
}

String _networkNameForFederatedMembership(
  FederatedClientMembership membership,
) {
  try {
    final host = Uri.parse(membership.targetApiOrigin).host;
    return host.isEmpty ? 'Federated Network' : host;
  } catch (_) {
    final serverName = membership.server.name;
    if (serverName != null && serverName.trim().isNotEmpty) {
      return serverName;
    }
  }
  return 'Federated Network';
}

final class _FederatedHomeAccessCandidate {
  const _FederatedHomeAccessCandidate({
    required this.networkId,
    required this.apiOrigin,
    required this.source,
  });

  final String networkId;
  final String apiOrigin;
  final String source;
}

class _LoginSurface extends StatelessWidget {
  const _LoginSurface({
    required this.controller,
    required this.emailController,
    required this.passwordController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.registerConfirmPasswordController,
    required this.codeController,
    required this.networkNameController,
    required this.networkOriginController,
    required this.mode,
    required this.registerFormError,
    required this.networkFormError,
    required this.showPassword,
    required this.showRegisterPassword,
    required this.legalAccepted,
    required this.onTogglePassword,
    required this.onToggleRegisterPassword,
    required this.onToggleLegalAccepted,
    required this.onSubmitCredentials,
    required this.onSubmitRegistration,
    required this.onSubmitCode,
    required this.onShowRegister,
    required this.onShowNetworks,
    required this.onShowAddNetwork,
    required this.onSelectNetwork,
    required this.onCancelNetworkFlow,
    required this.onSaveNetwork,
    this.profileBadgeLabel,
  });

  final LoginController controller;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final TextEditingController registerConfirmPasswordController;
  final TextEditingController codeController;
  final TextEditingController networkNameController;
  final TextEditingController networkOriginController;
  final _AuthPanelMode mode;
  final String? registerFormError;
  final String? networkFormError;
  final bool showPassword;
  final bool showRegisterPassword;
  final bool legalAccepted;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRegisterPassword;
  final ValueChanged<bool> onToggleLegalAccepted;
  final Future<void> Function() onSubmitCredentials;
  final Future<void> Function() onSubmitRegistration;
  final Future<void> Function() onSubmitCode;
  final VoidCallback onShowRegister;
  final VoidCallback onShowNetworks;
  final VoidCallback onShowAddNetwork;
  final Future<void> Function(NetworkProfile profile) onSelectNetwork;
  final VoidCallback onCancelNetworkFlow;
  final Future<void> Function() onSaveNetwork;
  final String? profileBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 640;
    final loginContent = Container(
      color: VerdantColors.background,
      child: Center(
        child: SmoothSingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 32,
            vertical: compact ? 12 : 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: _AuthPanel(
              controller: controller,
              emailController: emailController,
              passwordController: passwordController,
              registerEmailController: registerEmailController,
              registerPasswordController: registerPasswordController,
              registerConfirmPasswordController:
                  registerConfirmPasswordController,
              codeController: codeController,
              networkNameController: networkNameController,
              networkOriginController: networkOriginController,
              mode: mode,
              registerFormError: registerFormError,
              networkFormError: networkFormError,
              showPassword: showPassword,
              showRegisterPassword: showRegisterPassword,
              legalAccepted: legalAccepted,
              onTogglePassword: onTogglePassword,
              onToggleRegisterPassword: onToggleRegisterPassword,
              onToggleLegalAccepted: onToggleLegalAccepted,
              onSubmitCredentials: onSubmitCredentials,
              onSubmitRegistration: onSubmitRegistration,
              onSubmitCode: onSubmitCode,
              onShowRegister: onShowRegister,
              onShowNetworks: onShowNetworks,
              onShowAddNetwork: onShowAddNetwork,
              onSelectNetwork: onSelectNetwork,
              onCancelNetworkFlow: onCancelNetworkFlow,
              onSaveNetwork: onSaveNetwork,
              profileBadgeLabel: profileBadgeLabel,
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: controller.isInitializing
          ? Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(opacity: 0, child: loginContent),
                  ),
                ),
                _StartupLoadingSurface(profileBadgeLabel: profileBadgeLabel),
              ],
            )
          : loginContent,
    );
  }
}

class _StartupLoadingSurface extends StatelessWidget {
  const _StartupLoadingSurface({this.profileBadgeLabel});

  final String? profileBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 640;
    final iconSize = compact ? 44.0 : 56.0;
    return ColoredBox(
      key: const ValueKey('startup-loading-surface'),
      color: VerdantColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(iconSize <= 44 ? 8 : 10),
              child: Image.asset(
                verdantAppIconAsset,
                key: const ValueKey('startup-loading-app-icon'),
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (profileBadgeLabel case final label?) ...[
              const SizedBox(height: 10),
              _AuthProfileBadge(label: label),
            ],
            SizedBox(height: compact ? 18 : 24),
            const SizedBox(
              key: ValueKey('startup-loading-progress'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(height: 14),
            Text(
              'Starting Verdant',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Restoring your workspace',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: VerdantColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.controller,
    required this.emailController,
    required this.passwordController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.registerConfirmPasswordController,
    required this.codeController,
    required this.networkNameController,
    required this.networkOriginController,
    required this.mode,
    required this.registerFormError,
    required this.networkFormError,
    required this.showPassword,
    required this.showRegisterPassword,
    required this.legalAccepted,
    required this.onTogglePassword,
    required this.onToggleRegisterPassword,
    required this.onToggleLegalAccepted,
    required this.onSubmitCredentials,
    required this.onSubmitRegistration,
    required this.onSubmitCode,
    required this.onShowRegister,
    required this.onShowNetworks,
    required this.onShowAddNetwork,
    required this.onSelectNetwork,
    required this.onCancelNetworkFlow,
    required this.onSaveNetwork,
    this.profileBadgeLabel,
  });

  final LoginController controller;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final TextEditingController registerConfirmPasswordController;
  final TextEditingController codeController;
  final TextEditingController networkNameController;
  final TextEditingController networkOriginController;
  final _AuthPanelMode mode;
  final String? registerFormError;
  final String? networkFormError;
  final bool showPassword;
  final bool showRegisterPassword;
  final bool legalAccepted;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRegisterPassword;
  final ValueChanged<bool> onToggleLegalAccepted;
  final Future<void> Function() onSubmitCredentials;
  final Future<void> Function() onSubmitRegistration;
  final Future<void> Function() onSubmitCode;
  final VoidCallback onShowRegister;
  final VoidCallback onShowNetworks;
  final VoidCallback onShowAddNetwork;
  final Future<void> Function(NetworkProfile profile) onSelectNetwork;
  final VoidCallback onCancelNetworkFlow;
  final Future<void> Function() onSaveNetwork;
  final String? profileBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 210);

    final child = controller.isCodeStep
        ? _codeForm(context)
        : switch (mode) {
            _AuthPanelMode.signIn => _credentialsForm(context),
            _AuthPanelMode.register => _registerForm(context),
            _AuthPanelMode.networkList => _networkList(context),
            _AuthPanelMode.addNetwork => _addNetworkForm(context),
          };

    return _Panel(
      child: AnimatedSize(
        duration: duration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOutCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return currentChild ?? const SizedBox.shrink();
            },
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.018),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(position: offset, child: child);
            },
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _credentialsForm(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 640;
    final logoSize = compact ? 42.0 : 56.0;
    final sectionGap = compact ? 12.0 : 24.0;
    final fieldGap = compact ? 6.0 : 8.0;
    final inputGap = compact ? 10.0 : 16.0;
    final actionGap = compact ? 10.0 : 20.0;
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        key: const ValueKey('credentials-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brandHeader(context, size: logoSize),
          SizedBox(height: sectionGap),
          _FieldLabel('API origin'),
          SizedBox(height: fieldGap),
          _NetworkSelectorButton(
            profile: controller.selectedNetworkProfile,
            identity: controller.instanceIdentityFor(
              controller.selectedNetworkProfile,
            ),
            isLoading: controller.isInitializing,
            compact: compact,
            onPressed: controller.isSubmitting ? null : onShowNetworks,
          ),
          SizedBox(height: sectionGap),
          Text(
            'Sign in to Verdant',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              'Use an existing account session.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          SizedBox(height: sectionGap),
          _FieldLabel('Email'),
          SizedBox(height: fieldGap),
          TextField(
            key: const ValueKey('login-email-field'),
            controller: emailController,
            enabled: !controller.isSubmitting,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              hintText: 'you@example.com',
              dense: compact,
            ),
          ),
          SizedBox(height: inputGap),
          _FieldLabel('Password'),
          SizedBox(height: fieldGap),
          TextField(
            key: const ValueKey('login-password-field'),
            controller: passwordController,
            enabled: !controller.isSubmitting,
            autocorrect: false,
            enableSuggestions: false,
            obscureText: !showPassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitCredentials(),
            decoration: _inputDecoration(
              hintText: 'Enter your password',
              dense: compact,
              suffixIcon: IconButton(
                tooltip: showPassword ? 'Hide password' : 'Show password',
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: controller.isSubmitting ? null : onTogglePassword,
              ),
            ),
          ),
          _ErrorMessage(error: controller.error),
          SizedBox(height: compact && controller.error == null ? 8 : actionGap),
          VerdantButton(
            key: const ValueKey('login-submit-button'),
            onPressed: controller.isSubmitting || controller.isInitializing
                ? null
                : onSubmitCredentials,
            label: controller.isSubmitting ? 'Signing in' : 'Sign In',
            isBusy: controller.isSubmitting,
          ),
          SizedBox(height: compact ? 6 : 10),
          VerdantButton(
            key: const ValueKey('login-show-register-button'),
            onPressed: controller.isSubmitting || controller.isInitializing
                ? null
                : onShowRegister,
            label: 'Create account',
            variant: VerdantButtonVariant.ghost,
          ),
        ],
      ),
    );
  }

  Widget _registerForm(BuildContext context) {
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        key: const ValueKey('register-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brandHeader(context, size: 44),
          const SizedBox(height: 12),
          _FieldLabel('API origin'),
          const SizedBox(height: 6),
          _NetworkSelectorButton(
            profile: controller.selectedNetworkProfile,
            identity: controller.instanceIdentityFor(
              controller.selectedNetworkProfile,
            ),
            isLoading: controller.isInitializing,
            compact: true,
            onPressed: controller.isSubmitting ? null : onShowNetworks,
          ),
          const SizedBox(height: 14),
          Text(
            'Create your account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          _FieldLabel('Email'),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('register-email-field'),
            controller: registerEmailController,
            enabled: !controller.isSubmitting,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              hintText: 'you@example.com',
              dense: true,
            ),
          ),
          const SizedBox(height: 10),
          _FieldLabel('Password'),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('register-password-field'),
            controller: registerPasswordController,
            enabled: !controller.isSubmitting,
            autocorrect: false,
            enableSuggestions: false,
            obscureText: !showRegisterPassword,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              hintText: 'Min. 8 characters',
              dense: true,
              suffixIcon: IconButton(
                tooltip: showRegisterPassword
                    ? 'Hide password'
                    : 'Show password',
                icon: Icon(
                  showRegisterPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: controller.isSubmitting
                    ? null
                    : onToggleRegisterPassword,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FieldLabel('Confirm password'),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('register-confirm-password-field'),
            controller: registerConfirmPasswordController,
            enabled: !controller.isSubmitting,
            autocorrect: false,
            enableSuggestions: false,
            obscureText: !showRegisterPassword,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => onSubmitRegistration(),
            decoration: _inputDecoration(
              hintText: 'Repeat your password',
              dense: true,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('register-legal-checkbox'),
              borderRadius: VerdantRadii.sharp,
              onTap: controller.isSubmitting
                  ? null
                  : () => onToggleLegalAccepted(!legalAccepted),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: legalAccepted,
                        onChanged: controller.isSubmitting
                            ? null
                            : (value) => onToggleLegalAccepted(value ?? false),
                        activeColor: VerdantColors.accent,
                        checkColor: VerdantColors.background,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'I accept the Terms and Privacy Policy for this network.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _ErrorMessage(error: registerFormError ?? controller.error),
          const SizedBox(height: 12),
          VerdantButton(
            key: const ValueKey('register-submit-button'),
            onPressed: controller.isSubmitting || controller.isInitializing
                ? null
                : onSubmitRegistration,
            label: controller.isSubmitting
                ? 'Creating account'
                : 'Create account',
            isBusy: controller.isSubmitting,
          ),
          const SizedBox(height: 8),
          VerdantButton(
            key: const ValueKey('register-show-login-button'),
            onPressed: controller.isSubmitting ? null : onCancelNetworkFlow,
            label: 'Back to sign in',
            variant: VerdantButtonVariant.ghost,
          ),
        ],
      ),
    );
  }

  Widget _networkList(BuildContext context) {
    return Column(
      key: const ValueKey('network-list-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brandHeader(context),
        const SizedBox(height: 24),
        Text('Choose network', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Select the API origin that owns this account.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        for (final profile in controller.networkProfiles) ...[
          _NetworkOptionRow(
            profile: profile,
            identity: controller.instanceIdentityFor(profile),
            selected:
                profile.apiOrigin ==
                controller.selectedNetworkProfile.apiOrigin,
            onTap: () => onSelectNetwork(profile),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        VerdantButton(
          key: const ValueKey('login-add-network-button'),
          onPressed: onShowAddNetwork,
          icon: Icons.add_link,
          label: 'New API URL',
          variant: VerdantButtonVariant.secondary,
        ),
        const SizedBox(height: 10),
        VerdantButton(
          onPressed: onCancelNetworkFlow,
          label: 'Back to sign in',
          variant: VerdantButtonVariant.ghost,
        ),
      ],
    );
  }

  Widget _addNetworkForm(BuildContext context) {
    return Column(
      key: const ValueKey('add-network-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brandHeader(context),
        const SizedBox(height: 24),
        Text('Add API URL', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Save a local network profile for this desktop client.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        _FieldLabel('Network name'),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('login-network-name-field'),
          controller: networkNameController,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(hintText: 'Self-host'),
        ),
        const SizedBox(height: 16),
        _FieldLabel('API URL'),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('login-network-origin-field'),
          controller: networkOriginController,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSaveNetwork(),
          decoration: _inputDecoration(hintText: 'https://api.example.com'),
        ),
        _ErrorMessage(error: networkFormError),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: VerdantButton(
                onPressed: onCancelNetworkFlow,
                label: 'Cancel',
                variant: VerdantButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VerdantButton(
                key: const ValueKey('login-network-save-button'),
                onPressed: onSaveNetwork,
                label: 'Save',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _codeForm(BuildContext context) {
    final title = controller.step == LoginStep.twoFactor
        ? 'Two-factor authentication'
        : 'Verification code';
    final description = controller.step == LoginStep.twoFactor
        ? 'Enter an authenticator code or backup code.'
        : 'Complete the pending sign-in.';
    final label = controller.step == LoginStep.twoFactor
        ? 'Authentication code'
        : 'Code';
    final keyboardType = controller.step == LoginStep.twoFactor
        ? TextInputType.text
        : TextInputType.number;
    final hintText = controller.step == LoginStep.twoFactor
        ? '000000 or backup code'
        : '000000';
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        key: const ValueKey('code-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brandHeader(context),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          _FieldLabel(label),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('login-code-field'),
            controller: codeController,
            enabled: !controller.isSubmitting,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: keyboardType,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitCode(),
            decoration: _inputDecoration(hintText: hintText),
          ),
          _ErrorMessage(error: controller.error),
          const SizedBox(height: 20),
          VerdantButton(
            key: const ValueKey('login-code-submit-button'),
            onPressed: controller.isSubmitting ? null : onSubmitCode,
            label: controller.isSubmitting ? 'Checking' : 'Continue',
            isBusy: controller.isSubmitting,
          ),
          const SizedBox(height: 10),
          VerdantButton(
            onPressed: controller.isSubmitting
                ? null
                : controller.backToCredentials,
            label: 'Use another account',
            variant: VerdantButtonVariant.ghost,
          ),
        ],
      ),
    );
  }

  Widget _brandHeader(BuildContext context, {double size = 56}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(size <= 44 ? 8 : 10),
            child: Image.asset(
              verdantAppIconAsset,
              key: const ValueKey('login-brand-app-icon'),
              width: size,
              height: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
          if (profileBadgeLabel case final label?) ...[
            const SizedBox(height: 10),
            _AuthProfileBadge(label: label),
          ],
        ],
      ),
    );
  }
}

class _AuthProfileBadge extends StatelessWidget {
  const _AuthProfileBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        key: const ValueKey('login-profile-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: VerdantColors.panelRaised,
          border: Border.all(color: VerdantColors.accent),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: VerdantColors.accent,
            fontWeight: FontWeight.w800,
            letterSpacing: .12,
          ),
        ),
      ),
    );
  }
}

class _NetworkSelectorButton extends StatelessWidget {
  const _NetworkSelectorButton({
    required this.profile,
    required this.identity,
    required this.isLoading,
    required this.onPressed,
    this.compact = false,
  });

  final NetworkProfile profile;
  final InstanceIdentity? identity;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('login-network-selector-button'),
        onTap: onPressed,
        borderRadius: VerdantRadii.sharp,
        child: Container(
          padding: EdgeInsets.all(compact ? 9 : 12),
          decoration: BoxDecoration(
            color: VerdantColors.panelRaised,
            border: Border.all(color: VerdantColors.border),
            borderRadius: VerdantRadii.sharp,
          ),
          child: Row(
            children: [
              Icon(
                _networkTrustIcon(profile, identity),
                size: compact ? 17 : 18,
                color: _networkTrustColor(profile, identity),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? 'Loading networks...' : profile.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.apiOrigin,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _networkTrustLabel(profile, identity),
                      key: ValueKey(
                        'login-network-selector-trust-${profile.networkId}',
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _networkTrustColor(profile, identity),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: VerdantColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkOptionRow extends StatelessWidget {
  const _NetworkOptionRow({
    required this.profile,
    required this.identity,
    required this.selected,
    required this.onTap,
  });

  final NetworkProfile profile;
  final InstanceIdentity? identity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('login-network-option-${profile.networkId}'),
        onTap: onTap,
        borderRadius: VerdantRadii.sharp,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? VerdantColors.panelHover
                : VerdantColors.panelRaised,
            border: Border.all(
              color: selected ? VerdantColors.accent : VerdantColors.border,
            ),
            borderRadius: VerdantRadii.sharp,
          ),
          child: Row(
            children: [
              Icon(
                _networkTrustIcon(profile, identity),
                size: 18,
                color: selected
                    ? _networkTrustColor(profile, identity)
                    : _networkTrustColor(
                        profile,
                        identity,
                      ).withValues(alpha: 0.84),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.apiOrigin,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _networkTrustLabel(profile, identity),
                      key: ValueKey(
                        'login-network-option-trust-${profile.networkId}',
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _networkTrustColor(profile, identity),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: VerdantColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _networkTrustIcon(NetworkProfile profile, InstanceIdentity? identity) {
  final status = identity?.trustStatus;
  if (status == InstanceTrustStatus.warning) {
    return Icons.warning_amber_outlined;
  }
  if (profile.isOfficial || status == InstanceTrustStatus.official) {
    return Icons.verified_outlined;
  }
  if (status == InstanceTrustStatus.verified ||
      status == InstanceTrustStatus.trustedByUser) {
    return Icons.verified_user_outlined;
  }
  return Icons.public_outlined;
}

Color _networkTrustColor(NetworkProfile profile, InstanceIdentity? identity) {
  final status = identity?.trustStatus;
  if (status == InstanceTrustStatus.warning) {
    return const Color(0xFFFFD166);
  }
  if (profile.isOfficial || status == InstanceTrustStatus.official) {
    return VerdantColors.accent;
  }
  if (status == InstanceTrustStatus.verified ||
      status == InstanceTrustStatus.trustedByUser) {
    return VerdantColors.accentStrong;
  }
  return VerdantColors.textMuted;
}

String _networkTrustLabel(NetworkProfile profile, InstanceIdentity? identity) {
  if (identity == null) {
    return profile.isOfficial
        ? 'Official pinned origin'
        : 'Identity not checked';
  }
  if (identity.trustStatus == InstanceTrustStatus.warning) {
    return 'Warning: ${identity.apiOrigin}';
  }
  return switch (identity.trustStatus) {
    InstanceTrustStatus.official => 'Official pinned origin',
    InstanceTrustStatus.verified => 'Registry verified origin',
    InstanceTrustStatus.trustedByUser => 'Trusted by you',
    InstanceTrustStatus.unverified => 'Self-reported origin',
    InstanceTrustStatus.warning => 'Warning: ${identity.apiOrigin}',
  };
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 640;
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: VerdantColors.panel,
        border: Border.all(color: VerdantColors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: VerdantColors.textMuted),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const SizedBox(height: 12);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF351C23),
          border: Border.all(color: const Color(0xFF8C2D42)),
          borderRadius: VerdantRadii.sharp,
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18, color: Color(0xFFFF809A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFFB3C1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  Widget? suffixIcon,
  bool dense = false,
}) {
  return InputDecoration(
    hintText: hintText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: VerdantColors.background,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 14,
      vertical: dense ? 10 : 13,
    ),
    border: OutlineInputBorder(
      borderRadius: VerdantRadii.sharp,
      borderSide: const BorderSide(color: VerdantColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: VerdantRadii.sharp,
      borderSide: const BorderSide(color: VerdantColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: VerdantRadii.sharp,
      borderSide: const BorderSide(color: VerdantColors.accent),
    ),
  );
}
