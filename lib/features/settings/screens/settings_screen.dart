import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/settings/providers/settings_provider.dart';

/// Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsNotifier>(
        builder: (context, notifier, child) {
          final settings = notifier.state;

          return ListView(
            children: [
              // Appearance Section
              _SectionHeader(title: 'Appearance'),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeLabel(settings.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showThemeDialog(context, notifier, settings.themeMode),
              ),

              const Divider(),

              // Reading Section
              _SectionHeader(title: 'Reading'),
              SwitchListTile(
                secondary: const Icon(Icons.save),
                title: const Text('Auto-save progress'),
                subtitle: const Text('Automatically save reading position'),
                value: settings.autoSaveProgress,
                onChanged: (value) {
                  notifier.updateAutoSaveProgress(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.numbers),
                title: const Text('Show page numbers'),
                subtitle: const Text('Display page numbers in viewer'),
                value: settings.showPageNumbers,
                onChanged: (value) {
                  notifier.updateShowPageNumbers(value);
                },
              ),

              const Divider(),

              // About Section
              _SectionHeader(title: 'About'),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text(AppConstants.appVersion),
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset settings'),
                subtitle: const Text('Restore default settings'),
                onTap: () => _showResetDialog(context, notifier),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    SettingsNotifier notifier,
    ThemeMode currentMode,
  ) async {
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose theme'),
        content: RadioGroup<ThemeMode>(
          groupValue: currentMode,
          onChanged: (value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System default'),
                value: ThemeMode.system,
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      notifier.updateThemeMode(result);
    }
  }

  Future<void> _showResetDialog(
    BuildContext context,
    SettingsNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      notifier.resetSettings();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to default')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingLg,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
