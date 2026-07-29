class PredictionResult {
  final String prediction;
  final double confidence;
  final Map<String, double> probabilities;
  final String modelVersion;
  final String imageSize;
  final double processingTimeMs;

  PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.probabilities,
    required this.modelVersion,
    required this.imageSize,
    required this.processingTimeMs,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      prediction: json['prediction'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      probabilities:
          (json['probabilities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
      modelVersion: json['model_version'] ?? 'N/A',
      imageSize: json['image_size'] ?? 'N/A',
      processingTimeMs: (json['processing_time_ms'] ?? 0).toDouble(),
    );
  }
}
