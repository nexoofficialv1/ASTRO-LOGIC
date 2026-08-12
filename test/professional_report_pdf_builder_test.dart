import 'dart:convert';

import 'package:astro_logic/src/models/professional_report_export.dart';
import 'package:astro_logic/src/services/professional_report_pdf_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/professional_report_export_fixture.dart';

void main() {
  test('English PDF export creates a PDF file from immutable report data', () async {
    final snapshot = professionalReportExportFixture();
    final bytes = await const ProfessionalReportPdfBuilder().build(
      snapshot: snapshot,
      locale: ProfessionalReportExportLocale.english,
    );
    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('signed PDF export includes verification QR payload content', () async {
    final snapshot = professionalReportExportFixture();
    final approval = professionalReportApprovalFixture(snapshot: snapshot);
    final bytes = await const ProfessionalReportPdfBuilder().build(
      snapshot: snapshot,
      approval: approval,
      locale: ProfessionalReportExportLocale.english,
    );
    expect(bytes.length, greaterThan(1500));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });
}
