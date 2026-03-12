import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/income_statement_model.dart';
import '../repositories/income_statement_repository.dart';

final incomeStatementViewModelProvider =
    StateNotifierProvider<IncomeStatementViewModel, AsyncValue<IncomeStatementModel>>((ref) {
      return IncomeStatementViewModel(IncomeStatementRepository());
    });

class IncomeStatementViewModel extends StateNotifier<AsyncValue<IncomeStatementModel>> {
  final IncomeStatementRepository repository;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  pw.Font? _ttfFont;

  IncomeStatementViewModel(this.repository) : super(const AsyncValue.loading());

  Future<void> _loadFont() async {
    if (_ttfFont == null) {
      final fontData = await rootBundle.load('lib/assets/fonts/Roboto-Regular.ttf');
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

          return pw.Container(
            padding: const pw.EdgeInsets.all(28),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColor.fromInt(0xFFD6E6E0)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FINANCIAL REPORT',
                          style: pw.TextStyle(
                            font: _ttfFont,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF35695B),
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Income Statement',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            font: _ttfFont,
                            color: PdfColor.fromInt(0xFF143D34),
                          ),
                        ),
                      ],
                    ),
                    _pdfDateBadge(),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Container(
                  height: 3,
                  width: 64,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF0C6A57),
                  ),
                ),
                pw.SizedBox(height: 20),
                _pdfSectionCard(
                  title: 'Sales',
                  totalLabel: 'Total Sales',
                  totalValue: data.sales,
                  rows: [
                    _PdfDataRow(label: 'Merchandise Sales', value: data.merchandiseSales),
                  ],
                ),
                pw.SizedBox(height: 14),
                _pdfSectionCard(
                  title: 'Expenses',
                  totalLabel: 'Total Expenses',
                  totalValue: data.totalExpenses,
                  rows: expenseEntries.isEmpty
                      ? const [
                          _PdfDataRow(label: 'No expense records', value: 0, muted: true),
                        ]
                      : expenseEntries
                          .map((entry) => _PdfDataRow(label: entry.key, value: entry.value))
                          .toList(),
                ),
                pw.SizedBox(height: 18),
                _pdfNetIncomeCard(data.netIncome),
              ],
            ),
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

  pw.Widget _pdfDateBadge() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEAF5F1),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFCFE1DB)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PERIOD',
            style: pw.TextStyle(
              font: _ttfFont,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF35695B),
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
            style: pw.TextStyle(
              font: _ttfFont,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF143D34),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionCard({
    required String title,
    required String totalLabel,
    required double totalValue,
    required List<_PdfDataRow> rows,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FBFA),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFDCE9E4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: _ttfFont,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF143D34),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 1, color: PdfColor.fromInt(0xFFDCE9E4)),
          pw.SizedBox(height: 10),
          ...rows.map(_pdfRow),
          pw.SizedBox(height: 8),
          pw.Container(height: 1, color: PdfColor.fromInt(0xFFDCE9E4)),
          pw.SizedBox(height: 10),
          _pdfTotalRow(totalLabel, totalValue),
        ],
      ),
    );
  }

  pw.Widget _pdfRow(_PdfDataRow row) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              row.label,
              style: pw.TextStyle(
                font: _ttfFont,
                fontSize: 10.5,
                color: row.muted ? PdfColors.grey700 : PdfColor.fromInt(0xFF223F39),
                fontStyle: row.muted ? pw.FontStyle.italic : pw.FontStyle.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            row.muted ? '-' : _pdfMoney(row.value),
            style: pw.TextStyle(
              font: _ttfFont,
              fontSize: 10.5,
              fontWeight: row.muted ? pw.FontWeight.normal : pw.FontWeight.bold,
              color: row.muted ? PdfColors.grey700 : PdfColor.fromInt(0xFF223F39),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTotalRow(String label, double value) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              font: _ttfFont,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF143D34),
              letterSpacing: 0.4,
            ),
          ),
        ),
        pw.Text(
          _pdfMoney(value),
          style: pw.TextStyle(
            font: _ttfFont,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF143D34),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfNetIncomeCard(double netIncome) {
    final isPositive = netIncome >= 0;
    final accent = isPositive
        ? PdfColor.fromInt(0xFF0C6A57)
        : PdfColor.fromInt(0xFFC04B43);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: pw.BoxDecoration(
        color: isPositive
            ? PdfColor.fromInt(0xFFEAF5F1)
            : PdfColor.fromInt(0xFFF9ECEA),
        border: pw.Border.all(color: accent),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FINAL RESULT',
                style: pw.TextStyle(
                  font: _ttfFont,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Net Income',
                style: pw.TextStyle(
                  font: _ttfFont,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF143D34),
                ),
              ),
            ],
          ),
          pw.Text(
            _pdfMoney(netIncome),
            style: pw.TextStyle(
              font: _ttfFont,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  String _pdfMoney(double value) {
    return NumberFormat.currency(
      symbol: 'PHP ',
      decimalDigits: 2,
    ).format(value);
  }
}

class _PdfDataRow {
  const _PdfDataRow({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final double value;
  final bool muted;
}
