# ASTRO LOGIC v066 — Professional Report Signing & Approval Workflow v1

Status: source implementation completed; runtime Flutter/Android/Windows validation still requires the pinned Flutter toolchain.

## Version contract

- App: `0.62.0+66`
- SQLite: schema v9
- Professional report generation: unchanged `1.4.0` / `professional-consultation-report-v1`
- Approval engine: `1.0.0`
- Approval statement: `professional-report-approval-statement-v1`
- Export engine: `1.1.0` / `professional-report-export-v2`

## Implemented

- one immutable practitioner approval per saved report snapshot;
- practitioner name + designation required; credential/reference optional;
- `approvedForClientDelivery` and `approvedWithReservations` decisions;
- reservation note requirement;
- explicit UI acknowledgement before sign-off;
- approval hash binding to report id/consultation/report hash + practitioner metadata + decision/note + UTC approval instant;
- signed-report hash binding source report hash + approval hash + statement version;
- SQLite report/consultation insert guards and approval UPDATE/DELETE blockers;
- report preview approval status and lock metadata;
- signed PDF/DOCX verification block and bilingual disclosure;
- signed export filename based on signed-report hash; unsigned exports retain prior filename form;
- signed exports reject source report tampering, approval tampering and wrong report linkage;
- audit event `professionalReportApproved` with report/approval/signed hashes.

## Safety / truthfulness boundary

The workflow is an ASTRO LOGIC in-app practitioner electronic sign-off. It does not use a private signing key, X.509 certificate, government e-sign provider or trusted timestamp authority and must not be described as a certificate-backed digital signature. No credential or registration number is auto-generated.

## Immutability semantics

Signing locks the report snapshot and approval record, not the entire consultation. Existing professional report snapshots were already immutable. Schema v9 makes approval append-only as well. A changed professional opinion therefore requires a new report snapshot, which can receive its own independent approval.

## Deferred build gates

This source container has no Flutter/Dart SDK. `flutter analyze`, `flutter test`, Android APK and Windows release build remain mandatory at the final CI/build checkpoint and are not claimed here.
