import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final String placeholder;
  final List<String> items;
  final String? selectedValue;
  final Function(String?) onChanged;
  final bool compact;
  final Color? textColor;
  final Color? borderColor;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.placeholder,
    required this.items,
    this.selectedValue,
    required this.onChanged,
    this.compact = false,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final double spacing = compact ? 2 : 8;
    final double innerHeight = compact ? 34 : 40;
    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;

    // Use provided colors or default based on theme
    final effectiveTextColor =
        textColor ?? (isLightMode ? Colors.black : Colors.white);
    final effectiveBorderColor =
        borderColor ?? (isLightMode ? Colors.black : Colors.white);
    final hintColor = isLightMode ? Colors.black54 : Colors.white70;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: spacing),
        Container(
          width: double.infinity,
          padding:
              EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 4 : 8),
          decoration: BoxDecoration(
            color: isLightMode ? Colors.white : AppTheme.transparentBackground,
            border: Border.all(
              color: effectiveBorderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
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
                  color: hintColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              underline: const SizedBox.shrink(),
              isExpanded: true,
              dropdownColor: isLightMode ? Colors.white : AppTheme.primaryColor,
              menuMaxHeight: compact ? 250 : 300,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: effectiveTextColor,
              ),
              iconSize: compact ? 18 : 20,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
