import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';

import '../repositories/balancesheet_repository.dart';

class BalanceSheetViewModel extends ChangeNotifier {
  final BalanceSheetRepository repository = BalanceSheetRepository();

  // ---------------- Data ----------------
  Map<String, double> assets = {};
  Map<String, double> liabilities = {};
  Map<String, double> equity = {};

  double get totalAssets => assets.values.fold(0, (prev, cur) => prev + cur);
  double get totalLiabilities =>
      liabilities.values.fold(0, (prev, cur) => prev + cur);
  double get totalEquity => equity.values.fold(0, (prev, cur) => prev + cur);

  // ---------------- Font for PDF ----------------
  pw.Font? _ttfFont;

  Future<void> _loadFont() async {
    if (_ttfFont == null) {
      final fontData =
          await rootBundle.load('lib/assets/fonts/Roboto-Regular.ttf');
      _ttfFont = pw.Font.ttf(fontData);
    }
  }

  // ---------------- Currency Formatter ----------------
  // (kept for app usage + repository display logic)
  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return formatter.format(value);
  }

  // ✅ PDF currency (match Income Statement style: ₱ with 2 decimals)
  String _pdfMoney(double value) {
    return NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(value);
  }

  // ---------------- Load data from DB ----------------
  Future<void> loadBalanceSheet() async {
    assets = await repository.getAssets();
    liabilities = await repository.getLiabilities();
    equity = await repository.getEquity();
    notifyListeners();
  }

  // ---------------- PDF Export ----------------
  Future<void> exportPdf() async {
    await _loadFont();

    final pdf = pw.Document();
    final asOfText = DateFormat('yyyy-MM-dd').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Text(
                'Balance Sheet',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              pw.SizedBox(height: 8),

              // As of (same pattern as income statement "Period:")
              pw.Text(
                'As of: $asOfText',
                style: pw.TextStyle(font: _ttfFont),
              ),

              pw.Divider(),
              pw.SizedBox(height: 8),

              // ---------------- ASSETS ----------------
              pw.Text(
                'Assets',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              if (assets.isEmpty)
                _pdfEmptyRow('No records yet.')
              else ...[
                ..._pdfLeaderRows(assets, indent: true),
                pw.Divider(),
                _pdfLeaderRow('TOTAL ASSETS', totalAssets, bold: true),
              ],

              pw.SizedBox(height: 12),

              // ---------------- LIABILITIES ----------------
              pw.Text(
                'Liabilities',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              if (liabilities.isEmpty)
                _pdfEmptyRow('No records yet.')
              else ...[
                ..._pdfLeaderRows(liabilities, indent: true),
                pw.Divider(),
                _pdfLeaderRow('TOTAL LIABILITIES', totalLiabilities, bold: true),
              ],

              pw.SizedBox(height: 12),

              // ---------------- EQUITY ----------------
              pw.Text(
                "Owner's Equity",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              if (equity.isEmpty)
                _pdfEmptyRow('No records yet.')
              else ...[
                ..._pdfLeaderRows(equity, indent: true),
                pw.Divider(),
                _pdfLeaderRow('TOTAL EQUITY', totalEquity, bold: true),
              ],

              pw.SizedBox(height: 12),

              // ---------------- TOTAL L + E ----------------
              pw.Divider(),
              _pdfLeaderRow(
                'TOTAL LIABILITIES + EQUITY',
                totalLiabilities + totalEquity,
                bold: true,
              ),
            ],
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

  // ---------------- PDF Helpers (Income Statement style) ----------------

  List<pw.Widget> _pdfLeaderRows(
    Map<String, double> items, {
    bool indent = false,
  }) {
    return items.entries
        .map((e) => _pdfLeaderRow(e.key, e.value, indent: indent))
        .toList();
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
            _pdfMoney(value),
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              font: _ttfFont,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfEmptyRow(String message) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 10),
      child: pw.Text(
        message,
        style: pw.TextStyle(
          font: _ttfFont,
          color: PdfColors.grey700,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }
}