import 'package:flutter/widgets.dart';

import '../../auth/auth_diagnostics.dart';

class WorkspaceRenderProbe extends StatefulWidget {
  const WorkspaceRenderProbe({
    required this.surface,
    required this.child,
    this.id,
    this.fields = const {},
    super.key,
  });

  final String surface;
  final String? id;
  final Map<String, Object?> fields;
  final Widget child;

  @override
  State<WorkspaceRenderProbe> createState() => _WorkspaceRenderProbeState();
}

class _WorkspaceRenderProbeState extends State<WorkspaceRenderProbe> {
  @override
  void initState() {
    super.initState();
    _log('mount');
  }

  @override
  void didUpdateWidget(covariant WorkspaceRenderProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surface != widget.surface ||
        oldWidget.id != widget.id ||
        !_sameFields(oldWidget.fields, widget.fields)) {
      _log('update');
    }
  }

  @override
  void dispose() {
    _log('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log('build');
    return widget.child;
  }

  void _log(String phase) {
    logWorkspaceRender('${widget.surface}.$phase', {
      if (widget.id != null) 'id': widget.id,
      ...widget.fields,
    });
  }
}

void logWorkspaceRender(String event, Map<String, Object?> fields) {
  if (!verdantClientDiagnosticsEnabled) {
    return;
  }
  writeVerdantDiagnosticLine(
    'verdant.render $event ${sanitizeAuthDiagnosticFields(fields)}',
  );
}

Map<String, Object?> renderMediaUrlFields(String? rawUrl) {
  final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return {
      'hasUrl': rawUrl != null && rawUrl.trim().isNotEmpty,
      'urlAccepted': false,
    };
  }
  return {
    'hasUrl': true,
    'urlAccepted': true,
    'origin': _originForDiagnostic(uri),
    'pathRoot': _pathRootForDiagnostic(uri),
    'extension': _extensionForDiagnostic(uri),
  };
}

bool _sameFields(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

String _originForDiagnostic(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$scheme://$host$port';
}

String _pathRootForDiagnostic(Uri uri) {
  for (final segment in uri.pathSegments) {
    if (segment.isNotEmpty) {
      return segment.toLowerCase();
    }
  }
  return 'none';
}

String _extensionForDiagnostic(Uri uri) {
  if (uri.pathSegments.isEmpty) {
    return 'none';
  }
  final segment = uri.pathSegments.last.toLowerCase();
  final dot = segment.lastIndexOf('.');
  if (dot < 0 || dot == segment.length - 1) {
    return 'none';
  }
  return segment.substring(dot + 1);
}
