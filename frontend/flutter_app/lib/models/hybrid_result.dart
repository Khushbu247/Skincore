class PrimaryPredictionInfo {
  final String condition;
  final String conditionDisplay;
  final double confidence;
  final String model;
  final String modelVersion;

  PrimaryPredictionInfo({
    required this.condition,
    required this.conditionDisplay,
    required this.confidence,
    required this.model,
    required this.modelVersion,
  });

  factory PrimaryPredictionInfo.fromJson(Map<String, dynamic> json) {
    return PrimaryPredictionInfo(
      condition: json['condition'] ?? '',
      conditionDisplay: json['condition_display'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      model: json['model'] ?? 'MobileNetV2',
      modelVersion: json['model_version'] ?? '1.0.0',
    );
  }
}

class SkinTypeData {
  final String estimatedType;
  final String confidenceNote;
  final String source;

  SkinTypeData({
    required this.estimatedType,
    required this.confidenceNote,
    required this.source,
  });

  factory SkinTypeData.fromJson(Map<String, dynamic> json) {
    return SkinTypeData(
      estimatedType: json['estimated_type'] ?? 'unknown',
      confidenceNote: json['confidence_note'] ?? '',
      source: json['source'] ?? 'none',
    );
  }
}

class RegionObservationData {
  final String region;
  final String observation;
  final String severity;

  RegionObservationData({
    required this.region,
    required this.observation,
    required this.severity,
  });

  factory RegionObservationData.fromJson(Map<String, dynamic> json) {
    return RegionObservationData(
      region: json['region'] ?? '',
      observation: json['observation'] ?? '',
      severity: json['severity'] ?? 'normal',
    );
  }
}

class GroqAnalysisData {
  final bool available;
  final String visualDescription;
  final List<RegionObservationData> regionObservations;
  final List<String> additionalFindings;
  final String? modelUsed;

  GroqAnalysisData({
    required this.available,
    required this.visualDescription,
    required this.regionObservations,
    required this.additionalFindings,
    this.modelUsed,
  });

  factory GroqAnalysisData.fromJson(Map<String, dynamic> json) {
    var rawRegions = json['region_observations'] as List? ?? [];
    var regions = rawRegions
        .map((r) => RegionObservationData.fromJson(Map<String, dynamic>.from(r)))
        .toList();

    var rawFindings = json['additional_findings'] as List? ?? [];
    var findings = rawFindings.map((f) => f.toString()).toList();

    return GroqAnalysisData(
      available: json['available'] ?? false,
      visualDescription: json['visual_description'] ?? '',
      regionObservations: regions,
      additionalFindings: findings,
      modelUsed: json['model_used'],
    );
  }
}

class GradcamData {
  final bool available;
  final String? heatmapBase64;
  final String description;

  GradcamData({
    required this.available,
    this.heatmapBase64,
    required this.description,
  });

  factory GradcamData.fromJson(Map<String, dynamic> json) {
    return GradcamData(
      available: json['available'] ?? false,
      heatmapBase64: json['heatmap_base64'],
      description: json['description'] ?? '',
    );
  }
}

class ProcessingData {
  final double mobilenetTimeMs;
  final double totalTimeMs;
  final String imageSize;

  ProcessingData({
    required this.mobilenetTimeMs,
    required this.totalTimeMs,
    required this.imageSize,
  });

  factory ProcessingData.fromJson(Map<String, dynamic> json) {
    return ProcessingData(
      mobilenetTimeMs: (json['mobilenet_time_ms'] as num?)?.toDouble() ?? 0.0,
      totalTimeMs: (json['total_time_ms'] as num?)?.toDouble() ?? 0.0,
      imageSize: json['image_size'] ?? '224x224',
    );
  }
}

class HybridResult {
  final bool success;
  final String analysisVersion;
  final String endpoint;
  final PrimaryPredictionInfo primaryPrediction;
  final Map<String, double> probabilities;
  final String assessmentState;
  final String assessmentStateDisplay;
  final SkinTypeData skinType;
  final GroqAnalysisData groqAnalysis;
  final String overallAssessment;
  final bool needsProfessionalReview;
  final String? safetyMessage;
  final GradcamData gradcam;
  final ProcessingData processing;
  final List<String> errors;

  HybridResult({
    required this.success,
    required this.analysisVersion,
    required this.endpoint,
    required this.primaryPrediction,
    required this.probabilities,
    required this.assessmentState,
    required this.assessmentStateDisplay,
    required this.skinType,
    required this.groqAnalysis,
    required this.overallAssessment,
    required this.needsProfessionalReview,
    this.safetyMessage,
    required this.gradcam,
    required this.processing,
    required this.errors,
  });

  factory HybridResult.fromJson(Map<String, dynamic> json) {
    var rawProbs = json['probabilities'] as Map<String, dynamic>? ?? {};
    Map<String, double> parsedProbs = {};
    rawProbs.forEach((k, v) {
      parsedProbs[k] = (v as num).toDouble();
    });

    var rawErrors = json['errors'] as List? ?? [];
    List<String> parsedErrors = rawErrors.map((e) => e.toString()).toList();

    return HybridResult(
      success: json['success'] ?? true,
      analysisVersion: json['analysis_version'] ?? '2.0.0',
      endpoint: json['endpoint'] ?? '/predict/hybrid',
      primaryPrediction: PrimaryPredictionInfo.fromJson(
        Map<String, dynamic>.from(json['primary_prediction'] ?? {}),
      ),
      probabilities: parsedProbs,
      assessmentState: json['assessment_state'] ?? 'condition',
      assessmentStateDisplay: json['assessment_state_display'] ?? 'Condition Detected',
      skinType: SkinTypeData.fromJson(
        Map<String, dynamic>.from(json['skin_type'] ?? {}),
      ),
      groqAnalysis: GroqAnalysisData.fromJson(
        Map<String, dynamic>.from(json['groq_analysis'] ?? {}),
      ),
      overallAssessment: json['overall_assessment'] ?? '',
      needsProfessionalReview: json['needs_professional_review'] ?? false,
      safetyMessage: json['safety_message'],
      gradcam: GradcamData.fromJson(
        Map<String, dynamic>.from(json['gradcam'] ?? {}),
      ),
      processing: ProcessingData.fromJson(
        Map<String, dynamic>.from(json['processing'] ?? {}),
      ),
      errors: parsedErrors,
    );
  }

  bool get isNormalAppearing => assessmentState == 'normal_appearing';
  bool get isUncertain => assessmentState == 'uncertain';
  bool get isCondition => assessmentState == 'condition';
}
