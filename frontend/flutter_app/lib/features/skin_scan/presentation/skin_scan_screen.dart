import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../../models/prediction_result.dart';
import '../../../../models/hybrid_result.dart';
import '../../../../providers/reports_provider.dart';
import '../../../../widgets/safety_warning_card.dart';
import '../../../../widgets/region_analysis_card.dart';
import '../../../../widgets/gradcam_overlay.dart';


enum ScanStage { capture, preview, analyzing, result }

class SkinScanScreen extends ConsumerStatefulWidget {
  const SkinScanScreen({super.key});

  @override
  ConsumerState<SkinScanScreen> createState() => _SkinScanScreenState();
}

class _SkinScanScreenState extends ConsumerState<SkinScanScreen> {
  ScanStage _stage = ScanStage.capture;
  XFile? _imageFile;
  PredictionResult? _result;
  HybridResult? _hybridResult;
  String? _errorMessage;
  int _analysisStep = 0;

  final List<String> _analysisSteps = const [
    'Uploading image to SkinCore AI...',
    'Preprocessing & resizing to 224x224...',
    'Evaluating fine-tuned MobileNetV2 model...',
    'Performing visual analysis with SkinCore AI...',
    'Generating optional AI attention heatmap...',
    'Merging hybrid 3-state AI analysis...',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked == null) return;
      setState(() {
        _imageFile = picked;
        _stage = ScanStage.preview;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.purple),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.purple),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAnalysis() async {
    if (_imageFile == null) return;

    setState(() {
      _stage = ScanStage.analyzing;
      _analysisStep = 0;
      _errorMessage = null;
    });

    final stepTimer = Stream.periodic(const Duration(milliseconds: 900), (i) => i).listen((step) {
      if (mounted && step < _analysisSteps.length) {
        setState(() => _analysisStep = step);
      }
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Call primary hybrid endpoint
      final hybridResult = await apiService.predictSkinConditionHybrid(_imageFile!);
      await stepTimer.cancel();

      // Convert to legacy prediction result format for report saving compatibility
      final legacyResult = PredictionResult(
        prediction: hybridResult.primaryPrediction.condition,
        confidence: hybridResult.primaryPrediction.confidence,
        probabilities: hybridResult.probabilities,
        modelVersion: hybridResult.primaryPrediction.modelVersion,
        imageSize: hybridResult.processing.imageSize,
        processingTimeMs: hybridResult.processing.totalTimeMs,
      );

      // Automatically save detailed hybrid report to Track History
      await ref.read(reportsProvider.notifier).addReportFromHybrid(
            imagePath: _imageFile!.path,
            hybridResult: hybridResult,
          );


      if (mounted) {
        setState(() {
          _hybridResult = hybridResult;
          _result = legacyResult;
          _stage = ScanStage.result;
        });
      }
    } catch (e) {
      await stepTimer.cancel();
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _stage = ScanStage.preview;
        });
      }
    }
  }

  void _resetScan() {
    setState(() {
      _stage = ScanStage.capture;
      _imageFile = null;
      _result = null;
      _hybridResult = null;
      _errorMessage = null;
      _analysisStep = 0;
    });
  }


  String _formatClassName(String raw) {
    switch (raw.toLowerCase()) {
      case 'normal_skin':
      case 'normal/healthy skin':
        return 'Normal / Healthy Skin';
      case 'acne':
        return 'Acne';
      case 'eczema_rash':
      case 'eczema/rash':
        return 'Eczema / Rash';
      case 'pigmentation':
        return 'Pigmentation';
      case 'serious_condition':
        return 'Serious Condition';
      default:
        return raw.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('AI Skin Scan'),
        centerTitle: true,
      ),
      body: switch (_stage) {
        ScanStage.capture => _CaptureView(
            onTap: _showSourceSheet,
            errorMessage: _errorMessage,
          ),
        ScanStage.preview => _PreviewView(
            imageFile: _imageFile!,
            onRetake: _showSourceSheet,
            onAnalyze: _startAnalysis,
            errorMessage: _errorMessage,
          ),
        ScanStage.analyzing => _AnalyzingView(
            steps: _analysisSteps,
            currentIndex: _analysisStep,
          ),
        ScanStage.result => _ResultView(
            imageFile: _imageFile!,
            result: _result!,
            hybridResult: _hybridResult,
            formatClassName: _formatClassName,
            onAnalyzeAnother: _resetScan,
          ),

      },
    );
  }
}

class _CaptureView extends StatelessWidget {
  final VoidCallback onTap;
  final String? errorMessage;

  const _CaptureView({required this.onTap, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Take a clear, well-lit photo of the skin area you'd like analyzed. Ensure good lighting for highest accuracy.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDCC7E4), width: 2, style: BorderStyle.solid),
                color: const Color(0xFFFCF8FD),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.purple, size: 44),
                  SizedBox(height: 12),
                  Text('Tap to capture or select photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  SizedBox(height: 6),
                  Text('Camera · Gallery', style: TextStyle(color: AppColors.mutedLight, fontSize: 12)),
                ],
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF5DFB1)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ '),
                Expanded(
                  child: Text(
                    'SkinCore provides AI-assisted, preliminary classification only and is not a medical diagnosis. Always consult a certified dermatologist.',
                    style: TextStyle(color: Color(0xFF8A6416), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  final XFile imageFile;
  final VoidCallback onRetake;
  final VoidCallback onAnalyze;
  final String? errorMessage;

  const _PreviewView({
    required this.imageFile,
    required this.onRetake,
    required this.onAnalyze,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _CrossPlatformImage(
              file: imageFile,
              height: 280,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 20),
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          GradientButton(
            label: 'Analyze Image with AI',
            icon: Icons.psychology_rounded,
            onPressed: onAnalyze,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetake,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 18),
                SizedBox(width: 8),
                Text('Retake / Choose another photo'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const _AnalyzingView({required this.steps, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                strokeWidth: 7,
                valueColor: AlwaysStoppedAnimation(AppColors.rose),
              ),
            ),
            const SizedBox(height: 28),
            Text('Analyzing Skin Condition', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Running MobileNetV2 Deep Learning Model',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            ...List.generate(steps.length, (i) {
              final done = i <= currentIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: done ? AppColors.success : AppColors.mutedLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 13,
                        color: done ? AppColors.ink : AppColors.mutedLight,
                        fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final XFile imageFile;
  final PredictionResult result;
  final HybridResult? hybridResult;
  final String Function(String) formatClassName;
  final VoidCallback onAnalyzeAnother;

  const _ResultView({
    required this.imageFile,
    required this.result,
    this.hybridResult,
    required this.formatClassName,
    required this.onAnalyzeAnother,
  });

  Color _getAssessmentStateColor(String state) {
    switch (state) {
      case 'normal_appearing':
        return Colors.green.shade700;
      case 'uncertain':
        return Colors.orange.shade800;
      case 'condition':
      default:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSerious = result.prediction.toLowerCase().contains('serious') ||
        (hybridResult?.needsProfessionalReview ?? false);
    final safetyMsg = hybridResult?.safetyMessage;
    final assessmentStateDisplay = hybridResult?.assessmentStateDisplay ?? 'Condition Detected';
    final assessmentState = hybridResult?.assessmentState ?? 'condition';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safety Warning Banner
          if (isSerious || safetyMsg != null)
            SafetyWarningCard(
              safetyMessage: safetyMsg ??
                  'Elevated risk features or serious skin condition detected. Please seek prompt evaluation from a qualified dermatologist.',
            ),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _CrossPlatformImage(
              file: imageFile,
              height: 180,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 16),

          // Grad-CAM Heatmap Overlay Widget (if available)
          if (hybridResult?.gradcam.available == true &&
              hybridResult?.gradcam.heatmapBase64 != null)
            GradcamOverlayWidget(
              heatmapBase64: hybridResult!.gradcam.heatmapBase64!,
              description: hybridResult!.gradcam.description,
            ),

          // Primary Prediction Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3-State Assessment Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getAssessmentStateColor(assessmentState).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          assessmentStateDisplay.toUpperCase(),
                          style: TextStyle(
                            color: _getAssessmentStateColor(assessmentState),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (hybridResult?.skinType.estimatedType != null &&
                          hybridResult?.skinType.estimatedType != 'unknown')
                        Chip(
                          avatar: const Icon(Icons.water_drop_outlined, size: 14, color: Colors.blue),
                          label: Text(
                            'Skin: ${hybridResult!.skinType.estimatedType.toUpperCase()}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: Colors.blue.shade50,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRIMARY CLASSIFICATION',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSerious ? AppColors.danger : AppColors.rose,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatClassName(result.prediction),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: isSerious ? AppColors.danger : null,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isSerious ? AppColors.danger : AppColors.purple).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${result.confidence.toStringAsFixed(1)}% confidence',
                          style: TextStyle(
                            color: isSerious ? AppColors.danger : AppColors.purple,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: result.confidence / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF0E8F2),
                      valueColor: AlwaysStoppedAnimation(
                        isSerious ? AppColors.danger : AppColors.rose,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Groq AI Region Analysis Card (if available)
          if (hybridResult?.groqAnalysis.available == true)
            RegionAnalysisCard(
              observations: hybridResult!.groqAnalysis.regionObservations,
              visualDescription: hybridResult!.groqAnalysis.visualDescription,
              additionalFindings: hybridResult!.groqAnalysis.additionalFindings,
            ),

          // Overall Assessment Summary Card
          if (hybridResult?.overallAssessment != null &&
              hybridResult!.overallAssessment.isNotEmpty) ...[
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: AppColors.purple, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Summary Assessment',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hybridResult!.overallAssessment,
                      style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 20),
          Text('Full Probability Distribution', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: result.probabilities.entries.map((entry) {
                  final label = formatClassName(entry.key);
                  final prob = entry.value;
                  final isTop = entry.key.toLowerCase() == result.prediction.toLowerCase();
                  final isDark = theme.brightness == Brightness.dark;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                                color: isTop ? AppColors.purple : (isDark ? Colors.white : AppColors.ink),
                              ),
                            ),
                            Text(
                              '${prob.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12.5,
                                color: isTop ? AppColors.purple : (isDark ? Colors.white70 : AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: prob / 100,
                            minHeight: 6,
                            backgroundColor: isDark ? AppColors.lineDark : const Color(0xFFF5EEF7),
                            valueColor: AlwaysStoppedAnimation(
                              isTop ? AppColors.purple : (isDark ? Colors.white24 : AppColors.mutedLight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetaTile(label: 'Model Version', value: result.modelVersion),
                  _MetaTile(label: 'Image Size', value: result.imageSize),
                  _MetaTile(
                    label: 'Latency',
                    value: '${result.processingTimeMs.toStringAsFixed(0)} ms',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'View Personalized Recommendations',
            onPressed: () => context.pushNamed('recommendations', extra: result.prediction),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.goNamed('progress'),
            icon: const Icon(Icons.assignment_outlined, size: 18),
            label: const Text('View Medical Report in Track History'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onAnalyzeAnother,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.center_focus_strong_rounded, size: 18),
                SizedBox(width: 8),
                Text('Analyze Another Image'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.goNamed('home'),
            child: const Center(child: Text('Back to Home')),
          ),
        ],
      ),
    );
  }
}

class _CrossPlatformImage extends StatelessWidget {
  final XFile file;
  final double height;
  final double width;

  const _CrossPlatformImage({
    required this.file,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(file.path),
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    }
  }
}

class _MetaTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetaTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      ],
    );
  }
}
