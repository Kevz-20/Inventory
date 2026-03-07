// lib/view_models/income_statement_view_model.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/income_statement_model.dart';
import '../repositories/income_statement_repository.dart';

// -----------------------------
// Provider
// -----------------------------
final incomeStatementViewModelProvider =
    StateNotifierProvider<
      IncomeStatementViewModel,
      AsyncValue<IncomeStatementModel>
    >((ref) {
      return IncomeStatementViewModel(IncomeStatementRepository());
    });

// -----------------------------
// ViewModel
// -----------------------------
class IncomeStatementViewModel
    extends StateNotifier<AsyncValue<IncomeStatementModel>> {
  final IncomeStatementRepository repository;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  pw.Font? _ttfFont;

  IncomeStatementViewModel(this.repository) : super(const AsyncValue.loading());

  Future<void> _loadFont() async {
    if (_ttfFont == null) {
      final fontData = await rootBundle.load(
        'lib/assets/fonts/Roboto-Regular.ttf',
      );
      _ttfFont = pw.Font.ttf(fontData);
    }
  }

  Future<void> load({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    this.startDate = startDate;
    this.endDate = endDate;

    if (!mounted) return;
    state = const AsyncValue.loading();

    try {
      final data = await repository.fetchIncomeStatement(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> exportPdf() async {
    final data = state.value;
    if (data == null) return;

    await _loadFont();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final expenseEntries = data.expenseCategories.entries.toList()
            ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Income Statement",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                "Period: ${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}",
                style: pw.TextStyle(font: _ttfFont),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),

              pw.Text(
                "Sales",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              _pdfLeaderRow(
                "Merchandise Sales",
                data.merchandiseSales,
                indent: true,
              ),
              _pdfLeaderRow(
                "TOTAL SALES",
                data.sales,
                bold: true,
                indent: true,
              ),
              pw.SizedBox(height: 12),

              pw.Text(
                "Expenses",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),

              if (expenseEntries.isEmpty)
                _pdfLeaderRow("No expenses", 0, indent: true)
              else
                ...expenseEntries.map(
                  (entry) => _pdfLeaderRow(
                    entry.key,
                    entry.value,
                    indent: true,
                  ),
                ),

              pw.Divider(),
              _pdfLeaderRow(
                "TOTAL EXPENSES",
                data.totalExpenses,
                bold: true,
              ),
              pw.SizedBox(height: 8),
              _pdfLeaderRow(
                "NET INCOME",
                data.netIncome,
                bold: true,
              ),
            ],
          );
        },
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
              font: _ttfFont,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              '.' * 80,
              maxLines: 1,
              style: pw.TextStyle(
                color: PdfColors.grey,
                font: _ttfFont,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            NumberFormat.currency(
              symbol: '₱',
              decimalDigits: 2,
            ).format(value),
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              font: _ttfFont,
            ),
          ),
        ],
      ),
    );
  }
}