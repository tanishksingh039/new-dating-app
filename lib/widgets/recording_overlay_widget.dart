import 'package:flutter/material.dart';

// Separate StatefulWidget for recording overlay to prevent parent rebuilds
class RecordingOverlayWidget extends StatefulWidget {
  final Duration recordingDuration;
  final List<double> waveformData;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const RecordingOverlayWidget({
    Key? key,
    required this.recordingDuration,
    required this.waveformData,
    required this.onCancel,
    required this.onSend,
  }) : super(key: key);

  @override
  State<RecordingOverlayWidget> createState() => _RecordingOverlayWidgetState();
}

class _RecordingOverlayWidgetState extends State<RecordingOverlayWidget> {
  @override
  Widget build(BuildContext context) {
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C34), // Dark background like WhatsApp
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Delete/Cancel button
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Timer with red dot
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated red dot
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.3, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF5350),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  formatDuration(widget.recordingDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Waveform visualization
            Expanded(
              child: _buildWaveform(),
            ),
            const SizedBox(width: 16),
            // Slide to cancel text
            Text(
              '< Slide to cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 16),
            // Send button
            GestureDetector(
              onTap: widget.onSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF128C7E), // WhatsApp green
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          widget.waveformData.length.clamp(0, 40),
          (index) {
            final amplitude = widget.waveformData[index];
            return Container(
              width: 2.5,
              height: 4 + (amplitude * 24),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ),
    );
  }
}
