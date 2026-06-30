import 'package:flutter/widgets.dart';

import 'media_residency_service.dart';

class MediaResidencyScope extends StatefulWidget {
  const MediaResidencyScope({required this.child, this.service, super.key});

  final Widget child;
  final MediaResidencyService? service;

  static MediaResidencyService? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_MediaResidencyInherited>()
        ?.service;
  }

  @override
  State<MediaResidencyScope> createState() => _MediaResidencyScopeState();
}

class _MediaResidencyScopeState extends State<MediaResidencyScope> {
  late MediaResidencyService _ownedService;

  MediaResidencyService get _service => widget.service ?? _ownedService;

  @override
  void initState() {
    super.initState();
    _ownedService = MediaResidencyService();
  }

  @override
  void dispose() {
    if (widget.service == null) {
      _ownedService.clear();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MediaResidencyInherited(service: _service, child: widget.child);
  }
}

class _MediaResidencyInherited extends InheritedWidget {
  const _MediaResidencyInherited({required this.service, required super.child});

  final MediaResidencyService service;

  @override
  bool updateShouldNotify(_MediaResidencyInherited oldWidget) {
    return !identical(service, oldWidget.service);
  }
}
