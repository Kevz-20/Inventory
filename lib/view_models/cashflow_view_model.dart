import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CashflowType { income, expense }

class CashflowRecord {
  final int? id;
  final String description;
  final double amount;
  final CashflowType type;
  final DateTime date;

  CashflowRecord({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  String get formattedDate => DateFormat('yyyy-MM-dd').format(date);

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'type': type == CashflowType.income ? 'income' : 'expense',
      'date': date.toIso8601String(),
    };
  }

  factory CashflowRecord.fromMap(Map<String, dynamic> map) {
    return CashflowRecord(
      id: map['id'] as int?,
      description: map['description'],
      amount: map['amount'],
      type: map['type'] == 'income'
          ? CashflowType.income
          : CashflowType.expense,
      date: DateTime.parse(map['date']),
    );
  }
}

// Use ChangeNotifierProvider for Riverpod
final cashflowViewModelProvider = ChangeNotifierProvider<CashflowViewModel>((
  ref,
) {
  return CashflowViewModel();
});

class CashflowViewModel extends ChangeNotifier {
  List<CashflowRecord> cashflowRecords = [];

  DateTime? startDate;
  DateTime? endDate;

  String get formattedStartDate =>
      startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : '';
  String get formattedEndDate =>
      endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : '';

  void setStartDate(DateTime date) {
    startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    endDate = date;
    notifyListeners();
  }

  // ---------------------------
  // Fetch records from DB using DBService helpers
  // ---------------------------

  // ---------------------------
  // Show Add Cashflow Dialog
  // ---------------------------
  void showAddCashflowDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    CashflowType type = CashflowType.expense;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Add Cashflow",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Amount (numbers only)
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Type selection as single words
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _typeButton('Income', type == CashflowType.income, () {
                        setState(() => type = CashflowType.income);
                      }),
                      _typeButton('Expense', type == CashflowType.expense, () {
                        setState(() => type = CashflowType.expense);
                      }),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (descriptionController.text.isEmpty ||
                                amountController.text.isEmpty)
                              // ignore: curly_braces_in_flow_control_structures
                              return;

                            // final record = CashflowRecord(
                            //   description: descriptionController.text,
                            //   amount: double.parse(amountController.text),
                            //   type: type,
                            //   date: selectedDate,
                            // );

                            // await addCashflow(record);
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          },
                          child: const Text("Add"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper button for type selection
  Widget _typeButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
