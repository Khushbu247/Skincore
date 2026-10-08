import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/product_recommendation.dart';
import '../../../models/skincare_routine.dart';
import '../../../providers/recommendation_provider.dart';
import '../../../providers/skincare_routine_provider.dart';
import 'widgets/prerequisite_warning_card.dart';
import 'widgets/product_card.dart';

class ProductRecommendationScreen extends ConsumerStatefulWidget {
  const ProductRecommendationScreen({super.key});

  @override
  ConsumerState<ProductRecommendationScreen> createState() => _ProductRecommendationScreenState();
}

class _ProductRecommendationScreenState extends ConsumerState<ProductRecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    'All',
    'Cleanser',
    'Serum',
    'Moisturizer',
    'Sunscreen',
    'Exfoliant',
    'Eye Care',
  ];

  final List<Map<String, String>> _priceBands = [
    {'label': 'All Prices', 'value': 'All'},
    {'label': 'Budget (≤ ₹500)', 'value': 'budget'},
    {'label': 'Mid-Range (₹501–₹1000)', 'value': 'mid_range'},
    {'label': 'Premium (> ₹1000)', 'value': 'premium'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddEditRoutineModal([SkincareRoutineItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditRoutineBottomSheet(itemToEdit: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final recState = ref.watch(recommendationProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Personalized Skincare'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.read(recommendationProvider.notifier).fetchRecommendations(forceRefresh: true),
            tooltip: 'Refresh Recommendations',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.purple,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.purple,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'AI Recommendations'),
            Tab(icon: Icon(Icons.spa_outlined, size: 18), text: 'My Routine'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: AI Product Recommendations
          _buildAiRecommendationsTab(context, ref, recState, theme, isDark),
          // Tab 2: My Routine Management
          _buildRoutineManagementTab(context, ref, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildAiRecommendationsTab(
    BuildContext context,
    WidgetRef ref,
    RecommendationState recState,
    ThemeData theme,
    bool isDark,
  ) {
    // Prerequisite Checks
    if (!recState.hasQuestionnaire) {
      return const PrerequisiteWarningCard(missingQuestionnaire: true);
    }
    if (!recState.hasSkinAnalysis) {
      return const PrerequisiteWarningCard(missingQuestionnaire: false);
    }

    // Loading State
    if (recState.isLoading) {
      return _buildShimmerLoading();
    }

    // Error State
    if (recState.errorMessage != null && recState.response == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text(
                'Could Not Generate Recommendations',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                recState.errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.read(recommendationProvider.notifier).fetchRecommendations(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final response = recState.response;
    final products = recState.filteredProducts;

    return RefreshIndicator(
      onRefresh: () => ref.read(recommendationProvider.notifier).fetchRecommendations(forceRefresh: true),
      color: AppColors.purple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Serious Condition Warning Banner
            if (response != null && response.seriousConditionDetected && response.medicalWarningBanner != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services_outlined, color: AppColors.danger, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        response.medicalWarningBanner!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.red[200] : Colors.red[900],
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // AI Synthesis Summary Card
            if (response != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2A2342), const Color(0xFF1E1B2E)]
                        : [const Color(0xFFF3E8FF), const Color(0xFFEDE9FE)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.purple.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.purple, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Personalization Insight',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            response.skinTypeSummary,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      response.summaryAiInsight,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Category Filter Chips
            Text(
              'Category Filters',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = recState.selectedCategory.toLowerCase() == cat.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      selectedColor: AppColors.purple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (_) {
                        ref.read(recommendationProvider.notifier).setCategoryFilter(cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Price Band Filter Chips
            Text(
              'Price Budget',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _priceBands.length,
                itemBuilder: (context, index) {
                  final pb = _priceBands[index];
                  final isSelected = recState.selectedPriceBand.toLowerCase() == pb['value']!.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(pb['label']!),
                      selectedColor: AppColors.purple.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.purple : (isDark ? Colors.grey[400] : Colors.grey[700]),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppColors.purple : Colors.transparent,
                        ),
                      ),
                      onSelected: (_) {
                        ref.read(recommendationProvider.notifier).setPriceBandFilter(pb['value']!);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Product Cards List
            if (products.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No products match the selected filters.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          ref.read(recommendationProvider.notifier).setCategoryFilter('All');
                          ref.read(recommendationProvider.notifier).setPriceBandFilter('All');
                        },
                        child: const Text('Clear Filters', style: TextStyle(color: AppColors.purple)),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Recommended Products (${products.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: products[index]);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineManagementTab(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    final allRoutines = ref.watch(skincareRoutineProvider);

    if (allRoutines.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa_outlined, color: AppColors.purple, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'No skincare routine added yet.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add products from AI recommendations or customize your daily skincare checklist.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _openAddEditRoutineModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Routine Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: allRoutines.length,
        itemBuilder: (context, index) {
          final item = allRoutines[index];
          final isMorning = item.routineType.toLowerCase() == 'morning';
          final isEvening = item.routineType.toLowerCase() == 'evening';

          final iconData = isMorning
              ? Icons.wb_sunny_rounded
              : (isEvening ? Icons.nightlight_round : Icons.access_time_filled_rounded);

          final badgeColor = isMorning
              ? AppColors.purple
              : (isEvening ? const Color(0xFF4A5568) : AppColors.rose);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(skincareRoutineProvider.notifier).toggleComplete(item.id),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: item.isCompleted ? AppColors.success : Colors.transparent,
                      border: Border.all(
                        color: item.isCompleted ? AppColors.success : AppColors.mutedLight,
                        width: 1.8,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: badgeColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.routineType.toUpperCase(),
                              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.time,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          color: item.isCompleted ? AppColors.muted : null,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.purple),
                  onPressed: () => _openAddEditRoutineModal(item),
                  tooltip: 'Edit routine',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                  onPressed: () {
                    ref.read(skincareRoutineProvider.notifier).deleteRoutine(item.id);
                  },
                  tooltip: 'Delete routine',
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditRoutineModal(),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Routine', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(
            3,
            (index) => Container(
              height: 140,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddEditRoutineBottomSheet extends ConsumerStatefulWidget {
  final SkincareRoutineItem? itemToEdit;

  const _AddEditRoutineBottomSheet({this.itemToEdit});

  @override
  ConsumerState<_AddEditRoutineBottomSheet> createState() => _AddEditRoutineBottomSheetState();
}

class _AddEditRoutineBottomSheetState extends ConsumerState<_AddEditRoutineBottomSheet> {
  final _productCtrl = TextEditingController();
  String _selectedRoutineType = 'Morning';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _productCtrl.text = item.productName;
      _selectedRoutineType = item.routineType;
      _selectedTime = _parseTimeString(item.time);
    }
  }

  TimeOfDay _parseTimeString(String raw) {
    try {
      final format = DateFormat.jm();
      final dt = format.parse(raw);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _onSave() {
    final product = _productCtrl.text.trim();
    if (product.isEmpty) {
      setState(() => _error = 'Please enter a product or skincare activity.');
      return;
    }

    final formattedTime = _formatTimeOfDay(_selectedTime);

    if (widget.itemToEdit != null) {
      final updated = widget.itemToEdit!.copyWith(
        productName: product,
        routineType: _selectedRoutineType,
        time: formattedTime,
      );
      ref.read(skincareRoutineProvider.notifier).updateRoutine(updated);
    } else {
      ref.read(skincareRoutineProvider.notifier).addRoutine(
            productName: product,
            routineType: _selectedRoutineType,
            time: formattedTime,
          );
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _productCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.itemToEdit != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEditing ? 'Edit Skincare Routine' : 'Add Skincare Routine',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 18),

              // Routine Type Selection
              Text('Routine Type', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.muted)),
              const SizedBox(height: 8),
              Row(
                children: ['Morning', 'Evening', 'Custom'].map((type) {
                  final isSelected = _selectedRoutineType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: AppColors.purple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRoutineType = type;
                            if (type == 'Morning') {
                              _selectedTime = const TimeOfDay(hour: 8, minute: 0);
                            } else if (type == 'Evening') {
                              _selectedTime = const TimeOfDay(hour: 21, minute: 0);
                            }
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              Text('Product Name', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.muted)),
              const SizedBox(height: 8),
              TextField(
                controller: _productCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Salicylic Acid Cleanser',
                  prefixIcon: Icon(Icons.spa_outlined, size: 20),
                ),
              ),

              const SizedBox(height: 18),
              Text('Reminder Time', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.muted)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.purple.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.purple.withOpacity(0.06),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTimeOfDay(_selectedTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Text('Change', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add to Routine', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
