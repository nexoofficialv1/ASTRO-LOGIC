import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/professional_report_approval.dart';
import '../models/professional_report_export.dart';
import '../models/professional_report_snapshot.dart';
import 'professional_report_verification_service.dart';
import 'professional_report_export_projection.dart';

class ProfessionalReportPdfFontResolver {
  const ProfessionalReportPdfFontResolver();

  static const _regularCandidates = <String>[
    '/system/fonts/NotoSansBengali-Regular.ttf',
    '/system/fonts/NotoSansBengaliUI-Regular.ttf',
    '/system/fonts/NotoSansBengali-VF.ttf',
    r'C:\Windows\Fonts\Nirmala.ttf',
    r'C:\Windows\Fonts\NirmalaS.ttf',
    '/usr/share/fonts/truetype/noto/NotoSansBengali-Regular.ttf',
    '/usr/share/fonts/opentype/noto/NotoSansBengali-Regular.ttf',
    '/System/Library/Fonts/Supplemental/Noto Sans Bengali.ttf',
  ];

  static const _boldCandidates = <String>[
    '/system/fonts/NotoSansBengali-Bold.ttf',
    '/system/fonts/NotoSansBengaliUI-Bold.ttf',
    r'C:\Windows\Fonts\NirmalaB.ttf',
    '/usr/share/fonts/truetype/noto/NotoSansBengali-Bold.ttf',
    '/usr/share/fonts/opentype/noto/NotoSansBengali-Bold.ttf',
  ];

  Future<({pw.Font regular, pw.Font bold})?> resolveUnicodeFonts() async {
    final regular = await _firstFont(_regularCandidates);
    if (regular == null) return null;
    final bold = await _firstFont(_boldCandidates) ?? regular;
    return (regular: regular, bold: bold);
  }

  Future<pw.Font?> _firstFont(List<String> candidates) async {
    for (final path in candidates) {
      final file = File(path);
      if (!await file.exists()) continue;
      final data = await file.readAsBytes();
      return pw.Font.ttf(
        data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes),
      );
    }
    return null;
  }
}

class ProfessionalReportPdfBuilder {
  const ProfessionalReportPdfBuilder({
    this.fontResolver = const ProfessionalReportPdfFontResolver(),
  });

  final ProfessionalReportPdfFontResolver fontResolver;

  Future<Uint8List> build({
    required ProfessionalReportSnapshot snapshot,
    required ProfessionalReportExportLocale locale,
    ProfessionalReportApproval? approval,
  }) async {
    final view = ProfessionalReportExportProjection.fromSnapshot(
      snapshot: snapshot,
      locale: locale,
      approval: approval,
    );

    pw.Font regular;
    pw.Font bold;
    final unicodeFonts = await fontResolver.resolveUnicodeFonts();
    if (unicodeFonts != null) {
      regular = unicodeFonts.regular;
      bold = unicodeFonts.bold;
    } else {
      if (view.requiresUnicodePdfFont) {
        throw const ProfessionalReportExportException(
          'A Unicode Bengali-capable system font is required for this PDF. '
          'DOCX export remains available without embedded fonts.',
        );
      }
      regular = pw.Font.helvetica();
      bold = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final document = pw.Document(
      title: view.reportTitle,
      author: 'ASTRO LOGIC',
      creator: 'ASTRO LOGIC Professional Report Export Engine v3',
      subject: view.subject,
      keywords: '${snapshot.reportSchemaVersion},${snapshot.reportHash},${approval?.signedReportHash ?? ''}',
      producer: 'ASTRO LOGIC',
      theme: theme,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 42, 38, 42),
        maxPages: 80,
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey500)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${(approval?.signedReportHash ?? snapshot.reportHash).substring(0, 12)} | ${view.languageCode}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                '${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              'ASTRO LOGIC',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              view.reportTitle,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              view.clientName,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (view.subject.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(view.subject, style: const pw.TextStyle(fontSize: 11)),
            ],
            pw.SizedBox(height: 12),
            _metaLine('${view.sourceSchemaLabel}: ${snapshot.reportSchemaVersion}'),
            _metaLine('${view.asOfLabel}: ${view.asOfUtc}'),
            _metaLine('${view.reportHashLabel}: ${snapshot.reportHash}'),
            _metaLine('${view.professionalReviewLabel}: ${view.professionalReviewRequired ? 'Yes' : 'No'}'),
            if (approval != null) ..._approvalWidgets(view, snapshot, approval),
            pw.SizedBox(height: 18),
          ];

          var sectionNumber = 1;
          for (final section in view.sections) {
            widgets.addAll(_sectionWidgets(view, section, sectionNumber++));
          }
          if (view.warnings.isNotEmpty) {
            widgets.addAll([
              pw.SizedBox(height: 12),
              pw.Text(
                view.warningsTitle,
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              for (final warning in view.warnings)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text('- $warning', style: const pw.TextStyle(fontSize: 9.5)),
                ),
            ]);
          }
          return widgets;
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _metaLine(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
      );

  static List<pw.Widget> _sectionWidgets(
    ProfessionalReportExportProjection view,
    Map<String, Object?> section,
    int number,
  ) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 6),
      pw.Text(
        '$number. ${view.sectionTitle(section)}',
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        '[${view.sectionStatus(section)}] ${view.sectionSummary(section)}',
        style: const pw.TextStyle(fontSize: 10),
      ),
      pw.SizedBox(height: 7),
    ];
    for (final item in view.sectionItems(section)) {
      widgets.add(
        pw.Text(
          view.itemTitle(item),
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      );
      final narrative = view.itemNarrative(item);
      if (narrative.isNotEmpty) {
        widgets.addAll([
          pw.SizedBox(height: 2),
          pw.Text(narrative, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2)),
        ]);
      }
      final confidence = view.itemConfidence(item);
      if (confidence.isNotEmpty) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              '${view.confidenceLabel}: $confidence',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
            ),
          ),
        );
      }
      final evidence = view.itemEvidence(item);
      if (evidence.isNotEmpty) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              '${view.evidenceLabel}: ${evidence.join(', ')}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        );
      }
      widgets.add(pw.SizedBox(height: 7));
    }
    widgets.add(
      pw.Divider(height: 12, thickness: 0.4, color: PdfColors.grey400),
    );
    return widgets;
  }

  static List<pw.Widget> _approvalWidgets(
    ProfessionalReportExportProjection view,
    ProfessionalReportSnapshot snapshot,
    ProfessionalReportApproval approval,
  ) {
    final verificationPayload =
        const ProfessionalReportVerificationService().payloadFor(
      snapshot: snapshot,
      approval: approval,
    );
    return [
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.7, color: PdfColors.grey600),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                view.approvalTitle,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              _metaLine('${view.approvalStatusLabel}: ${view.approvalDecision(approval.decision)}'),
              _metaLine('${view.practitionerLabel}: ${approval.practitionerName}'),
              _metaLine('${view.designationLabel}: ${approval.practitionerDesignation}'),
              if (approval.credentialReference.isNotEmpty)
                _metaLine('${view.credentialLabel}: ${approval.credentialReference}'),
              _metaLine('${view.approvedAtLabel}: ${approval.approvedAt.toUtc().toIso8601String()}'),
              if (approval.approvalNote.isNotEmpty)
                _metaLine('${view.approvalNoteLabel}: ${approval.approvalNote}'),
              _metaLine('${view.approvalStatementLabel}: ${approval.approvalStatementVersion}'),
              _metaLine('${view.approvalHashLabel}: ${approval.approvalHash}'),
              _metaLine('${view.signedReportHashLabel}: ${approval.signedReportHash}'),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: verificationPayload,
                    width: 88,
                    height: 88,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          view.verificationQrLabel,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 3),
                        _metaLine('${view.verificationContractLabel}: ${ProfessionalReportVerificationService.verificationContractVersion}'),
                        pw.Text(
                          view.verificationDisclosure,
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                view.approvalDisclosure,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ];
  }

}
