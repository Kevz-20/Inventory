import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../view_models/expenses_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(expensesViewModelProvider);
    final notifier = ref.read(expensesViewModelProvider.notifier);
    final radius = 18.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Gasto', showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionCard(
                      title: 'Petsa',
                      icon: Icons.calendar_month_outlined,
                      child: GestureDetector(
                        onTap: () async {
                          final dt = await showDatePicker(
                            context: context,
                            initialDate: vm.selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF3C8DFF),
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (dt != null) notifier.setDate(dt);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(vm.selectedDate),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, size: 28),
                          ],
                        ),
                      ),
                      radius: radius,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Kategorya',
                      icon: Icons.category_outlined,
                      child: ListTile(
                        title: Text(
                          vm.category ?? 'Pili kategorya sa gasto',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.keyboard_arrow_down),
                        onTap: () => _showCategoryPicker(context, notifier),
                      ),
                      radius: radius,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, ExpensesViewModel notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        final categories = ['Food & Drinks', 'Bills', 'Supplies', 'Others'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories
                .map(
                  (c) => ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(c),
                    onTap: () {
                      notifier.setCategory(c);
                      Navigator.of(context).pop();
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    double radius = 16,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF5F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3C8DFF)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, height: 20, color: Colors.black12),
          child,
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
