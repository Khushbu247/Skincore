import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/medical_report.dart';

class PdfReportService {
  static Future<void> generateAndDownloadPdf(MedicalReport report, {String userName = 'Patient'}) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM dd, yyyy · hh:mm a');
    final formattedDate = dateFormat.format(report.dateTime);

    // Primary Colors
    final primaryColor = PdfColor.fromHex('#7A3B93');
    final roseColor = PdfColor.fromHex('#E9497A');
    final darkInk = PdfColor.fromHex('#251A2E');
    final mutedText = PdfColor.fromHex('#666666');
    final cardBg = PdfColor.fromHex('#FBF7F9');
    final borderColor = PdfColor.fromHex('#EFE7F0');

    final isQuestionnaire = report.reportType == 'questionnaire' || report.prediction == 'Skin Understanding';
    final isSerious = report.prediction.toLowerCase().contains('serious');
    final statusColor = isSerious ? PdfColor.fromHex('#C13B4A') : primaryColor;

    String formatClassName(String raw) {
      switch (raw.toLowerCase()) {
        case 'acne':
          return 'Acne Vulgaris';
        case 'eczema_rash':
        case 'eczema/rash':
          return 'Eczema / Contact Dermatitis';
        case 'pigmentation':
          return 'Hyperpigmentation';
        case 'serious_condition':
          return 'Serious Condition (Clinical Alert)';
        case 'skin understanding':
          return 'Skin Understanding Profile';
        default:
          return raw.replaceAll('_', ' ').toUpperCase();
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isQuestionnaire ? 'SKINCORE SKIN UNDERSTANDING REPORT' : 'SKINCORE AI CLINICAL REPORT',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        isQuestionnaire
                            ? 'Comprehensive 12-Point Patient Profile & Diagnostic Summary'
                            : 'Advanced Dermatological AI Diagnostic Record',
                        style: pw.TextStyle(color: mutedText, fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: cardBg,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: borderColor),
                        ),
                        child: pw.Text(
                          report.id,
                          style: pw.TextStyle(color: darkInk, fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: $formattedDate', style: pw.TextStyle(color: mutedText, fontSize: 9)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 14),

              // Patient Info Bar
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PATIENT / USER', style: pw.TextStyle(color: mutedText, fontSize: 8)),
                        pw.Text(userName, style: pw.TextStyle(color: darkInk, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RECORD TYPE', style: pw.TextStyle(color: mutedText, fontSize: 8)),
                        pw.Text(isQuestionnaire ? 'Skin Profile' : 'AI Scan', style: pw.TextStyle(color: darkInk, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('VERSION', style: pw.TextStyle(color: mutedText, fontSize: 8)),
                        pw.Text(report.modelVersion, style: pw.TextStyle(color: darkInk, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STATUS', style: pw.TextStyle(color: mutedText, fontSize: 8)),
                        pw.Text(report.riskLevel, style: pw.TextStyle(color: statusColor, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Title Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: statusColor, width: 1.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isQuestionnaire ? 'PATIENT CLINICAL QUESTIONNAIRE' : 'PRIMARY AI DIAGNOSTIC FINDING',
                          style: pw.TextStyle(color: roseColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          formatClassName(report.prediction),
                          style: pw.TextStyle(color: statusColor, fontSize: 18, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        isQuestionnaire ? '100% Completed' : '${report.confidence.toStringAsFixed(1)}% Match',
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // TABULAR REPORT BREAKDOWN
              if (!isQuestionnaire) ...[
                pw.Text('TABULAR MODEL PROBABILITY BREAKDOWN', style: pw.TextStyle(color: primaryColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: borderColor, width: 0.8),
                  headerStyle: pw.TextStyle(color: darkInk, fontWeight: pw.FontWeight.bold, fontSize: 8.5),
                  cellStyle: pw.TextStyle(color: darkInk, fontSize: 8),
                  headerDecoration: pw.BoxDecoration(color: cardBg),
                  headers: ['CLASSIFICATION TARGET', 'MODEL PROBABILITY (%)', 'CLASSIFICATION LEVEL'],
                  data: report.probabilities.entries.map((e) {
                    final isTop = e.key.toLowerCase() == report.prediction.toLowerCase() ||
                        formatClassName(e.key).toLowerCase() == report.prediction.toLowerCase();
                    return [
                      formatClassName(e.key),
                      '${e.value.toStringAsFixed(2)}%',
                      isTop ? 'PRIMARY SIGNAL' : 'SECONDARY'
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 12),
              ],

              if (report.regionObservations != null && report.regionObservations!.isNotEmpty) ...[
                pw.Text('SKINCORE AI REGIONAL ANALYSIS TABLE', style: pw.TextStyle(color: primaryColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: borderColor, width: 0.8),
                  headerStyle: pw.TextStyle(color: darkInk, fontWeight: pw.FontWeight.bold, fontSize: 8.5),
                  cellStyle: pw.TextStyle(color: darkInk, fontSize: 8),
                  headerDecoration: pw.BoxDecoration(color: cardBg),
                  headers: ['TARGET REGION', 'VISUAL OBSERVATION', 'SEVERITY'],
                  data: report.regionObservations!.map((r) => [
                    (r['region'] ?? 'General').toUpperCase(),
                    r['observation'] ?? '',
                    (r['severity'] ?? 'moderate').toUpperCase()
                  ]).toList(),
                ),
                pw.SizedBox(height: 12),
              ],

              // Observations & Care Routine / Questionnaire Answers
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isQuestionnaire ? 'Key Profile Findings' : 'Key Clinical Observations',
                          style: pw.TextStyle(color: darkInk, fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 6),
                        ...report.keyObservations.map(
                          (obs) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('• ', style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
                                pw.Expanded(child: pw.Text(obs, style: pw.TextStyle(fontSize: 9.5, color: darkInk))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isQuestionnaire ? 'Personalized Care Guidelines' : 'Recommended Clinical Steps',
                          style: pw.TextStyle(color: darkInk, fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 6),
                        ...report.recommendedCare.map(
                          (care) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('✓ ', style: pw.TextStyle(color: roseColor, fontWeight: pw.FontWeight.bold)),
                                pw.Expanded(child: pw.Text(care, style: pw.TextStyle(fontSize: 9.5, color: darkInk))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),


              pw.Spacer(),

              // Medical Disclaimer Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Text(
                  'DISCLAIMER: SkinCore AI provides preliminary, automated skin assessment for informational purposes only. This report does not constitute an official medical diagnosis. Please consult a board-certified dermatologist for professional medical advice, diagnosis, or treatment.',
                  style: pw.TextStyle(fontSize: 7.5, color: mutedText, height: 1.3),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Trigger Print/Save dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SkinCore_Medical_Report_${report.id}.pdf',
    );
  }
}
