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
                        'AI Attention Heatmap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _showHeatmap,
                    activeColor: Colors.deepOrange,
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
