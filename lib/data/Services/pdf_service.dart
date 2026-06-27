/*
class PdfService {
  static Future<void> generateTransactionReport({
    required String storeName,
    required List<Map<String, dynamic>> transactions,
    required double totalBalance,
  }) async {
    final pdf = pw.Document();

    // تحميل خط يدعم اللغة العربية (ضروري جداً)
    final font = await PdfGoogleFonts.almaraiRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            // العنوان والترويسة
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "كشف حساب مالي",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(storeName, style: pw.TextStyle(fontSize: 18)),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // ملخص الرصيد
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey200,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("إجمالي الرصيد الحالي:"),
                  pw.Text(
                    "₪ ${totalBalance.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // جدول العمليات
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              headers: ['الحالة', 'المبلغ', 'التاريخ', 'العملية'],
              data: transactions.map((item) {
                final date = (item['createdAt'] as Timestamp).toDate();
                return [
                  item['status'] == 'completed' ? 'مكتمل' : 'معلق',
                  '${item['amount']} ₪',
                  DateFormat('yyyy/MM/dd').format(date),
                  _getTypeLabel(item['type']),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // معاينة الملف أو طباعته مباشرة
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static String _getTypeLabel(String type) {
    switch (type) {
      case 'order_revenue':
        return 'أرباح طلب';
      case 'withdrawal':
        return 'سحب رصيد';
      case 'refund':
        return 'مرتجع';
      default:
        return 'أخرى';
    }
  }
}
*/