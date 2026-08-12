import 'dart:io';
import 'dart:typed_data';

import 'package:qr/qr.dart';

class QrPngEncoder {
  const QrPngEncoder._();

  static Uint8List encode(
    String data, {
    int moduleScale = 5,
    int quietZoneModules = 4,
  }) {
    if (data.isEmpty) throw ArgumentError('QR payload cannot be empty');
    if (moduleScale < 1 || moduleScale > 20) {
      throw ArgumentError.range(moduleScale, 1, 20, 'moduleScale');
    }
    if (quietZoneModules < 0 || quietZoneModules > 16) {
      throw ArgumentError.range(quietZoneModules, 0, 16, 'quietZoneModules');
    }

    final code = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final image = QrImage(code);
    final modules = image.moduleCount + (quietZoneModules * 2);
    final width = modules * moduleScale;
    final height = width;
    final raw = BytesBuilder(copy: false);

    for (var y = 0; y < height; y++) {
      raw.addByte(0); // PNG filter: none.
      final moduleY = (y ~/ moduleScale) - quietZoneModules;
      for (var x = 0; x < width; x++) {
        final moduleX = (x ~/ moduleScale) - quietZoneModules;
        final inside = moduleX >= 0 &&
            moduleY >= 0 &&
            moduleX < image.moduleCount &&
            moduleY < image.moduleCount;
        final dark = inside && image.isDark(moduleY, moduleX);
        final value = dark ? 0 : 255;
        raw.add(<int>[value, value, value]);
      }
    }

    final png = BytesBuilder(copy: false)
      ..add(const <int>[137, 80, 78, 71, 13, 10, 26, 10])
      ..add(_chunk('IHDR', _ihdr(width, height)))
      ..add(_chunk('IDAT', ZLibEncoder().convert(raw.takeBytes())))
      ..add(_chunk('IEND', const <int>[]));
    return png.takeBytes();
  }

  static Uint8List _ihdr(int width, int height) {
    final data = ByteData(13)
      ..setUint32(0, width)
      ..setUint32(4, height)
      ..setUint8(8, 8) // bit depth
      ..setUint8(9, 2) // truecolor RGB
      ..setUint8(10, 0)
      ..setUint8(11, 0)
      ..setUint8(12, 0);
    return data.buffer.asUint8List();
  }

  static Uint8List _chunk(String type, List<int> data) {
    final typeBytes = Uint8List.fromList(type.codeUnits);
    final body = Uint8List.fromList(data);
    final result = BytesBuilder(copy: false);
    final length = ByteData(4)..setUint32(0, body.length);
    result
      ..add(length.buffer.asUint8List())
      ..add(typeBytes)
      ..add(body);
    final crcInput = BytesBuilder(copy: false)
      ..add(typeBytes)
      ..add(body);
    final crcData = ByteData(4)..setUint32(0, _crc32(crcInput.takeBytes()));
    result.add(crcData.buffer.asUint8List());
    return result.takeBytes();
  }

  static int _crc32(List<int> bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        final mask = -(crc & 1);
        crc = (crc >>> 1) ^ (0xedb88320 & mask);
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}
