import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../view_models/balance_sheet_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

final balanceSheetProvider = ChangeNotifierProvider(
  (ref) => BalanceSheetViewModel(),
);

class BalanceSheetScreen extends ConsumerWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(balanceSheetProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Balance Sheet', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date Range Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => vm.selectDate(context, true),
                    child: _DateBox(
                      title: 'Start Date',
                      dateLabel: vm.getFormattedDate(true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => vm.selectDate(context, false),
                    child: _DateBox(
                      title: 'End Date',
                      dateLabel: vm.getFormattedDate(false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Assets Section
            _buildSectionCard(
              title: "Assets",
              items: vm.assets,
              footer: "Total Assets: ${vm.formatCurrency(vm.totalAssets)}",
            ),

            const SizedBox(height: 20),

            // Liabilities Section
            _buildSectionCard(
              title: "Liabilities",
              items: vm.liabilities,
              footer:
                  "Total Liabilities: ${vm.formatCurrency(vm.totalLiabilities)}",
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black.withAlpha((0.3 * 255).round()),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                debugPrint("Download Balance Sheet tapped");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED1C24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Download PDF',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<String> items,
    required String footer,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            for (var item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            const Divider(thickness: 1),
            Text(
              footer,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String title;
  final String dateLabel;

  const _DateBox({required this.title, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateLabel, style: const TextStyle(fontSize: 14)),
              const Icon(Icons.calendar_today, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
