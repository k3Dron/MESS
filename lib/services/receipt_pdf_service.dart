import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/receipt_model.dart';

class ReceiptPdfService {
  /// Generate a styled receipt PDF from a ReceiptModel and trigger
  /// the system share/save/print dialog.
  static Future<void> downloadReceipt(ReceiptModel receipt) async {
    final pdfBytes = await _generatePdf(receipt);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'receipt_${receipt.receiptCode}.pdf',
    );
  }

  static Future<Uint8List> _generatePdf(ReceiptModel receipt) async {
    final pdf = pw.Document();

    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthLabel = receipt.month > 0 && receipt.month <= 12
        ? monthNames[receipt.month]
        : 'Month ${receipt.month}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'MEZZ',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#6C63FF'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Hostel Mess Management',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromHex('#95A5A6'),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('#E8ECF4')),
              pw.SizedBox(height: 20),

              // Receipt Code (prominent)
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#6C63FF'),
                      width: 2,
                    ),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Receipt Code',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromHex('#95A5A6'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        receipt.receiptCode,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 4,
                          color: PdfColor.fromHex('#6C63FF'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 30),

              // Details
              _infoRow('Student', receipt.studentEmail),
              _infoRow('Vendor Code', receipt.vendorCode),
              _infoRow('Billing Month', monthLabel),
              _infoRow('Date', _formatDate(receipt.date)),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#E8ECF4')),
              pw.SizedBox(height: 20),

              // Financial Breakdown
              pw.Text(
                'Billing Summary',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              _amountRow('Total Expenditure', receipt.expenditure),
              _amountRow('Plan Deduction', -receipt.planDeduction),
              if (receipt.bufferUsed > 0)
                _amountRow('Buffer Used', -receipt.bufferUsed),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Final Amount',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '₹${receipt.finalCost.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#2ECC71'),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 40),
              pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#E8ECF4')),
              pw.SizedBox(height: 12),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'This receipt is digitally signed with code ${receipt.receiptCode}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#95A5A6'),
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated by Mezz App • ${_formatDate(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromHex('#BDC3C7'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColor.fromHex('#636E72'),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _amountRow(String label, double amount) {
    final isNegative = amount < 0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            '${isNegative ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 12,
              color: isNegative
                  ? PdfColor.fromHex('#E74C3C')
                  : PdfColor.fromHex('#2D3436'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
