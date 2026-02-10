// lib/view_models/income_statement_view_model.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/income_statement_model.dart';
import '../repositories/income_statement_repository.dart';
import '../providers/database_provider.dart';

// -----------------------------
// Provider
// -----------------------------
final incomeStatementViewModelProvider =
    StateNotifierProvider<
      IncomeStatementViewModel,
      AsyncValue<IncomeStatementModel>
    >((ref) {
      final dbAsync = ref.watch(databaseProvider);

      return dbAsync.when(
        data: (_) {
          final repository = IncomeStatementRepository(); // NO AccountRepository
          return IncomeStatementViewModel(repository);
        },
        loading: () {
          final repository = IncomeStatementRepository(); // NO AccountRepository
          return IncomeStatementViewModel(repository);
        },
        error: (_, _) => throw Exception('Database initialization failed'),
      );
    });

// -----------------------------
// ViewModel
// -----------------------------
class IncomeStatementViewModel
    extends StateNotifier<AsyncValue<IncomeStatementModel>> {
  final IncomeStatementRepository repository;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  IncomeStatementViewModel(this.repository) : super(const AsyncValue.loading());

  /// Load income statement for a given date range
  Future<void> load({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    this.startDate = startDate;
    this.endDate = endDate;

    state = const AsyncValue.loading();

    try {
      final data = await repository.fetchIncomeStatement(
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Export the current income statement to PDF
  Future<void> exportPdf() async {
    final data = state.value;
    if (data == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Income Statement",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              "Period: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}",
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // SALES
            pw.Text(
              "Sales",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            _pdfLeaderRow(
              "Merchandise Sales",
              data.merchandiseSales,
              indent: true,
            ),
            _pdfLeaderRow("TOTAL SALES", data.sales, bold: true, indent: true),
            pw.SizedBox(height: 12),

            // EXPENSES
            pw.Text(
              "Expenses",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            _pdfLeaderRow("Kompra", data.kompra, indent: true),
            _pdfLeaderRow("Kuryente / Tubig", data.electricity, indent: true),
            _pdfLeaderRow("Transportation", data.transportation, indent: true),
            _pdfLeaderRow("Mga Bayronon", data.rentPayment, indent: true),
            _pdfLeaderRow("Uban Pa", data.miscExpenses, indent: true),
            pw.Divider(),
            _pdfLeaderRow("NET INCOME", data.netIncome, bold: true),
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

  /// Helper for PDF row formatting
  pw.Widget _pdfLeaderRow(
    String title,
    double value, {
    bool bold = false,
    bool indent = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: indent ? 16 : 0, bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              '.' * 80,
              maxLines: 1,
              style: pw.TextStyle(color: PdfColors.grey),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(value),
          ),
        ],
      ),
    );
  }
}
