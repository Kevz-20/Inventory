import '../widgets/header.dart';
import 'package:flutter/material.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
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
    final double radius = 18;

    return Scaffold(
      backgroundColor: const Color(0xFFf6f1ea),
      appBar: const AppHeader(
        title: 'Rekord sa mga Gasto',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              _buildCard(
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, right: 12.0),
                      child: Text(
                        'Petsa',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                    ),
                  ],
                ),
                radius: radius,
              ),
              const SizedBox(height: 14),
              _buildCard(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12.0, right: 8.0),
                      child: Text(
                        '₱',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    hintText: 'Ibutang kantidad',
                    hintStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  style: const TextStyle(fontSize: 20),
                ),
                radius: radius,
              ),
              const SizedBox(height: 14),
              _buildCard(
                child: ListTile(
                  title: Text(
                    category ?? 'Kategorya sa Gasto',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                  onTap: () => _showCategoryPicker(context),
                ),
                radius: radius,
              ),
              const SizedBox(height: 14),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Deskripsyon (Gikinahanglan)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g., Water bill, Supplier Name',
                      ),
                    ),
                    const Divider(color: Colors.grey, thickness: 1),
                  ],
                ),
                radius: radius,
              ),
              const SizedBox(height: 14),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.camera_alt_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Resibo (opsyonal)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _pillButton('Photo', onPressed: () {}),
                        _pillButton('Choose', onPressed: () {}),
                        _pillButton('Remove', onPressed: () {}, isDanger: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                radius: radius,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    backgroundColor: const Color(0xFF3C8DFF),
                    elevation: 8,
                    shadowColor: Colors.black26,
                  ),
                  child: const Text(
                    'Rekord',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, double radius = 16}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
            ? const Color(0xFFef5960)
            : const Color(0xFF3C8DFF),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
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
    );
    if (dt != null) setState(() => selectedDate = dt);
  }

  void _showCategoryPicker(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Food & Drinks'),
                onTap: () => _setCategory('Food & Drinks'),
              ),
              ListTile(
                title: const Text('Bills'),
                onTap: () => _setCategory('Bills'),
              ),
              ListTile(
                title: const Text('Supplies'),
                onTap: () => _setCategory('Supplies'),
              ),
              ListTile(
                title: const Text('Others'),
                onTap: () => _setCategory('Others'),
              ),
            ],
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
