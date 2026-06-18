import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class ChipsRow extends StatelessWidget {
  final List<String> chips;
  final String? selectedChip;
  final Function(String)? onChipSelected;

  const ChipsRow({
    super.key,
    required this.chips,
    this.selectedChip,
    this.onChipSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = chip == selectedChip;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(chip),
              selected: isSelected,
              onSelected: (selected) {
                if (onChipSelected != null) {
                  onChipSelected!(chip);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
