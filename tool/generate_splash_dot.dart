// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

/// Writes `assets/splash/wayo_dot.png` (192×192, orange #F47A1F circle, transparent bg).
void main() {
  const w = 192;
  const h = 192;
  final rgba = Uint8List(w * h * 4);
  const cx = 96.0;
  const cy = 96.0;
  const r = 32.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final i = (y * w + x) * 4;
      if (dx * dx + dy * dy <= r * r) {
        rgba[i] = 244;
        rgba[i + 1] = 122;
        rgba[i + 2] = 31;
        rgba[i + 3] = 255;
      } else {
        rgba[i] = 0;
        rgba[i + 1] = 0;
        rgba[i + 2] = 0;
        rgba[i + 3] = 0;
      }
    }
  }
  final path = 'assets/splash/wayo_dot.png';
  File(path).writeAsBytesSync(_encodePng(w, h, rgba));
  print('Wrote $path');
}

Uint8List _encodePng(int width, int height, Uint8List rgba) {
  final b = BytesBuilder();
  b.add([137, 80, 78, 71, 13, 10, 26, 10]);
  _chunk(b, 'IHDR', _ihdr(width, height));
  _chunk(b, 'IDAT', _idat(width, height, rgba));
  _chunk(b, 'IEND', Uint8List(0));
  return b.toBytes();
}

Uint8List _ihdr(int w, int h) {
  final d = ByteData(13);
  d.setUint32(0, w, Endian.big);
  d.setUint32(4, h, Endian.big);
  d.setUint8(8, 8);
  d.setUint8(9, 6);
  d.setUint8(10, 0);
  d.setUint8(11, 0);
  d.setUint8(12, 0);
  return d.buffer.asUint8List();
}

Uint8List _idat(int width, int height, Uint8List rgba) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    raw.add(rgba.sublist(y * width * 4, (y + 1) * width * 4));
  }
  return Uint8List.fromList(ZLibEncoder().convert(raw.toBytes()));
}

void _chunk(BytesBuilder b, String tag, Uint8List data) {
  final tagB = Uint8List.fromList(tag.codeUnits);
  final len = ByteData(4)..setUint32(0, data.length, Endian.big);
  b.add(len.buffer.asUint8List());
  b.add(tagB);
  b.add(data);
  final crcIn = Uint8List(tagB.length + data.length);
  crcIn.setAll(0, tagB);
  crcIn.setAll(tagB.length, data);
  final crc = ByteData(4)..setUint32(0, _crc32(crcIn), Endian.big);
  b.add(crc.buffer.asUint8List());
}

int _crc32(Uint8List bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
