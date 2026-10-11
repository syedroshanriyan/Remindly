import 'package:flutter/material.dart';

class SegmentedTabs extends StatelessWidget {
  final int selectedIndex;

  final ValueChanged<int> onChanged;

  const SegmentedTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Today',
      'Schedule',
      'Completed',
      'All',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: List.generate(
            labels.length,
            (index) {
              final selected = selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(
                    index,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
