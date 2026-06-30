part of 'user_settings_workspace.dart';

class _AccessibilitySettingsTab extends StatelessWidget {
  const _AccessibilitySettingsTab({
    required this.accessibilitySettings,
    required this.onAccessibilityChanged,
  });

  final WorkspaceAccessibilitySettings accessibilitySettings;
  final ValueChanged<WorkspaceAccessibilitySettings> onAccessibilityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Workspace Scale',
          trailing: workspaceTextScaleLabel(
            accessibilitySettings.textScaleFactor,
          ),
        ),
        const SizedBox(height: 10),
        _AccessibilityScaleCard(
          value: accessibilitySettings.textScaleFactor,
          onChanged: (value) {
            onAccessibilityChanged(
              accessibilitySettings.copyWith(
                textScaleFactor: normalizeWorkspaceTextScale(value),
              ),
            );
          },
        ),
      ],
    );
  }
}
