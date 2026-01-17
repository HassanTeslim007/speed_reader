import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/settings/providers/settings_provider.dart';

/// Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: Consumer<SettingsNotifier>(
          builder: (context, notifier, child) {
            final settings = notifier.state;

            return ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Appearance Section
                _SectionHeader(title: 'Appearance'),
                _PremiumTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme Mode',
                  subtitle: _getThemeModeLabel(settings.themeMode),
                  onTap: () =>
                      _showThemeDialog(context, notifier, settings.themeMode),
                ),

                const SizedBox(height: 8),

                // Reading Section
                _SectionHeader(title: 'Reading Performance'),
                _PremiumSwitchTile(
                  icon: Icons.auto_stories_outlined,
                  title: 'Auto-save Progress',
                  subtitle: 'Resume where you left off',
                  value: settings.autoSaveProgress,
                  onChanged: (value) => notifier.updateAutoSaveProgress(value),
                ),
                _PremiumSwitchTile(
                  icon: Icons.pin_drop_outlined,
                  title: 'Visual Overlays',
                  subtitle: 'Show page numbers in viewer',
                  value: settings.showPageNumbers,
                  onChanged: (value) => notifier.updateShowPageNumbers(value),
                ),

                const SizedBox(height: 8),

                // About Section
                _SectionHeader(title: 'Application'),
                _PremiumTile(
                  icon: Icons.api_outlined,
                  title: 'Platform Version',
                  subtitle: AppConstants.appVersion,
                ),
                _PremiumTile(
                  icon: Icons.history_edu_outlined,
                  title: 'Reset to Factory',
                  subtitle: 'Restore default configurations',
                  onTap: () => _showResetDialog(context, notifier),
                ),
              ],
            );
          },
        ),
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
        24,
        AppConstants.spacingMd,
        12,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PremiumTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _PremiumTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainer
            : Colors.white,
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
          trailing: onTap != null
              ? const Icon(Icons.chevron_right, size: 20)
              : null,
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _PremiumSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PremiumSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainer
            : Colors.white,
        child: SwitchListTile(
          secondary: Icon(icon, color: theme.colorScheme.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
          value: value,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

// ... RadioGroup definition below (re-using existing or standard)
