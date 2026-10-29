import 'package:sabcargo/services/logger_service.dart';
// ignore_for_file: avoid_print
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<void> generateReceipt(Map<String, dynamic> data) async {
    try {
      appLogger.i('Generating PDF...');
      
      final pdf = pw.Document();
      final dateStr = data['date'] ?? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
      final bookingId = data['bookingId'] ?? 'SAB-XXXX';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SABCARGO',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange900,
                            ),
                          ),
                          pw.Text(
                            'Logistics & Freight Services',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'RECEIPT',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'ID: $bookingId',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 20),

                  // Company & Date Info
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Company Information:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text('Sabcargo Logistics LLC'),
                          pw.Text('Saudi Arabia / UAE'),
                          pw.Text('Contact: +966 XX XXX XXXX'),
                          pw.Text('Email: info@sabcargo.com'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Date Issued:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(dateStr),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Status: ${data['status'] ?? 'PAID'}',
                            style: pw.TextStyle(
                              color: PdfColors.green700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 30),

                  // Shipment Details Section
                  pw.Text(
                    'SHIPMENT DETAILS',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        _buildPdfRow('Item Name', data['itemName']?.toString() ?? 'N/A'),
                        _buildPdfRow('Freight Type', data['cargoType']?.toString() ?? 'N/A'),
                        _buildPdfRow('Weight', '${data['weight'] ?? '0'} kg'),
                        _buildPdfRow('Origin', data['fromCity']?.toString() ?? 'N/A'),
                        _buildPdfRow('Destination', data['toCity']?.toString() ?? 'N/A'),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Contacts Section
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SENDER',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(data['senderName']?.toString() ?? 'N/A'),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'RECEIVER',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(data['receiverName']?.toString() ?? 'N/A'),
                            pw.Text(data['receiverPhone']?.toString() ?? 'N/A'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 40),

                  // Payment Summary
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 250,
                        child: pw.Column(
                          children: [
                             pw.Row(
                               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                               children: [
                                 pw.Text('Subtotal:'),
                                 pw.Text('${data['total'] ?? '0.00'} SAR'),
                               ]
                             ),
                            pw.Divider(color: PdfColors.grey400),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TOTAL PAID',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  '${data['total'] ?? '0.00'} SAR',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.orange800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // Footer
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Thank you for choosing Sabcargo Logistics!',
                          style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'This is a computer-generated receipt and does not require a signature.',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Sabcargo_Receipt_$bookingId.pdf',
      );
      appLogger.i('PDF generated and shared successfully.');
    } catch (e) {
      appLogger.i('Error generating PDF: $e');
    }
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
