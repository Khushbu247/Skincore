import 'dart:convert';
import 'prediction_result.dart';
import 'hybrid_result.dart';

class MedicalReport {
  final String id;
  final DateTime dateTime;
  final String imagePath;
  final String prediction;
  final double confidence;
  final Map<String, double> probabilities;
  final String modelVersion;
  final String imageSize;
  final double processingTimeMs;
  final List<String> keyObservations;
  final List<String> recommendedCare;
  final String riskLevel;
  final String reportType; // 'scan' or 'questionnaire'
  final Map<String, dynamic>? questionnaireAnswers;

  // Additional Hybrid Fields for Tabular & Detailed Reporting
  final String? assessmentState;
  final String? skinType;
  final String? visualDescription;
  final List<Map<String, String>>? regionObservations;
  final List<String>? additionalFindings;
  final String? safetyMessage;

  MedicalReport({
    required this.id,
    required this.dateTime,
    required this.imagePath,
    required this.prediction,
    required this.confidence,
    required this.probabilities,
    required this.modelVersion,
    required this.imageSize,
    required this.processingTimeMs,
    required this.keyObservations,
    required this.recommendedCare,
    required this.riskLevel,
    this.reportType = 'scan',
    this.questionnaireAnswers,
    this.assessmentState,
    this.skinType,
    this.visualDescription,
    this.regionObservations,
    this.additionalFindings,
    this.safetyMessage,
  });


  factory MedicalReport.fromQuestionnaire({
    required String id,
    required DateTime dateTime,
    required Map<String, dynamic> answers,
  }) {
    final skinType = answers['skin_type'] ?? 'Combination';
    final rawConcern = answers['main_concern'];
    final mainConcernStr = rawConcern is List
        ? rawConcern.join(', ')
        : (rawConcern as String? ?? 'Skin Health & Maintenance');

    final symptoms = answers['symptoms'] is List
        ? (answers['symptoms'] as List).join(', ')
        : (answers['symptoms'] as String? ?? 'None reported');

    final duration = answers['duration'] ?? 'Not specified';
    final severity = answers['severity'] ?? 'Moderate';
    final triggers = answers['triggers'] is List
        ? (answers['triggers'] as List).join(', ')
        : (answers['triggers'] as String? ?? 'None specified');
    final routine = answers['products'] is List
        ? (answers['products'] as List).join(', ')
        : (answers['products'] as String? ?? 'Standard routine');
    final helpRequest = answers['help_request'] ?? 'General skin care guidance';

    return MedicalReport(
      id: id,
      dateTime: dateTime,
      imagePath: 'assets/images/sample_skin.jpg',
      prediction: 'Skin Understanding',
      confidence: 100.0,
      probabilities: {'Questionnaire Profile': 100.0},
      modelVersion: 'SkinCore Questionnaire v1.0',
      imageSize: '12 Questions',
      processingTimeMs: 0.0,
      keyObservations: [
        'Skin Type: $skinType',
        'Main Concern(s): $mainConcernStr',
        'Key Symptoms: $symptoms ($duration, $severity)',
        'Reported Triggers: $triggers',
      ],
      recommendedCare: [
        'Tailor daily skincare products specifically for $skinType skin.',
        'Target primary concerns ($mainConcernStr) with non-comedogenic active ingredients.',
        'Current Routine Products: $routine',
        'User Request: $helpRequest',
      ],
      riskLevel: 'Skin Profile',
      reportType: 'questionnaire',
      questionnaireAnswers: answers,
    );
  }

  factory MedicalReport.fromPredictionResult({
    required String id,
    required DateTime dateTime,
    required String imagePath,
    required PredictionResult result,
  }) {
    final isSerious = result.prediction.toLowerCase().contains('serious');
    final isEczema = result.prediction.toLowerCase().contains('eczema') ||
        result.prediction.toLowerCase().contains('rash');
    final isPigmentation = result.prediction.toLowerCase().contains('pigmentation');

    String risk;
    List<String> obs;
    List<String> care;

    if (isSerious) {
      risk = 'High Risk';
      obs = [
        'Atypical lesion pattern detected by MobileNetV2 classifier.',
        'High probability signal requiring professional evaluation.',
        'Potential skin inflammation or structural irregularity.',
      ];
      care = [
        'Consult a board-certified dermatologist immediately.',
        'Avoid self-medication or irritating skincare products.',
        'Monitor for changes in size, border, color, or elevation.',
      ];
    } else if (isEczema) {
      risk = 'Moderate Risk';
      obs = [
        'Skin surface shows signs of localized erythema/dryness.',
        'Disrupted epidermal barrier detected.',
        'Moderate sensitivity and moisture loss.',
      ];
      care = [
        'Use gentle, fragrance-free colloidal oatmeal cleansers.',
        'Apply ceramide-rich barrier repair ointments twice daily.',
        'Apply broad-spectrum mineral SPF 50+ when outdoors.',
      ];
    } else if (isPigmentation) {
      risk = 'Low-Moderate Risk';
      obs = [
        'Localized melanin concentration detected.',
        'Post-inflammatory hyperpigmentation or sun spots.',
        'Uneven tone in epidermal layer.',
      ];
      care = [
        'Incorporate 15% Vitamin C serum in morning routine.',
        'Use Niacinamide and Alpha Arbutin targeted spot treatments.',
        'Reapply broad-spectrum sunscreen every 2 hours.',
      ];
    } else {
      risk = 'Low-Moderate Risk';
      obs = [
        'Active follicular congestion and mild papular lesions.',
        'Elevated sebum production in target area.',
        'Surface inflammation present.',
      ];
      care = [
        'Cleanse daily with 2% Salicylic Acid cleanser.',
        'Apply Niacinamide serum for oil control & pore refinement.',
        'Keep skin hydrated with lightweight non-comedogenic gel.',
      ];
    }

    return MedicalReport(
      id: id,
      dateTime: dateTime,
      imagePath: imagePath,
      prediction: result.prediction,
      confidence: result.confidence,
      probabilities: result.probabilities,
      modelVersion: result.modelVersion,
      imageSize: result.imageSize,
      processingTimeMs: result.processingTimeMs,
      keyObservations: obs,
      recommendedCare: care,
      riskLevel: risk,
      reportType: 'scan',
    );
  }

  factory MedicalReport.fromHybridResult({
    required String id,
    required DateTime dateTime,
    required String imagePath,
    required HybridResult hybridResult,
  }) {
    final isSerious = hybridResult.needsProfessionalReview ||
        hybridResult.primaryPrediction.condition.toLowerCase().contains('serious');
    final isNormal = hybridResult.isNormalAppearing;
    final isUncertain = hybridResult.isUncertain;

    String risk;
    if (isSerious) {
      risk = 'High Risk (Clinical Alert)';
    } else if (isNormal) {
      risk = 'Low Risk (Normal-Appearing)';
    } else if (isUncertain) {
      risk = 'Uncertain Assessment';
    } else {
      risk = 'Moderate Risk';
    }

    List<String> obs = [];
    if (hybridResult.overallAssessment.isNotEmpty) {
      obs.add(hybridResult.overallAssessment);
    }

    if (hybridResult.groqAnalysis.visualDescription.isNotEmpty) {
      obs.add('Visual Observation: ${hybridResult.groqAnalysis.visualDescription}');
    }

    for (final reg in hybridResult.groqAnalysis.regionObservations) {
      obs.add('[${reg.region.toUpperCase()}] ${reg.observation} (Severity: ${reg.severity})');
    }

    for (final finding in hybridResult.groqAnalysis.additionalFindings) {
      obs.add('Finding: $finding');
    }

    List<String> care = [];
    if (isSerious) {
      care.addAll([
        'Consult a board-certified dermatologist immediately for professional medical evaluation.',
        'Avoid self-medication or applying harsh active chemical products.',
        'Monitor the targeted area for changes in color, border, size, or sensation.',
      ]);
    } else if (isNormal) {
      care.addAll([
        'Maintain daily gentle cleansing and moisturizing.',
        'Apply broad-spectrum SPF 30+ daily to protect healthy skin barrier.',
        'Re-evaluate if new symptoms or changes develop.',
      ]);
    } else if (isUncertain) {
      care.addAll([
        'Consider retaking a clear photograph in natural daylight.',
        'If symptoms persist or cause discomfort, consult a skincare professional.',
        'Avoid over-exfoliating or applying new unverified skincare products.',
      ]);
    } else {
      care.addAll([
        'Cleanse daily with a gentle non-comedogenic cleanser suited for ${hybridResult.skinType.estimatedType} skin.',
        'Apply targeted active treatments for ${hybridResult.primaryPrediction.conditionDisplay}.',
        'Wear broad-spectrum SPF 30+ daily and keep skin adequately hydrated.',
      ]);
    }

    List<Map<String, String>> regObsMaps = hybridResult.groqAnalysis.regionObservations
        .map((r) => {'region': r.region, 'observation': r.observation, 'severity': r.severity})
        .toList();

    return MedicalReport(
      id: id,
      dateTime: dateTime,
      imagePath: imagePath,
      prediction: hybridResult.primaryPrediction.conditionDisplay,
      confidence: hybridResult.primaryPrediction.confidence,
      probabilities: hybridResult.probabilities,
      modelVersion: hybridResult.primaryPrediction.modelVersion,
      imageSize: hybridResult.processing.imageSize,
      processingTimeMs: hybridResult.processing.totalTimeMs,
      keyObservations: obs,
      recommendedCare: care,
      riskLevel: risk,
      reportType: 'scan',
      assessmentState: hybridResult.assessmentStateDisplay,
      skinType: hybridResult.skinType.estimatedType,
      visualDescription: hybridResult.groqAnalysis.visualDescription,
      regionObservations: regObsMaps,
      additionalFindings: hybridResult.groqAnalysis.additionalFindings,
      safetyMessage: hybridResult.safetyMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'imagePath': imagePath,
      'prediction': prediction,
      'confidence': confidence,
      'probabilities': probabilities,
      'modelVersion': modelVersion,
      'imageSize': imageSize,
      'processingTimeMs': processingTimeMs,
      'keyObservations': keyObservations,
      'recommendedCare': recommendedCare,
      'riskLevel': riskLevel,
      'reportType': reportType,
      'questionnaireAnswers': questionnaireAnswers,
      'assessmentState': assessmentState,
      'skinType': skinType,
      'visualDescription': visualDescription,
      'regionObservations': regionObservations,
      'additionalFindings': additionalFindings,
      'safetyMessage': safetyMessage,
    };
  }

  factory MedicalReport.fromJson(Map<String, dynamic> json) {
    var rawRegs = json['regionObservations'] as List?;
    List<Map<String, String>>? parsedRegs;
    if (rawRegs != null) {
      parsedRegs = rawRegs
          .map((r) => Map<String, String>.from(Map<String, dynamic>.from(r)))
          .toList();
    }

    return MedicalReport(
      id: json['id'] ?? '',
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      imagePath: json['imagePath'] ?? '',
      prediction: json['prediction'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      probabilities: (json['probabilities'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      modelVersion: json['modelVersion'] ?? 'v1.0',
      imageSize: json['imageSize'] ?? '224x224',
      processingTimeMs: (json['processingTimeMs'] ?? 0).toDouble(),
      keyObservations: List<String>.from(json['keyObservations'] ?? []),
      recommendedCare: List<String>.from(json['recommendedCare'] ?? []),
      riskLevel: json['riskLevel'] ?? 'Low Risk',
      reportType: json['reportType'] ?? 'scan',
      questionnaireAnswers: json['questionnaireAnswers'] as Map<String, dynamic>?,
      assessmentState: json['assessmentState'],
      skinType: json['skinType'],
      visualDescription: json['visualDescription'],
      regionObservations: parsedRegs,
      additionalFindings: json['additionalFindings'] != null ? List<String>.from(json['additionalFindings']) : null,
      safetyMessage: json['safetyMessage'],
    );
  }

  String encode() => jsonEncode(toJson());

  factory MedicalReport.decode(String raw) => MedicalReport.fromJson(jsonDecode(raw));
}

