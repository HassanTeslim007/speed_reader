import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/features/speed_reader/providers/rsvp_provider.dart';
import 'package:speed_reader/features/speed_reader/widgets/rsvp_controls.dart';
import 'package:speed_reader/features/speed_reader/widgets/rsvp_display.dart';

/// RSVP (Rapid Serial Visual Presentation) Screen
class RsvpScreen extends StatefulWidget {
  final String? initialText;

  const RsvpScreen({super.key, this.initialText});

  @override
  State<RsvpScreen> createState() => _RsvpScreenState();
}

class _RsvpScreenState extends State<RsvpScreen> {
  @override
  void initState() {
    super.initState();

    // Load initial text if provided
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RsvpProvider>().loadText(widget.initialText!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'How to use',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // RSVP Display
          const Expanded(child: RsvpDisplay()),

          // Controls
          const RsvpControls(),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use Speed Reader'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RSVP Mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'RSVP (Rapid Serial Visual Presentation) displays one word at a time at the center of your screen, helping you read faster by reducing eye movement.',
              ),
              SizedBox(height: 16),
              Text(
                'Tips for Speed Reading:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Start at 200-300 WPM and gradually increase'),
              Text('• Focus on the red highlighted letter (ORP)'),
              Text('• Use the crosshair to keep your eyes centered'),
              Text('• Don\'t subvocalize (say words in your head)'),
              Text('• Trust your brain to comprehend'),
              SizedBox(height: 16),
              Text('Controls:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Adjust WPM with the slider'),
              Text('• Use quick presets (200-1000 WPM)'),
              Text('• Play/Pause to control reading'),
              Text('• Stop to reset to beginning'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
