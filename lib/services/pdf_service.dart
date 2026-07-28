import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndDownloadTranscript({
    required String chatId,
    required String currentUserName,
    required String targetUserName,
  }) async {
    // 1. Fetch all messages from Firestore for this chat room
    final querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();

    final pdf = pw.Document();

    // 2. Build the PDF layout using pw widgets
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal800,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WhatsApp Clone Report',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Official Chat Transcript',
                        style: pw.TextStyle(
                          color: PdfColors.teal100,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateTime.now().toString().split('.')[0],
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Participant Metadata Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Participants: $currentUserName & $targetUserName',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Total Messages: ${querySnapshot.docs.length}'),
                  pw.Text('Chat Room ID: $chatId'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'Conversation Log',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.Divider(color: PdfColors.teal800),
            pw.SizedBox(height: 10),

            // Message List
            ...querySnapshot.docs.map((doc) {
              final data = doc.data();
              final text = data['text'] ?? '';
              final senderId = data['senderId'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final timeStr = timestamp != null
                  ? timestamp.toDate().toString().substring(0, 16)
                  : 'Sending...';

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          senderId == currentUserName
                              ? 'You ($currentUserName)'
                              : targetUserName,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.Text(
                          timeStr,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    // 3. Trigger print / download browser preview window
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Chat_Transcript_$chatId.pdf',
    );
  }
}
