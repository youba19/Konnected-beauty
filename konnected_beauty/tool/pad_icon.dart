import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates a padded square icon with a black background so the white logo
/// does not fill the entire icon bounds.
///
/// Usage:
///   dart run tool/pad_icon.dart <input_png> <output_png> [scale]
/// - input_png: path to source PNG
/// - output_png: path to write padded PNG
/// - scale: optional scale factor for the logo inside the canvas (0.0-1.0),
///          default 0.8 (20% total padding)
void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
        'Usage: dart run tool/pad_icon.dart <input_png> <output_png> [scale]');
    exit(64);
  }

  final inputPath = args[0];
  final outputPath = args[1];
  final scale = args.length >= 3 ? double.tryParse(args[2]) ?? 0.8 : 0.8;

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Input file not found: $inputPath');
    exit(66);
  }

  final bytes = inputFile.readAsBytesSync();
  final src = img.decodePng(bytes);
  if (src == null) {
    stderr.writeln('Failed to decode image: $inputPath');
    exit(65);
  }

  // Make square canvas using the largest side
  final size = src.width > src.height ? src.width : src.height;
  final out = img.Image(width: size, height: size);

  // Fill background black (iOS will round-mask)
  img.fill(out, color: img.ColorRgb8(0, 0, 0));

  // Resize logo to fit within scale factor of canvas
  final target = (size * scale).round();
  final resized = img.copyResize(src,
      width: target, height: target, interpolation: img.Interpolation.average);

  // Composite centered
  final dx = ((size - resized.width) / 2).round();
  final dy = ((size - resized.height) / 2).round();
  img.compositeImage(out, resized, dstX: dx, dstY: dy);

  // Encode and save
  final outBytes = img.encodePng(out);
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(outBytes);

  stdout.writeln(
      'Wrote padded icon → $outputPath (size: ${out.width}x${out.height}, scale: $scale)');
}
