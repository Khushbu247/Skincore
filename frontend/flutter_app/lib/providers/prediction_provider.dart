import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/api_service.dart';
import '../models/prediction_result.dart';

class PredictionProvider extends ChangeNotifier {
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  PredictionResult? _result;

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  XFile? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PredictionResult? get result => _result;

  void clearImage() {
    _selectedImage = null;
    _errorMessage = null;
    _result = null;
    notifyListeners();
  }

  Future<bool> pickImage(ImageSource source) async {
    _errorMessage = null;
    _result = null;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
      );

      if (pickedFile != null) {
        _selectedImage = pickedFile;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
    return false;
  }

  Future<void> checkLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      _selectedImage = response.file;
      notifyListeners();
    } else {
      _errorMessage = response.exception?.code;
      notifyListeners();
    }
  }

  Future<bool> analyzeImage() async {
    if (_selectedImage == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _apiService.predictSkinCondition(_selectedImage!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
