import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/speed_reader/providers/rsvp_provider.dart';

/// RSVP controls for playback and settings
class RsvpControls extends StatelessWidget {
  const RsvpControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RsvpProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final isPlaying = provider.playbackState == RsvpPlaybackState.playing;

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // WPM Slider
                Row(
                  children: [
                    const Icon(Icons.speed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: settings.wordsPerMinute.toDouble(),
                        min: 100,
                        max: 1000,
                        divisions: 90,
                        label: '${settings.wordsPerMinute} WPM',
                        onChanged: (value) {
                          provider.updateWpm(value.round());
                        },
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${settings.wordsPerMinute} WPM',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stop button
                    IconButton.filled(
                      icon: const Icon(Icons.stop),
                      onPressed: provider.totalWords > 0
                          ? () => provider.stop()
                          : null,
                      tooltip: 'Stop',
                    ),

                    const SizedBox(width: AppConstants.spacingMd),

                    // Play/Pause button
                    IconButton.filled(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                      onPressed: provider.totalWords > 0
                          ? () {
                              if (isPlaying) {
                                provider.pause();
                              } else {
                                provider.play();
                              }
                            }
                          : null,
                      tooltip: isPlaying ? 'Pause' : 'Play',
                    ),

                    const SizedBox(width: AppConstants.spacingMd),

                    // Settings button
                    IconButton.filled(
                      icon: const Icon(Icons.settings),
                      onPressed: () => _showSettingsDialog(context, provider),
                      tooltip: 'Settings',
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingSm),

                // Quick WPM presets
                Wrap(
                  spacing: 8,
                  children: [
                    _buildPresetChip(context, provider, 200, '200'),
                    _buildPresetChip(context, provider, 300, '300'),
                    _buildPresetChip(context, provider, 500, '500'),
                    _buildPresetChip(context, provider, 700, '700'),
                    _buildPresetChip(context, provider, 1000, '1000'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(
    BuildContext context,
    RsvpProvider provider,
    int wpm,
    String label,
  ) {
    final isSelected = provider.settings.wordsPerMinute == wpm;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.updateWpm(wpm),
    );
  }

  void _showSettingsDialog(BuildContext context, RsvpProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer<RsvpProvider>(
        builder: (context, provider, child) => AlertDialog(
          title: const Text('RSVP Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Font size slider
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: const Text('Font Size'),
                  subtitle: Slider(
                    value: provider.settings.fontSize,
                    min: 24,
                    max: 72,
                    divisions: 24,
                    label: provider.settings.fontSize.round().toString(),
                    onChanged: (value) => provider.updateFontSize(value),
                  ),
                ),

                // Show focus guide toggle
                SwitchListTile(
                  secondary: const Icon(Icons.center_focus_strong),
                  title: const Text('Show Focus Guide'),
                  subtitle: const Text('Display crosshair for eye focus'),
                  value: provider.settings.showFocusGuide,
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(showFocusGuide: value),
                    );
                  },
                ),

                // Highlight ORP toggle
                SwitchListTile(
                  secondary: const Icon(Icons.highlight),
                  title: const Text('Highlight ORP'),
                  subtitle: const Text('Optimal Recognition Point'),
                  value: provider.settings.highlightORP,
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(highlightORP: value),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
