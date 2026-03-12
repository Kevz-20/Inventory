import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../repositories/balancesheet_repository.dart';

class BalanceSheetViewModel extends ChangeNotifier {
  final BalanceSheetRepository repository = BalanceSheetRepository();

  Map<String, double> assets = {};
  Map<String, double> liabilities = {};
  Map<String, double> equity = {};

  double get totalAssets => assets.values.fold(0, (prev, cur) => prev + cur);
  double get totalLiabilities =>
      liabilities.values.fold(0, (prev, cur) => prev + cur);
  double get totalEquity => equity.values.fold(0, (prev, cur) => prev + cur);

  pw.Font? _ttfFont;

  Future<void> _loadFont() async {
    if (_ttfFont == null) {
      final fontData =
          await rootBundle.load('lib/assets/fonts/Roboto-Regular.ttf');
      _ttfFont = pw.Font.ttf(fontData);
    }
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: 'PHP ');
    return formatter.format(value);
  }

  String _pdfMoney(double value) {
    return NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2).format(value);
  }

  Future<void> loadBalanceSheet() async {
    assets = await repository.getAssets();
    liabilities = await repository.getLiabilities();
    equity = await repository.getEquity();
    notifyListeners();
  }

  Future<void> exportPdf() async {
    await _loadFont();

    final pdf = pw.Document();
    final asOfText = DateFormat('MMM dd, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
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
                          'Balance Sheet',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            font: _ttfFont,
                            color: PdfColor.fromInt(0xFF143D34),
                          ),
                        ),
                      ],
                    ),
                    _pdfDateBadge(asOfText),
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
                  title: 'Assets',
                  totalLabel: 'Total Assets',
                  totalValue: totalAssets,
                  rows: assets.isEmpty
                      ? const [
                          _PdfDataRow(
                            label: 'No records yet.',
                            value: 0,
                            muted: true,
                          ),
                        ]
                      : assets.entries
                          .map((e) => _PdfDataRow(label: e.key, value: e.value))
                          .toList(),
                ),
                pw.SizedBox(height: 14),
                _pdfSectionCard(
                  title: 'Liabilities',
                  totalLabel: 'Total Liabilities',
                  totalValue: totalLiabilities,
                  rows: liabilities.isEmpty
                      ? const [
                          _PdfDataRow(
                            label: 'No records yet.',
                            value: 0,
                            muted: true,
                          ),
                        ]
                      : liabilities.entries
                          .map((e) => _PdfDataRow(label: e.key, value: e.value))
                          .toList(),
                ),
                pw.SizedBox(height: 14),
                _pdfSectionCard(
                  title: "Owner's Equity",
                  totalLabel: 'Total Equity',
                  totalValue: totalEquity,
                  rows: equity.isEmpty
                      ? const [
                          _PdfDataRow(
                            label: 'No records yet.',
                            value: 0,
                            muted: true,
                          ),
                        ]
                      : equity.entries
                          .map((e) => _PdfDataRow(label: e.key, value: e.value))
                          .toList(),
                ),
                pw.SizedBox(height: 18),
                _pdfFinalTotalCard(
                  'Total Liabilities + Equity',
                  totalLiabilities + totalEquity,
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/balance_sheet.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error saving or opening PDF: $e');
    }
  }

  pw.Widget _pdfDateBadge(String asOfText) {
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
            'AS OF',
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
            asOfText,
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
                color: row.muted
                    ? PdfColors.grey700
                    : PdfColor.fromInt(0xFF223F39),
                fontStyle:
                    row.muted ? pw.FontStyle.italic : pw.FontStyle.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            row.muted ? '-' : _pdfMoney(row.value),
            style: pw.TextStyle(
              font: _ttfFont,
              fontSize: 10.5,
              fontWeight:
                  row.muted ? pw.FontWeight.normal : pw.FontWeight.bold,
              color: row.muted
                  ? PdfColors.grey700
                  : PdfColor.fromInt(0xFF223F39),
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

  pw.Widget _pdfFinalTotalCard(String label, double value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEAF5F1),
        border: pw.Border.all(color: PdfColor.fromInt(0xFF0C6A57)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FINAL TOTAL',
                style: pw.TextStyle(
                  font: _ttfFont,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF0C6A57),
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                label,
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
            _pdfMoney(value),
            style: pw.TextStyle(
              font: _ttfFont,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0C6A57),
            ),
          ),
        ],
      ),
    );
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
