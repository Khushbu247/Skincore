import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/product_recommendation.dart';
import '../../../../providers/skincare_routine_provider.dart';
import 'product_detail_sheet.dart';

class ProductCard extends ConsumerWidget {
  final RecommendedProductItem product;

  const ProductCard({super.key, required this.product});

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

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(product: product),
    );
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
                Text('Add to My Routine'),
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
                  const SizedBox(height: 4),
                  Text(
                    'Brand: ${product.brand}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Routine Type:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Morning', 'Evening', 'Custom'].map((type) {
                      final isSelected = routineType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
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
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Reminder Time:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Brand & Suitability Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.brand.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          '${product.suitabilityBadge} (${product.suitabilityScore.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Main Row: Image + Name + Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      product.imageUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 76,
                        height: 76,
                        color: AppColors.purple.withOpacity(0.1),
                        child: const Icon(Icons.sanitizer_outlined, color: AppColors.purple, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '₹${product.priceInr.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.rose,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.usageTime,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ingredient Pills
              if (product.keyIngredients.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: product.keyIngredients.take(3).map((ing) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ing,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],

              // Why it works snippet
              if (product.whyItWorks.isNotEmpty) ...[
                Text(
                  'Why it works: ${product.whyItWorks}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Actions: Add to Routine & Buy Now
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openAddRoutineDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.purple),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.purple),
                      label: const Text(
                        'Add to Routine',
                        style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (product.buyUrl.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: () => _launchBuyUrl(product.buyUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text('Buy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
