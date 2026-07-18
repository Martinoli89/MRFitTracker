import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const List<_NavigationItem> _items = [
    _NavigationItem(
      label: 'Inicio',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavigationItem(
      label: 'Historial',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
    ),
    _NavigationItem(
      label: 'Progreso',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      margin: const EdgeInsets.fromLTRB(
        18,
        4,
        18,
        12,
      ),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.28,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0;
              index < _items.length;
              index++)
            Expanded(
              // El seleccionado recibe más espacio.
              flex: selectedIndex == index ? 14 : 9,
              child: _NavigationButton(
                item: _items[index],
                isSelected: selectedIndex == index,
                onTap: () {
                  onSelected(index);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final _NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 240,
            ),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 11 : 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.wineDark
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(
                      color: AppColors.wine.withValues(
                        alpha: 0.7,
                      ),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  isSelected
                      ? item.selectedIcon
                      : item.icon,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  size: 22,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}