import '../widgets/header.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

void main() {
  runApp(const ExpensesApp());
}

class ExpensesApp extends StatelessWidget {
  const ExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rekord sa mga Gasto',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3C8DFF),
        scaffoldBackgroundColor: AppColors.surface,
        fontFamily: 'Roboto',
      ),
      home: const ExpensesScreen(),
    );
  }
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime selectedDate = DateTime.now();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? category;

  @override
  Widget build(BuildContext context) {
    final radius = 18.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Gasto', showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
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
                          onTap: _pickDate,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(selectedDate),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                        radius: radius,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Kantidad',
                        icon: Icons.payments_outlined,
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, right: 10),
                              child: Text(
                                '₱',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(fontSize: 20),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Ibutang kantidad',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                        radius: radius,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Kategorya',
                        icon: Icons.category_outlined,
                        child: ListTile(
                          title: Text(
                            category ?? 'Pili kategorya sa gasto',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(Icons.keyboard_arrow_down),
                          onTap: () => _showCategoryPicker(context),
                        ),
                        radius: radius,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Deskripsyon',
                        icon: Icons.notes_outlined,
                        child: TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            filled: false,
                            hintText: 'e.g., Tubig, Kuryente, Supplier Name',
                            border: InputBorder.none,
                          ),
                        ),
                        radius: radius,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Resibo (opsyonal)',
                        icon: Icons.receipt_long_outlined,
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _pillButton('Kuháha', onPressed: () {}),
                                _pillButton('Pili', onPressed: () {}),
                                _pillButton(
                                  'Tanggala',
                                  onPressed: () {},
                                  isDanger: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade100,
                                    Colors.grey.shade300,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        radius: radius,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.save_rounded, size: 22),
                    label: const Text(
                      'Irekord',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      backgroundColor: const Color(0xFF3C8DFF),
                      elevation: 8,
                      shadowColor: Colors.black26,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
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

  static Widget _pillButton(
    String label, {
    required VoidCallback onPressed,
    bool isDanger = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDanger
            ? const Color(0xFFE74C3C)
            : const Color(0xFF3C8DFF),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
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

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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
    if (dt != null) setState(() => selectedDate = dt);
  }

  void _showCategoryPicker(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
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
                    onTap: () => _setCategory(c),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _setCategory(String value) {
    setState(() => category = value);
    Navigator.of(context).pop();
  }
}
