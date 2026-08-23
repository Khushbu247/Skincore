import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';
import '../../models/prediction_result.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
      ),
    );
  }

  Future<PredictionResult> predictSkinCondition(XFile pickedFile) async {
    try {
      final bytes = await pickedFile.readAsBytes();
      final String fileName = pickedFile.name.isNotEmpty ? pickedFile.name : 'skin_image.jpg';

      final FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiConstants.predictEndpoint,
        data: formData,
      );

      if (response.statusCode == 200) {
        return PredictionResult.fromJson(response.data);
      } else {
        throw Exception(
          'Server returned an error (${response.statusCode}). Please try again later.',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Connection timed out. Please check server availability and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to FastAPI server at ${ApiConstants.baseUrl}. Ensure server is running.',
        );
      } else if (e.response != null) {
        if (e.response?.statusCode == 422) {
          throw Exception('Invalid image format. Please upload a JPG, JPEG, or PNG photo.');
        } else if (e.response?.statusCode == 500) {
          throw Exception(
            'Internal server error during model prediction.',
          );
        }
        throw Exception(
          'Server error: ${e.response?.statusMessage ?? "Unknown"}',
        );
      }
      throw Exception(
        'Network error: Ensure backend server is accessible.',
      );
    } catch (e) {
      throw Exception(
        'An unexpected error occurred: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
  }

  Future<String> sendChatMessage(String message, {List<Map<String, String>> history = const []}) async {
    try {
      final response = await _dio.post(
        ApiConstants.chatbotEndpoint,
        data: {
          'message': message,
          'history': history,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['reply'] as String? ?? 'I am here to help with your skincare needs!';
      } else {
        throw Exception('Chat API error (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['reply'] != null) {
        return e.response?.data['reply'] as String;
      }
      return _generateLocalFallback(message);
    } catch (e) {
      return _generateLocalFallback(message);
    }
  }

  String _generateLocalFallback(String message) {
    final query = message.toLowerCase();

    if (query.contains('cyst') || query.contains('lump') || query.contains('bump') || query.contains('benign') || query.contains('harmful')) {
      return '''### Distinguishing Benign vs. Harmful Cysts & Bumps

**1. Benign Cysts (e.g., Epidermoid or Sebaceous Cysts):**
• **Feel & Mobility:** Soft, rubbery, or firm round bump that moves under the skin when pressed.
• **Growth & Pain:** Slow growing and generally painless unless inflamed or infected.
• **Appearance:** Skin-colored or slightly yellowish, often with a central dark pore (punctum).

**2. Harmful or Malignant Lesions (Requires Dermatologist Evaluation):**
• **Feel:** Hard, firm lump anchored to underlying deep tissue.
• **Growth:** Rapid enlargement or sudden changes in color, size, or shape.
• **Appearance:** Irregular/jagged borders, asymmetrical shape, spontaneous bleeding, or non-healing sores.
• **Color:** Multi-colored (dark brown, black, red, or blue).

💡 *SkinCore Tip:* Scan suspicious bumps with SkinCore AI Scan and export a PDF Medical Report to share with your dermatologist!''';
    } else if (query.contains('acne') || query.contains('pimple') || query.contains('breakout')) {
      return '''### Daily Acne Management Guide

1. **Cleanse:** Wash twice daily using a gentle, non-comedogenic cleanser.
2. **Treat:**
   • **Salicylic Acid (BHA 1-2%):** Clears oil and unclogs pores.
   • **Benzoyl Peroxide (2.5-5%):** Fights acne bacteria for active pimples.
   • **Retinoids:** Prevents clogged pores by regulating skin cell turnover.
3. **Moisturize & Protect:** Apply a lightweight, oil-free moisturizer and daily SPF 30+.''';
    } else if (query.contains('pigment') || query.contains('dark spot') || query.contains('melasma')) {
      return '''### Treating Dark Spots & Hyperpigmentation

1. **Morning:** Vitamin C serum + Broad Spectrum SPF 30+. Sunscreen prevents UV rays from worsening dark spots.
2. **Evening:** Apply Niacinamide (3-5%), Azelaic Acid (10%), or Alpha Arbutin to inhibit melanin overproduction.
3. **Exfoliation:** Use gentle AHA (Glycolic Acid) 1-2 times a week to slough off pigmented skin cells.''';
    } else if (query.contains('eczema') || query.contains('rash') || query.contains('redness') || query.contains('itch')) {
      return '''### Eczema & Redness Relief Guide

1. **Barrier Support:** Use ceramide-rich creams and hyaluronic acid to restore the skin barrier.
2. **Avoid Harsh Ingredients:** Avoid synthetic fragrances, alcohol, essential oils, and physical scrubs.
3. **Soothing Actives:** Colloidal Oatmeal, Centella Asiatica (Cica), and Panthenol (Vitamin B5) calm irritation.''';
    } else if (query.contains('scan') || query.contains('photo') || query.contains('camera')) {
      return '''### Tips for Accurate Skin Scanning

1. **Natural Daylight:** Take photos near a window with bright, even light. Avoid harsh shadows or indoor warm bulbs.
2. **Distance & Focus:** Keep camera 4-6 inches from your skin and ensure sharp focus.
3. **Clean Skin:** Ensure the skin is clean and un-shadowed without makeup or heavy cream.''';
    } else if (query.contains('routine')) {
      return '''### Standard SkinCore Daily Routine

• **AM:** Gentle Cleanser ➔ Vitamin C Serum ➔ Oil-Free Moisturizer ➔ Broad-Spectrum SPF 30+
• **PM:** Double Cleanser ➔ Active Treatment (Retinoid or BHA 2-3x/week) ➔ Hydrating Night Cream''';
    }

    return '''### SkinCore Skincare Advice

• **Cleanse:** Use a gentle cleanser suited to your skin type twice daily.
• **Target:** Treat concerns with targeted ingredients (BHA, Vitamin C, Niacinamide, Retinoids).
• **Protect:** Wear broad-spectrum SPF 30+ daily to protect your skin barrier.

Feel free to ask detailed questions on cysts, acne, dark spots, rashes, or daily routines!''';
  }
}


