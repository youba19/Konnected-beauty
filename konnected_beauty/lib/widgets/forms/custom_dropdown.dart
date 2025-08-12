import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final String placeholder;
  final List<String> items;
  final String? selectedValue;
  final Function(String?) onChanged;
  final bool compact;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.placeholder,
    required this.items,
    this.selectedValue,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double labelFont = compact ? 12 : 16;
    final double spacing = compact ? 2 : 8;
    final double innerHeight = compact ? 34 : 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: labelFont,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: spacing),
        Container(
          width: double.infinity,
          padding:
              EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 4 : 8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            border: Border.all(color: AppTheme.borderColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: innerHeight,
            child: DropdownButton<String>(
              value: selectedValue != null && items.contains(selectedValue)
                  ? selectedValue
                  : null,
              hint: Text(
                selectedValue ?? placeholder,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: compact ? 12 : 14,
                ),
              ),
              underline: const SizedBox.shrink(),
              isExpanded: true,
              dropdownColor: AppTheme.secondaryColor,
              menuMaxHeight: compact ? 250 : 300,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.textPrimaryColor,
              ),
              iconSize: compact ? 18 : 20,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
