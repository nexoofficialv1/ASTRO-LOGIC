import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:astro_logic/src/models/professional_report_export.dart';
import 'package:astro_logic/src/services/professional_report_docx_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/professional_report_export_fixture.dart';

void main() {
  test('DOCX export contains required OOXML parts and source report hash', () {
    final snapshot = professionalReportExportFixture();
    final bytes = const ProfessionalReportDocxBuilder().build(
      snapshot: snapshot,
      locale: ProfessionalReportExportLocale.english,
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((file) => file.name).toSet();
    expect(names, contains('[Content_Types].xml'));
    expect(names, contains('word/document.xml'));
    expect(names, contains('word/styles.xml'));
    expect(names, contains('docProps/core.xml'));

    final document = archive.files.firstWhere((file) => file.name == 'word/document.xml');
    final xml = utf8.decode(document.readBytes()!);
    expect(xml, contains('Professional Astrology Consultation Report'));
    expect(xml, contains('Career structure'));
    expect(xml, contains(snapshot.reportHash));
  });

  test('DOCX Bengali export keeps Unicode text without embedding a font file', () {
    final snapshot = professionalReportExportFixture();
    final bytes = const ProfessionalReportDocxBuilder().build(
      snapshot: snapshot,
      locale: ProfessionalReportExportLocale.bengali,
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    final document = archive.files.firstWhere((file) => file.name == 'word/document.xml');
    final xml = utf8.decode(document.readBytes()!);
    expect(xml, contains('পেশাদার জ্যোতিষ পরামর্শ রিপোর্ট'));
    expect(xml, contains('কর্মজীবনের কাঠামো'));
    expect(archive.files.where((file) => file.name.toLowerCase().endsWith('.ttf')), isEmpty);
  });

  test('signed DOCX contains approval and signed-report verification metadata', () {
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    final bytes = const ProfessionalReportDocxBuilder().build(
      snapshot: snapshot,
      approval: approval,
      locale: ProfessionalReportExportLocale.english,
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((file) => file.name).toSet();
    final document = archive.files.firstWhere((file) => file.name == 'word/document.xml');
    final xml = utf8.decode(document.readBytes()!);
    expect(xml, contains('Professional approval and sign-off'));
    expect(xml, contains(approval.practitionerName));
    expect(xml, contains(approval.approvalHash));
    expect(xml, contains(approval.signedReportHash));
    expect(xml, contains('astro-logic-signed-report-verification-v1'));
    expect(xml, contains('rIdVerificationQr'));
    expect(xml, contains('not a certificate-backed cryptographic/digital signature'));
    expect(names, contains('word/media/verification_qr.png'));
    final qr = archive.files.firstWhere(
      (file) => file.name == 'word/media/verification_qr.png',
    );
    expect(qr.readBytes()!.take(8).toList(), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    final relationships = archive.files.firstWhere(
      (file) => file.name == 'word/_rels/document.xml.rels',
    );
    expect(
      utf8.decode(relationships.readBytes()!),
      contains('media/verification_qr.png'),
    );
  });

}
