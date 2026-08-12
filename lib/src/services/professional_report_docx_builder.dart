import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/professional_report_approval.dart';
import '../models/professional_report_export.dart';
import '../models/professional_report_snapshot.dart';
import 'professional_report_export_projection.dart';
import 'professional_report_verification_service.dart';
import 'qr_png_encoder.dart';

class ProfessionalReportDocxBuilder {
  const ProfessionalReportDocxBuilder();

  Uint8List build({
    required ProfessionalReportSnapshot snapshot,
    required ProfessionalReportExportLocale locale,
    ProfessionalReportApproval? approval,
  }) {
    final view = ProfessionalReportExportProjection.fromSnapshot(
      snapshot: snapshot,
      locale: locale,
      approval: approval,
    );
    final created = snapshot.createdAt.toUtc();
    final verificationPayload = approval == null
        ? null
        : const ProfessionalReportVerificationService().payloadFor(
            snapshot: snapshot,
            approval: approval,
          );
    final body = StringBuffer()
      ..write(_paragraph('ASTRO LOGIC', style: 'Brand'))
      ..write(_paragraph(view.reportTitle, style: 'Title'))
      ..write(_paragraph(view.clientName, style: 'Heading1'));
    if (view.subject.isNotEmpty) body.write(_paragraph(view.subject));
    body
      ..write(_paragraph('${view.sourceSchemaLabel}: ${snapshot.reportSchemaVersion}', style: 'Small'))
      ..write(_paragraph('${view.asOfLabel}: ${view.asOfUtc}', style: 'Small'))
      ..write(_paragraph('${view.reportHashLabel}: ${snapshot.reportHash}', style: 'Small'))
      ..write(_paragraph('${view.professionalReviewLabel}: ${view.professionalReviewRequired ? 'Yes' : 'No'}', style: 'Small'));
    if (approval != null) {
      body
        ..write(_paragraph(view.approvalTitle, style: 'Heading2'))
        ..write(_paragraph('${view.approvalStatusLabel}: ${view.approvalDecision(approval.decision)}', style: 'Small'))
        ..write(_paragraph('${view.practitionerLabel}: ${approval.practitionerName}', style: 'Small'))
        ..write(_paragraph('${view.designationLabel}: ${approval.practitionerDesignation}', style: 'Small'));
      if (approval.credentialReference.isNotEmpty) {
        body.write(_paragraph('${view.credentialLabel}: ${approval.credentialReference}', style: 'Small'));
      }
      body.write(_paragraph('${view.approvedAtLabel}: ${approval.approvedAt.toUtc().toIso8601String()}', style: 'Small'));
      if (approval.approvalNote.isNotEmpty) {
        body.write(_paragraph('${view.approvalNoteLabel}: ${approval.approvalNote}', style: 'Small'));
      }
      body
        ..write(_paragraph('${view.approvalStatementLabel}: ${approval.approvalStatementVersion}', style: 'Small'))
        ..write(_paragraph('${view.approvalHashLabel}: ${approval.approvalHash}', style: 'Evidence'))
        ..write(_paragraph('${view.signedReportHashLabel}: ${approval.signedReportHash}', style: 'Evidence'))
        ..write(_paragraph('${view.verificationContractLabel}: ${ProfessionalReportVerificationService.verificationContractVersion}', style: 'Small'))
        ..write(_paragraph(view.verificationDisclosure, style: 'Evidence'))
        ..write(_paragraph(view.approvalDisclosure, style: 'Evidence'));
      if (verificationPayload != null) {
        body
          ..write(_paragraph(view.verificationQrLabel, style: 'Heading2'))
          ..write(_verificationQrDrawing());
      }
    }

    var sectionNumber = 1;
    for (final section in view.sections) {
      body
        ..write(_paragraph('$sectionNumber. ${view.sectionTitle(section)}', style: 'Heading1'))
        ..write(_paragraph('[${view.sectionStatus(section)}] ${view.sectionSummary(section)}'));
      sectionNumber++;
      for (final item in view.sectionItems(section)) {
        body.write(_paragraph(view.itemTitle(item), style: 'Heading2'));
        final narrative = view.itemNarrative(item);
        if (narrative.isNotEmpty) body.write(_paragraph(narrative));
        final confidence = view.itemConfidence(item);
        if (confidence.isNotEmpty) {
          body.write(_paragraph('${view.confidenceLabel}: $confidence', style: 'Small'));
        }
        final evidence = view.itemEvidence(item);
        if (evidence.isNotEmpty) {
          body.write(_paragraph('${view.evidenceLabel}: ${evidence.join(', ')}', style: 'Evidence'));
        }
      }
    }

    if (view.warnings.isNotEmpty) {
      body.write(_paragraph(view.warningsTitle, style: 'Heading1'));
      for (final warning in view.warnings) {
        body.write(_paragraph('- $warning'));
      }
    }

    body.write('''
<w:sectPr>
  <w:pgSz w:w="11906" w:h="16838"/>
  <w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="708" w:footer="708" w:gutter="0"/>
</w:sectPr>
''');

    final archive = Archive();
    void add(String name, String xml) {
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(xml)));
    }

    add('[Content_Types].xml', _contentTypes);
    add('_rels/.rels', _rootRels);
    add('docProps/core.xml', _coreProperties(view, snapshot, approval, created));
    add('docProps/app.xml', _appProperties);
    add('word/document.xml', _document(body.toString()));
    add('word/styles.xml', _styles(view.bengali));
    add('word/_rels/document.xml.rels', _documentRels(verificationPayload != null));
    if (verificationPayload != null) {
      archive.addFile(
        ArchiveFile.bytes(
          'word/media/verification_qr.png',
          QrPngEncoder.encode(verificationPayload),
        ),
      );
    }

    return ZipEncoder().encodeBytes(archive, modified: created);
  }

  static String _paragraph(String value, {String? style}) {
    final text = _xml(value);
    if (text.isEmpty) return '';
    final styleXml = style == null ? '' : '<w:pPr><w:pStyle w:val="$style"/></w:pPr>';
    return '<w:p>$styleXml<w:r><w:t xml:space="preserve">$text</w:t></w:r></w:p>';
  }

  static String _document(String body) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:body>$body</w:body>
</w:document>''';

  static String _verificationQrDrawing() => '''<w:p>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0">
        <wp:extent cx="1371600" cy="1371600"/>
        <wp:docPr id="1" name="Signed report verification QR"/>
        <a:graphic>
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic>
              <pic:nvPicPr>
                <pic:cNvPr id="0" name="verification_qr.png"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <a:blip r:embed="rIdVerificationQr"/>
                <a:stretch><a:fillRect/></a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm><a:off x="0" y="0"/><a:ext cx="1371600" cy="1371600"/></a:xfrm>
                <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
              </pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>''';

  static String _coreProperties(
    ProfessionalReportExportProjection view,
    ProfessionalReportSnapshot snapshot,
    ProfessionalReportApproval? approval,
    DateTime created,
  ) =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>${_xml(view.reportTitle)}</dc:title>
  <dc:subject>${_xml(view.subject)}</dc:subject>
  <dc:creator>ASTRO LOGIC</dc:creator>
  <cp:lastModifiedBy>ASTRO LOGIC</cp:lastModifiedBy>
  <dc:description>${_xml('${snapshot.reportSchemaVersion} | ${snapshot.reportHash}${approval == null ? '' : ' | approval=${approval.approvalHash} | signed=${approval.signedReportHash}'}')}</dc:description>
  <dcterms:created xsi:type="dcterms:W3CDTF">${created.toIso8601String()}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">${created.toIso8601String()}</dcterms:modified>
</cp:coreProperties>''';

  static String _styles(bool bengali) {
    final font = bengali ? 'Nirmala UI' : 'Aptos';
    String style(String id, String name, int size, {bool bold = false, String? basedOn}) => '''
<w:style w:type="paragraph" w:styleId="$id">
  <w:name w:val="$name"/>
  ${basedOn == null ? '' : '<w:basedOn w:val="$basedOn"/>'}
  <w:qFormat/>
  <w:rPr>
    <w:rFonts w:ascii="$font" w:hAnsi="$font" w:eastAsia="$font" w:cs="$font"/>
    ${bold ? '<w:b/><w:bCs/>' : ''}
    <w:sz w:val="$size"/><w:szCs w:val="$size"/>
    <w:lang w:val="en-US" w:eastAsia="${bengali ? 'bn-BD' : 'en-US'}"/>
  </w:rPr>
</w:style>''';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
${style('Normal', 'Normal', 22)}
${style('Brand', 'Brand', 18, bold: true, basedOn: 'Normal')}
${style('Title', 'Title', 34, bold: true, basedOn: 'Normal')}
${style('Heading1', 'Heading 1', 28, bold: true, basedOn: 'Normal')}
${style('Heading2', 'Heading 2', 24, bold: true, basedOn: 'Normal')}
${style('Small', 'Small', 18, basedOn: 'Normal')}
${style('Evidence', 'Evidence', 17, basedOn: 'Normal')}
</w:styles>''';
  }

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static const _contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

  static const _rootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

  static String _documentRels(bool hasVerificationQr) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  ${hasVerificationQr ? '<Relationship Id="rIdVerificationQr" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/verification_qr.png"/>' : ''}
</Relationships>''';

  static const _appProperties = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>ASTRO LOGIC</Application>
  <AppVersion>1.0</AppVersion>
</Properties>''';
}
