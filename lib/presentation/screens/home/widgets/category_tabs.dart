import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/entities/category.dart';
import '../../../providers/news_providers.dart';

class CategoryTabs extends ConsumerWidget {
  final ValueChanged<int> onCategorySelected;
  const CategoryTabs({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 44,
      child: categoriesAsync.when(
        loading: () => _buildTabs(ref, [
          const Category(id: 0, name: 'الكل', slug: 'all', count: 0),
        ], 0),
        error: (_, __) => _buildTabs(ref, [
          const Category(id: 0, name: 'الكل', slug: 'all', count: 0),
        ], 0),
        data: (categories) {
          final allCategories = [
            const Category(id: 0, name: 'الكل', slug: 'all', count: 0),
            ...categories,
          ];
          return _buildTabs(ref, allCategories, selected);
        },
      ),
    );
  }

  Widget _buildTabs(WidgetRef ref, List<Category> categories, int selectedIndex) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = index == selectedIndex;

        return GestureDetector(
          onTap: () {
            ref.read(selectedCategoryProvider.notifier).state = index;
            onCategorySelected(cat.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(100),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              cat.name,
              style: AppTypography.labelMd.copyWith(
                color: isSelected
                    ? AppColors.onPrimary
                    : AppColors.secondary,
              ),
            ),
          ),
        );
      },
    );
  }
}
