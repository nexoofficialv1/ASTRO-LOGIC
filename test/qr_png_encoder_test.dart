import 'dart:typed_data';

import 'package:astro_logic/src/services/qr_png_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QR PNG encoder emits a valid PNG signature and non-zero dimensions', () {
    final bytes = QrPngEncoder.encode('{"v":"fixture","s":"abc"}');
    expect(bytes.length, greaterThan(200));
    expect(bytes.take(8).toList(), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    final header = ByteData.sublistView(bytes, 16, 24);
    expect(header.getUint32(0), greaterThan(0));
    expect(header.getUint32(4), greaterThan(0));
  });
}
