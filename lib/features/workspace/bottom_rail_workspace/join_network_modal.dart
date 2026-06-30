import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/verdant_input_sanitizer.dart';
import '../../../theme/verdant_button.dart';
import '../../auth/auth_models.dart';
import '../../auth/instance_identity.dart';
import '../../auth/instance_metadata_service.dart';
import '../../auth/network_profile_store.dart';
import 'rail_action_modal_shell.dart';

class JoinNetworkRailModal extends StatefulWidget {
  const JoinNetworkRailModal({
    required this.profileStore,
    required this.metadataService,
    required this.currentApiOrigin,
    this.identityStore,
    this.identityManifestService,
    super.key,
  });

  final NetworkProfileStore profileStore;
  final InstanceMetadataService metadataService;
  final String currentApiOrigin;
  final InstanceIdentityStore? identityStore;
  final InstanceIdentityManifestService? identityManifestService;

  @override
  State<JoinNetworkRailModal> createState() => _JoinNetworkRailModalState();
}

class _JoinNetworkRailModalState extends State<JoinNetworkRailModal> {
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  var _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RailActionModalShell(
      key: const ValueKey('join-network-modal'),
      title: 'Join Network',
      icon: PhosphorIconsRegular.globeHemisphereEast,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('join-network-name-field'),
            controller: _nameController,
            enabled: !_isSaving,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: railActionInputDecoration(
              label: 'Network Name',
              hint: 'Community',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('join-network-origin-field'),
            controller: _originController,
            enabled: !_isSaving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: railActionInputDecoration(
              label: 'API Origin',
              hint: 'https://api.community.example',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            RailActionErrorText(_error!),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: VerdantButton(
                  label: 'Cancel',
                  variant: VerdantButtonVariant.ghost,
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: VerdantButton(
                  key: const ValueKey('join-network-save-button'),
                  label: 'Continue',
                  icon: PhosphorIconsRegular.arrowRight,
                  isBusy: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = sanitizeDisplayNameInput(_nameController.text);
    final rawOrigin = sanitizeUrlInput(_originController.text);
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final normalizedOrigin = normalizeBackendApiOrigin(rawOrigin);
      if (normalizedOrigin == widget.currentApiOrigin) {
        throw const AuthException('This network is already active');
      }
      await widget.metadataService.fetchRegistrationPolicy(
        apiOrigin: normalizedOrigin,
      );
      await _recordIdentity(normalizedOrigin);
      final profile = await widget.profileStore.saveProfile(
        name: name,
        apiOrigin: normalizedOrigin,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(profile);
    } on AuthException catch (error) {
      setState(() {
        _isSaving = false;
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        _error = 'Could not save network';
      });
    }
  }

  Future<void> _recordIdentity(String normalizedOrigin) async {
    final store = widget.identityStore;
    if (store == null) {
      return;
    }
    final service =
        widget.identityManifestService ??
        const NoopInstanceIdentityManifestService();
    try {
      final manifest = await service.fetchManifest(apiOrigin: normalizedOrigin);
      if (manifest == null) {
        await store.recordManifestUnavailable(
          connectedApiOrigin: normalizedOrigin,
        );
        return;
      }
      await store.recordSelfReportedManifest(
        connectedApiOrigin: normalizedOrigin,
        manifest: manifest,
      );
    } on AuthException {
      await store.recordManifestUnavailable(
        connectedApiOrigin: normalizedOrigin,
      );
    } catch (_) {
      await store.recordManifestUnavailable(
        connectedApiOrigin: normalizedOrigin,
      );
    }
  }
}
