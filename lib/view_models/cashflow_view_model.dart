import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cashflow_model.dart';
import 'package:intl/intl.dart';

// -------------------
// Provider
// -------------------
final cashflowViewModelProvider =
    ChangeNotifierProvider<CashflowViewModel>((ref) {
  return CashflowViewModel();
});

// -------------------
// ViewModel
// -------------------
class CashflowViewModel extends ChangeNotifier {
  final List<CashflowRecord> _records = [];

  DateTime? startDate;
  DateTime? endDate;

  List<CashflowRecord> get filteredRecords {
    return _records.where((r) {
      final afterStart = startDate == null || !r.date.isBefore(startDate!);
      final beforeEnd = endDate == null || !r.date.isAfter(endDate!);
      return afterStart && beforeEnd;
    }).toList();
  }

  List<double> get runningBalances {
    double balance = 0;
    return filteredRecords.map((r) {
      balance += r.cashIn - r.cashOut;
      return balance;
    }).toList();
  }

  void addRecord(CashflowRecord record) {
    _records.add(record);
    notifyListeners();
  }

  void updateRecord(int index, CashflowRecord record) {
    _records[index] = record;
    notifyListeners();
  }

  void showCashflowDialog(BuildContext context,
      {CashflowRecord? record, int? index}) {
    final itemCtrl = TextEditingController(text: record?.item ?? '');
    final inCtrl = TextEditingController(
        text: record?.cashIn == 0 ? '' : record!.cashIn.toString());
    final outCtrl = TextEditingController(
        text: record?.cashOut == 0 ? '' : record!.cashOut.toString());

    DateTime selectedDate = record?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              record == null ? 'Add Cashflow' : 'Edit Cashflow',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Item
            TextField(
              controller: itemCtrl,
              decoration: const InputDecoration(labelText: 'Item'),
            ),
            const SizedBox(height: 10),

            // Cash In
            TextField(
              controller: inCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cash In'),
              onChanged: (_) => outCtrl.clear(),
            ),
            const SizedBox(height: 10),

            // Cash Out
            TextField(
              controller: outCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cash Out'),
              onChanged: (_) => inCtrl.clear(),
            ),
            const SizedBox(height: 10),

            // Date picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) selectedDate = picked;
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (itemCtrl.text.isEmpty) return;

                    final newRecord = CashflowRecord(
                      date: selectedDate,
                      item: itemCtrl.text,
                      cashIn: double.tryParse(inCtrl.text) ?? 0,
                      cashOut: double.tryParse(outCtrl.text) ?? 0,
                    );

                    if (record == null) {
                      addRecord(newRecord);
                    } else {
                      updateRecord(index!, newRecord);
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}
