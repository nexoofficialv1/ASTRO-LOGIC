import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class SignedReportQrView extends StatelessWidget {
  const SignedReportQrView({
    required this.payload,
    this.size = 190,
    super.key,
  });

  final String payload;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = QrImage(
      QrCode.fromData(
        data: payload,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      ),
    );
    return Semantics(
      label: 'Signed report verification QR',
      image: true,
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: CustomPaint(
            size: Size.square(size),
            painter: _QrPainter(image, payload),
          ),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter(this.image, this.payload);

  final QrImage image;
  final String payload;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cell = size.shortestSide / image.moduleCount;
    for (var row = 0; row < image.moduleCount; row++) {
      for (var column = 0; column < image.moduleCount; column++) {
        if (!image.isDark(row, column)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            column * cell,
            row * cell,
            cell.ceilToDouble(),
            cell.ceilToDouble(),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.payload != payload;
}
