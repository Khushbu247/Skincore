import 'package:flutter/material.dart';
import '../models/hybrid_result.dart';

class RegionAnalysisCard extends StatelessWidget {
  final List<RegionObservationData> observations;
  final String visualDescription;
  final List<String> additionalFindings;

  const RegionAnalysisCard({
    super.key,
    required this.observations,
    required this.visualDescription,
    required this.additionalFindings,
  });


  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange.shade700;
      case 'mild':
        return Colors.amber.shade800;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (visualDescription.isEmpty && observations.isEmpty && additionalFindings.isEmpty) {
      return const SizedBox.shrink();
    }

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
              children: const [
                Icon(Icons.remove_red_eye_outlined, color: Colors.indigo, size: 22),
                SizedBox(width: 8),
                Text(
                  'Groq AI Visual Observation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            if (visualDescription.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                visualDescription,
                style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
              ),
            ],
            if (observations.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Region breakdown:',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              ...observations.map((obs) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(obs.severity).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            obs.region.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getSeverityColor(obs.severity),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            obs.observation,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (additionalFindings.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Additional Findings:',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              ...additionalFindings.map((finding) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        Expanded(
                          child: Text(finding, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
