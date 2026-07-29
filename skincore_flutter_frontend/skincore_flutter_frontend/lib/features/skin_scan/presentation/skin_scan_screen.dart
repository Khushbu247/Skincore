import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';

enum _ScanStage { capture, analyzing, result }

class SkinScanScreen extends StatefulWidget {
  const SkinScanScreen({super.key});

  @override
  State<SkinScanScreen> createState() => _SkinScanScreenState();
}

class _SkinScanScreenState extends State<SkinScanScreen> {
  _ScanStage _stage = _ScanStage.capture;
  File? _image;
  int _stepIndex = 0;

  final _steps = const [
    'Preprocessing image',
    'Detecting skin regions',
    'Running classification model',
    'Generating recommendations',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _stage = _ScanStage.analyzing;
      _stepIndex = 0;
    });
    _runAnalysisSteps();
  }

  void _runAnalysisSteps() {
    Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!mounted) return timer.cancel();
      if (_stepIndex < _steps.length - 1) {
        setState(() => _stepIndex++);
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _stage = _ScanStage.result);
        });
      }
    });
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: const Text('AI Skin Scan'),
        centerTitle: true,
      ),
      body: switch (_stage) {
        _ScanStage.capture => _CaptureView(onTap: _showSourceSheet),
        _ScanStage.analyzing => _AnalyzingView(steps: _steps, currentIndex: _stepIndex),
        _ScanStage.result => _ResultView(image: _image),
      },
    );
  }
}

class _CaptureView extends StatelessWidget {
  final VoidCallback onTap;
  const _CaptureView({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Take a clear, well-lit photo of the skin area you'd like analyzed. Remove makeup for best accuracy.",
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.purple, size: 40),
                  SizedBox(height: 10),
                  Text('Tap to capture or upload', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Camera · Gallery', style: TextStyle(color: AppColors.mutedLight, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFF6E9), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF5DFB1))),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ '),
                Expanded(
                  child: Text(
                    'SkinCore provides AI-assisted, preliminary guidance only and is not a medical diagnosis. Consult a licensed dermatologist for treatment decisions.',
                    style: TextStyle(color: Color(0xFF8A6416), fontSize: 12),
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

class _AnalyzingView extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;
  const _AnalyzingView({required this.steps, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(strokeWidth: 8, valueColor: AlwaysStoppedAnimation(AppColors.rose)),
          ),
          const SizedBox(height: 24),
          Text('Analyzing your skin', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Our model is examining texture, tone & patterns',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
          const SizedBox(height: 24),
          ...List.generate(steps.length, (i) {
            final done = i <= currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: done ? AppColors.success : AppColors.mutedLight, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(steps[i],
                      style: TextStyle(
                          fontSize: 12.5, color: done ? AppColors.ink : AppColors.mutedLight, fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final File? image;
  const _ResultView({required this.image});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: image != null
                ? Image.file(image!, height: 150, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 150, color: const Color(0xFFF3E4EE)),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PRIMARY FINDING', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.rose, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Mild Acne (Comedonal)', style: theme.textTheme.titleLarge),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                        child: const Text('92% confidence', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 11.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Severity', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    const Text('Mild', style: TextStyle(fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: 0.35,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF0E8F2),
                      valueColor: const AlwaysStoppedAnimation(AppColors.rose),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Description', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Small, non-inflamed bumps (blackheads/whiteheads) typically caused by clogged pores. Common in T-zone areas and usually responds well to consistent routine care.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 24),
          GradientButton(label: 'View my personalized routine', onPressed: () => context.pushNamed('recommendations')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => context.goNamed('home'), child: const Text('Back to home')),
        ],
      ),
    );
  }
}
