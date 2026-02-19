import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- rootBundle for font
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';

import '../repositories/balancesheet_repository.dart';

class BalanceSheetViewModel extends ChangeNotifier {
  final BalanceSheetRepository repository = BalanceSheetRepository();

  // ---------------- Dates ----------------
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

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
      final fontData = await rootBundle.load(
        'lib/assets/fonts/Roboto-Regular.ttf',
      );
      _ttfFont = pw.Font.ttf(fontData);
    }
  }

  // ---------------- Methods ----------------
  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return formatter.format(value);
  }

  String getFormattedDate(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  Future<void> selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(_endDate)) _startDate = _endDate;
      }
      notifyListeners();
    }
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Balance Sheet',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Period: ${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                style: pw.TextStyle(font: _ttfFont),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Assets
              pw.Text(
                'Assets',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              ..._pdfRows(assets),
              _pdfTotalRow('Total Assets', totalAssets),
              pw.SizedBox(height: 12),

              // Liabilities
              pw.Text(
                'Liabilities',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              ..._pdfRows(liabilities),
              _pdfTotalRow('Total Liabilities', totalLiabilities),
              pw.SizedBox(height: 12),

              // Equity
              pw.Text(
                "Owner's Equity",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: _ttfFont,
                ),
              ),
              ..._pdfRows(equity),
              _pdfTotalRow('Total Equity', totalEquity),
              pw.SizedBox(height: 12),

              // Total Liabilities + Equity
              _pdfTotalRow(
                'Total Liabilities + Equity',
                totalLiabilities + totalEquity,
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

  List<pw.Widget> _pdfRows(Map<String, double> items) {
    return items.entries.map((entry) {
      return pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(entry.key, style: pw.TextStyle(font: _ttfFont)),
          ),
          pw.Text(
            formatCurrency(entry.value),
            style: pw.TextStyle(font: _ttfFont),
          ),
        ],
      );
    }).toList();
  }

  pw.Widget _pdfTotalRow(String title, double value) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: _ttfFont),
          ),
        ),
        pw.Text(
          formatCurrency(value),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: _ttfFont),
        ),
      ],
    );
  }
}
