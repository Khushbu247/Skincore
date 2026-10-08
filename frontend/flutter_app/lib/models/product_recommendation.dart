class RecommendedProductItem {
  final String productId;
  final String name;
  final String brand;
  final String category;
  final String description;
  final double priceInr;
  final String priceBand; // 'budget', 'mid_range', 'premium'
  final String imageUrl;
  final String buyUrl;
  final List<String> keyIngredients;
  final double suitabilityScore; // 0 - 100
  final String suitabilityBadge; // 'Highly Suitable', 'Suitable', 'Potentially Suitable'
  final String usageTime; // 'AM', 'PM', 'AM/PM'
  final String whyItWorks;
  final String howToUse;
  final List<String> warningsOrConflicts;
  final String source;

  RecommendedProductItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.priceInr,
    required this.priceBand,
    required this.imageUrl,
    required this.buyUrl,
    required this.keyIngredients,
    required this.suitabilityScore,
    required this.suitabilityBadge,
    required this.usageTime,
    required this.whyItWorks,
    required this.howToUse,
    required this.warningsOrConflicts,
    this.source = 'dynamic_search',
  });

  factory RecommendedProductItem.fromJson(Map<String, dynamic> json) {
    return RecommendedProductItem(
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? 'Verified Brand',
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      priceInr: (json['price_inr'] ?? 0.0).toDouble(),
      priceBand: json['price_band'] ?? 'budget',
      imageUrl: json['image_url'] ?? 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=500',
      buyUrl: json['buy_url'] ?? '',
      keyIngredients: List<String>.from(json['key_ingredients'] ?? []),
      suitabilityScore: (json['suitability_score'] ?? 0.0).toDouble(),
      suitabilityBadge: json['suitability_badge'] ?? 'Suitable',
      usageTime: json['usage_time'] ?? 'AM/PM',
      whyItWorks: json['why_it_works'] ?? '',
      howToUse: json['how_to_use'] ?? '',
      warningsOrConflicts: List<String>.from(json['warnings_or_conflicts'] ?? []),
      source: json['source'] ?? 'dynamic_search',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'brand': brand,
      'category': category,
      'description': description,
      'price_inr': priceInr,
      'price_band': priceBand,
      'image_url': imageUrl,
      'buy_url': buyUrl,
      'key_ingredients': keyIngredients,
      'suitability_score': suitabilityScore,
      'suitability_badge': suitabilityBadge,
      'usage_time': usageTime,
      'why_it_works': whyItWorks,
      'how_to_use': howToUse,
      'warnings_or_conflicts': warningsOrConflicts,
      'source': source,
    };
  }
}

class CategoryIngredientGuidance {
  final String category;
  final List<String> recommendedActives;
  final List<String> avoidedIngredients;
  final String rationale;
  final String usageTime;
  final String howToUse;
  final List<String> safetyWarnings;

  CategoryIngredientGuidance({
    required this.category,
    required this.recommendedActives,
    required this.avoidedIngredients,
    required this.rationale,
    required this.usageTime,
    required this.howToUse,
    required this.safetyWarnings,
  });

  factory CategoryIngredientGuidance.fromJson(Map<String, dynamic> json) {
    return CategoryIngredientGuidance(
      category: json['category'] ?? '',
      recommendedActives: List<String>.from(json['recommended_actives'] ?? []),
      avoidedIngredients: List<String>.from(json['avoided_ingredients'] ?? []),
      rationale: json['rationale'] ?? '',
      usageTime: json['usage_time'] ?? 'AM/PM',
      howToUse: json['how_to_use'] ?? '',
      safetyWarnings: List<String>.from(json['safety_warnings'] ?? []),
    );
  }
}

class ProductRecommendationResponse {
  final String status; // 'success', 'missing_prerequisites', 'error'
  final String cacheKey;
  final bool isCached;
  final String skinTypeSummary;
  final String summaryAiInsight;
  final bool seriousConditionDetected;
  final String? medicalWarningBanner;
  final List<CategoryIngredientGuidance> categoryGuidance;
  final List<RecommendedProductItem> products;
  final List<String> missingPrerequisites;
  final String? errorMessage;

  ProductRecommendationResponse({
    required this.status,
    required this.cacheKey,
    this.isCached = false,
    required this.skinTypeSummary,
    required this.summaryAiInsight,
    this.seriousConditionDetected = false,
    this.medicalWarningBanner,
    required this.categoryGuidance,
    required this.products,
    this.missingPrerequisites = const [],
    this.errorMessage,
  });

  factory ProductRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return ProductRecommendationResponse(
      status: json['status'] ?? 'success',
      cacheKey: json['cache_key'] ?? '',
      isCached: json['is_cached'] ?? false,
      skinTypeSummary: json['skin_type_summary'] ?? 'Combination',
      summaryAiInsight: json['summary_ai_insight'] ?? '',
      seriousConditionDetected: json['serious_condition_detected'] ?? false,
      medicalWarningBanner: json['medical_warning_banner'],
      categoryGuidance: (json['category_guidance'] as List?)
              ?.map((e) => CategoryIngredientGuidance.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      products: (json['products'] as List?)
              ?.map((e) => RecommendedProductItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      missingPrerequisites: List<String>.from(json['missing_prerequisites'] ?? []),
      errorMessage: json['error_message'],
    );
  }
}
