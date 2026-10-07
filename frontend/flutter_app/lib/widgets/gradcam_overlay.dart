import 'dart:convert';
import 'package:flutter/material.dart';

class GradcamOverlayWidget extends StatefulWidget {
  final String heatmapBase64;
  final String description;

  const GradcamOverlayWidget({
    Key? key,
    required this.heatmapBase64,
    required this.description,
  }) : super(key: key);

  @override
  State<GradcamOverlayWidget> createState() => _GradcamOverlayWidgetState();
}

class _GradcamOverlayWidgetState extends State<GradcamOverlayWidget> {
  bool _showHeatmap = true;

  @override
  Widget build(BuildContext context) {
    String cleanBase64 = widget.heatmapBase64;
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',').last;
    }

    try {
      final bytes = base64Decode(cleanBase64);

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.center_focus_strong_outlined, color: Colors.deepOrange, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'AI Visual Focus — MobileNetV2',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _showHeatmap,
                    activeTrackColor: Colors.deepOrange,
                    onChanged: (val) {
                      setState(() {
                        _showHeatmap = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_showHeatmap) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    bytes,
                    height: 224,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'AI Visual Focus — highlights visual surface features considered by the initial 4-class MobileNetV2 classifier. It does NOT explain or prove the final Normal / Healthy classification, nor is it a medical diagnosis.',
                    style: TextStyle(fontSize: 10.5, color: Colors.black87, height: 1.3),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
