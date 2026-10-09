import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/product_recommendation.dart';
import '../../../../providers/skincare_routine_provider.dart';

class ProductDetailSheet extends ConsumerWidget {
  final RecommendedProductItem product;

  const ProductDetailSheet({super.key, required this.product});

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'highly suitable':
        return Colors.green.shade700;
      case 'suitable':
        return AppColors.purple;
      case 'potentially suitable':
        return Colors.amber.shade800;
      default:
        return AppColors.muted;
    }
  }

  void _openAddRoutineDialog(BuildContext context, WidgetRef ref) {
    String routineType = product.usageTime.contains('PM') && !product.usageTime.contains('AM')
        ? 'Evening'
        : 'Morning';
    TimeOfDay selectedTime = routineType == 'Evening'
        ? const TimeOfDay(hour: 21, minute: 0)
        : const TimeOfDay(hour: 8, minute: 0);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_task_rounded, color: AppColors.purple),
                SizedBox(width: 8),
                Expanded(child: Text('Add to My Routine', overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select Routine Type:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['Morning', 'Evening', 'Custom'].map((type) {
                      final isSelected = routineType == type;
                      return ChoiceChip(
                          label: Text(type, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          selectedColor: AppColors.purple,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                routineType = type;
                                if (type == 'Morning') {
                                  selectedTime = const TimeOfDay(hour: 8, minute: 0);
                                } else if (type == 'Evening') {
                                  selectedTime = const TimeOfDay(hour: 21, minute: 0);
                                }
                              });
                            }
                          },
                        );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Reminder Time:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.purple.withOpacity(0.06),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimeOfDay(selectedTime),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text('Change', style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final formattedTime = _formatTimeOfDay(selectedTime);
                  ref.read(skincareRoutineProvider.notifier).addRoutine(
                        productName: product.name,
                        routineType: routineType,
                        time: formattedTime,
                      );
                  Navigator.pop(dialogCtx);
                  Navigator.pop(context); // Close detail sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${product.name}" to $routineType routine ($formattedTime).'),
                      backgroundColor: AppColors.purple,
                    ),
                  );
                },
                child: const Text('Add to Routine'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _launchBuyUrl(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final badgeColor = _getBadgeColor(product.suitabilityBadge);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag handle
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

              // Hero Image & Badges
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  product.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 200,
                    color: AppColors.purple.withOpacity(0.1),
                    child: const Icon(Icons.sanitizer_outlined, color: AppColors.purple, size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Brand & Suitability Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.purple,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${product.suitabilityBadge} (${product.suitabilityScore.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Product Name & Price
              Text(
                product.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '₹${product.priceInr.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rose,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Chip(
                    label: Text(product.usageTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.purple.withOpacity(0.1),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description Section
              if (product.description.isNotEmpty) ...[
                Text('Description', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
                const SizedBox(height: 16),
              ],

              // Why it works AI Rationale Section
              if (product.whyItWorks.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.purple.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome_rounded, color: AppColors.purple, size: 18),
                          SizedBox(width: 6),
                          Text('Why it works for you', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.whyItWorks,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Key Active Ingredients
              if (product.keyIngredients.isNotEmpty) ...[
                Text('Key Active Ingredients', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: product.keyIngredients.map((ing) {
                    return Chip(
                      avatar: const Icon(Icons.science_outlined, size: 14, color: AppColors.purple),
                      label: Text(ing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      backgroundColor: AppColors.purple.withOpacity(0.1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // How To Use Guidance
              if (product.howToUse.isNotEmpty) ...[
                Text('How to Use', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          product.howToUse,
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Warnings / Conflicts
              if (product.warningsOrConflicts.isNotEmpty) ...[
                Text('Safety & Warnings', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...product.warningsOrConflicts.map((warn) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warn,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade800, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Actions: Add to Routine & Buy Now
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openAddRoutineDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppColors.purple, width: 1.5),
                      ),
                      icon: const Icon(Icons.add_rounded, color: AppColors.purple),
                      label: const Text(
                        'Add to Routine',
                        style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  if (product.buyUrl.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchBuyUrl(product.buyUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
