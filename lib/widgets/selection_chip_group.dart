import 'package:flutter/material.dart';

class SelectionChipGroup<T> extends StatelessWidget {
  const SelectionChipGroup({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.onSelected,
  });

  final List<T> values;
  final T? selectedValue;
  final String Function(T value) labelBuilder;
  final IconData Function(T value) iconBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values
          .map(
            (value) => ChoiceChip(
              selected: value == selectedValue,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconBuilder(value), size: 18),
                  const SizedBox(width: 8),
                  Text(labelBuilder(value)),
                ],
              ),
              onSelected: (_) => onSelected(value),
            ),
          )
          .toList(),
    );
  }
}
