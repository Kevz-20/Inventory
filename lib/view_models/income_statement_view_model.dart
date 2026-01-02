import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/income_statement_model.dart';
import '../providers/database_provider.dart';
import '../repositories/account_repository.dart';
import '../repositories/income_statement_repository.dart';

final incomeStatementViewModelProvider =
    StateNotifierProvider<
      IncomeStatementViewModel,
      AsyncValue<IncomeStatementModel>
    >((ref) {
      final dbAsync = ref.watch(databaseProvider);

      return dbAsync.when(
        data: (db) {
          final accountRepository = AccountRepository();
          final repository = IncomeStatementRepository(
            accountRepository: accountRepository,
          );
          return IncomeStatementViewModel(repository);
        },
        loading: () => IncomeStatementViewModel(null),
        error: (_, _) => throw Exception('Database initialization failed'),
      );
    });

class IncomeStatementViewModel
    extends StateNotifier<AsyncValue<IncomeStatementModel>> {
  final IncomeStatementRepository? repository;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  IncomeStatementViewModel(this.repository) : super(const AsyncValue.loading());

  Future<void> load({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (repository == null) return;

    this.startDate = startDate;
    this.endDate = endDate;

    state = const AsyncValue.loading();

    try {
      final result = await repository!.fetchIncomeStatement(
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(result);
      debugPrint('debug: Income statement loaded successfully: $result');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      debugPrint('debug: Error loading income statement: $e\n$st');
    }
  }

  Future<void> exportPdf() async {
    final data = state.value;
    if (data == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Income Statement",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              "Period: ${startDate.toString().substring(0, 10)}  -  ${endDate.toString().substring(0, 10)}",
            ),
            pw.Divider(),
            pw.SizedBox(height: 12),
            _row("Sales", data.sales),
            _row("Merchandise Sales", data.merchandiseSales),
            _row("Total Sales", data.sales),
            pw.SizedBox(height: 12),
            _row("Expenses", data.totalExpenses),
            _row("Kumpra", data.kumpra),
            _row("Transportation", data.transportation),
            _row("Total Expenses", data.totalExpenses),
            pw.Divider(),
            _row("Net Income", data.netIncome),
          ],
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/income_statement.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error saving or opening PDF: $e');
    }
  }

  pw.Widget _row(String title, double value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(title), pw.Text(value.toStringAsFixed(2))],
    );
  }
}
