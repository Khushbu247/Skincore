import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/medical_report.dart';

void main() {
  group('MedicalReport Data Pipeline & Backward Compatibility Tests', () {
    test('Full structured hybrid MedicalReport serializes and deserializes cleanly', () {
      final now = DateTime.now();
      final report = MedicalReport(
        id: 'REP-20261009-9999',
        dateTime: now,
        imagePath: 'assets/images/sample_skin.jpg',
        prediction: 'Acne Vulgaris',
        confidence: 94.5,
        probabilities: {'Acne Vulgaris': 94.5, 'Eczema': 5.5},
        modelVersion: 'MobileNetV2-Hybrid-v2.0',
        imageSize: '224x224',
        processingTimeMs: 180.0,
        keyObservations: ['Active follicular papules', 'Elevated sebum production'],
        recommendedCare: ['Apply Salicylic Acid cleanser', 'Use lightweight gel moisturizer'],
        riskLevel: 'Moderate Risk',
        reportType: 'scan',
        assessmentState: 'Condition Detected',
        skinType: 'oily',
        visualDescription: 'Multiple inflammatory papules visible on forehead and left cheek.',
        regionObservations: [
          {'region': 'forehead', 'observation': 'Mild erythema and papules', 'severity': 'mild'},
          {'region': 'cheeks', 'observation': 'Moderate comedones', 'severity': 'moderate'},
        ],
        additionalFindings: ['Slight skin barrier dehydration'],
        safetyMessage: 'No immediate clinical alert required.',
      );

      final json = report.toJson();
      expect(json['id'], 'REP-20261009-9999');
      expect(json['skinType'], 'oily');
      expect(json['visualDescription'], contains('inflammatory papules'));
      expect((json['regionObservations'] as List).length, 2);

      final deserialized = MedicalReport.fromJson(json);
      expect(deserialized.id, report.id);
      expect(deserialized.skinType, 'oily');
      expect(deserialized.visualDescription, report.visualDescription);
      expect(deserialized.regionObservations?.first['region'], 'forehead');
      expect(deserialized.keyObservations.length, 2);
    });

    test('Legacy summary-only MedicalReport deserializes without crashing', () {
      final legacyJson = {
        'id': 'REP-20260801-0001',
        'dateTime': '2026-08-01T10:00:00.000',
        'imagePath': 'assets/images/sample.jpg',
        'prediction': 'Acne Vulgaris',
        'confidence': 88.0,
        'probabilities': {'Acne Vulgaris': 88.0},
        'modelVersion': 'v1.0',
        'imageSize': '224x224',
        'processingTimeMs': 200.0,
        'keyObservations': ['Legacy observation'],
        'recommendedCare': ['Legacy care'],
        'riskLevel': 'Low-Moderate Risk',
        'reportType': 'scan',
      };

      final report = MedicalReport.fromJson(legacyJson);
      expect(report.id, 'REP-20260801-0001');
      expect(report.skinType, isNull);
      expect(report.visualDescription, isNull);
      expect(report.regionObservations, isNull);
      expect(report.keyObservations, equals(['Legacy observation']));
    });

    test('Questionnaire MedicalReport preserves answers and details', () {
      final answers = {
        'skin_type': 'Combination',
        'main_concern': ['Acne / pimples', 'Dark spots'],
        'symptoms': ['Redness', 'Itching'],
        'duration': '1-3 months',
        'severity': 'Moderate',
      };

      final report = MedicalReport.fromQuestionnaire(
        id: 'SKIN-UND-PROFILE',
        dateTime: DateTime.now(),
        answers: answers,
      );

      expect(report.id, 'SKIN-UND-PROFILE');
      expect(report.prediction, 'Skin Understanding');
      expect(report.reportType, 'questionnaire');
      expect(report.questionnaireAnswers, equals(answers));
      expect(report.keyObservations.any((o) => o.contains('Combination')), isTrue);
    });
  });
}
