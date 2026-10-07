import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/skincare_routine.dart';
import '../../../providers/skincare_routine_provider.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  final String prediction;

  const RecommendationsScreen({super.key, this.prediction = 'acne'});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Morning', 'Evening', 'Custom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddEditModal([SkincareRoutineItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditRoutineBottomSheet(itemToEdit: item),
    );
  }

  void _confirmDelete(SkincareRoutineItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Routine Item?'),
        content: Text('Are you sure you want to delete "${item.productName}" from your routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(skincareRoutineProvider.notifier).deleteRoutine(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.productName} deleted.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allRoutines = ref.watch(skincareRoutineProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Skincare Routine Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.purple, size: 24),
            onPressed: () => _openAddEditModal(),
            tooltip: 'Add Skincare Routine',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.purple,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.purple,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tabCategory) {
          final filtered = tabCategory == 'All'
              ? allRoutines
              : allRoutines.where((r) => r.routineType.toLowerCase() == tabCategory.toLowerCase()).toList();

          // Sort chronologically by time string display
          filtered.sort((a, b) => a.time.compareTo(b.time));

          if (filtered.isEmpty) {
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
                        color: AppColors.purple.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.spa_outlined, color: AppColors.purple, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No skincare routine added yet.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first routine to get personalized reminders.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openAddEditModal(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Add First Routine',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
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
                  border: Border.all(
                    color: isDark ? AppColors.lineDark : AppColors.lineLight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: badgeColor, size: 22),
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
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.routineType.toUpperCase(),
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.time,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.purple),
                      onPressed: () => _openAddEditModal(item),
                      tooltip: 'Edit routine',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                      onPressed: () => _confirmDelete(item),
                      tooltip: 'Delete routine',
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Routine', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _AddEditRoutineBottomSheet extends ConsumerStatefulWidget {
  final SkincareRoutineItem? itemToEdit;

  const _AddEditRoutineBottomSheet({this.itemToEdit});

  @override
  ConsumerState<_AddEditRoutineBottomSheet> createState() =>
      _AddEditRoutineBottomSheetState();
}

class _AddEditRoutineBottomSheetState
    extends ConsumerState<_AddEditRoutineBottomSheet> {
  final _productCtrl = TextEditingController();
  String _selectedRoutineType = 'Morning';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String? _error;

  final List<String> _suggestedProducts = [
    'Face Wash',
    'Vitamin C Serum',
    'Moisturizer',
    'Sunscreen',
    'Retinol',
    'Acne Treatment',
    'Gentle Cleanser',
    'Niacinamide Serum',
    'Toner',
  ];

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
      setState(() {
        _selectedTime = picked;
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine updated successfully!')),
      );
    } else {
      ref.read(skincareRoutineProvider.notifier).addRoutine(
            productName: product,
            routineType: _selectedRoutineType,
            time: formattedTime,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine added successfully!')),
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                isEditing ? 'Edit Skincare Routine' : 'Add Skincare Routine',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 18),

              // Routine Type Selection
              Text(
                'Routine Type',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                ),
              ),
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

              // Product / Activity Name Field
              Text(
                'Product / Activity Name',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _productCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Vitamin C Serum, Sunscreen',
                  prefixIcon: Icon(Icons.spa_outlined, size: 20),
                ),
              ),

              const SizedBox(height: 10),

              // Quick Product Suggestions
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _suggestedProducts.map((p) {
                  return ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      setState(() {
                        _productCtrl.text = p;
                        _error = null;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Time Selection
              Text(
                'Reminder Time',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.purple.withValues(alpha: 0.06),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.purple, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _formatTimeOfDay(_selectedTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],

              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add to Routine',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
