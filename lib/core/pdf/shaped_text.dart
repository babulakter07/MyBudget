import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// True when [s] contains characters the PDF package's built-in fonts cannot
/// draw or shape (Bengali block U+0980-U+09FF, plus ZWJ/ZWNJ joiners).
bool needsShaping(String s) {
  for (final u in s.runes) {
    if ((u >= 0x0980 && u <= 0x09FF) || u == 0x200C || u == 0x200D) {
      return true;
    }
  }
  return false;
}

/// Renders text with Flutter's text engine (HarfBuzz shaping, system Bengali
/// fallback font) into a PNG-backed PDF image. The `pdf` package cannot shape
/// Bengali conjuncts or reorder vowel signs itself, so complex-script text is
/// embedded as a high-resolution image instead.
class ShapedTextRasterizer {
  const ShapedTextRasterizer({this.scale = 4});

  /// Pixels per PDF point. 4 ~ 288 dpi: sharp when printed.
  final double scale;

  /// Returns an image widget for [text], or null if rasterization fails (the
  /// caller then falls back to plain PDF text).
  Future<pw.Widget?> render(
    String text, {
    required double fontSize,
    bool bold = false,
    double maxWidth = 500,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) async {
    try {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize * scale,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF000000),
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: alignment == pw.Alignment.centerRight
            ? TextAlign.right
            : TextAlign.left,
      )..layout(maxWidth: maxWidth * scale);
      final w = painter.width.ceil().clamp(1, 1 << 14);
      final h = painter.height.ceil().clamp(1, 1 << 14);
      final recorder = ui.PictureRecorder();
      painter.paint(ui.Canvas(recorder), ui.Offset.zero);
      final picture = recorder.endRecording();
      final image = await picture.toImage(w, h);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      painter.dispose();
      if (data == null) return null;
      return pw.Image(
        pw.MemoryImage(data.buffer.asUint8List()),
        width: w / scale,
        height: h / scale,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Builds PDF text widgets, rasterizing only strings that need shaping.
class PdfTextFactory {
  PdfTextFactory(this._rasterizer);

  final ShapedTextRasterizer _rasterizer;
  final _cache = <String, pw.Widget?>{};

  Future<pw.Widget> text(
    String s, {
    double fontSize = 12,
    bool bold = false,
    double maxWidth = 500,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? color,
  }) async {
    if (needsShaping(s)) {
      final key =
          '$fontSize|$bold|$maxWidth|${alignment == pw.Alignment.centerRight}|$s';
      if (!_cache.containsKey(key)) {
        _cache[key] = await _rasterizer.render(
          s,
          fontSize: fontSize,
          bold: bold,
          maxWidth: maxWidth,
          alignment: alignment,
        );
      }
      final img = _cache[key];
      if (img != null) return img;
    }
    return pw.Text(
      s,
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    );
  }
}
