import 'package:clingfy/core/export/models/export_settings_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export parsers use safe fallback for unknown values', () {
    expect(exportFormatFromWire('mov'), ExportFormat.mov);
    expect(
      exportFormatFromWire('legacy', fallback: ExportFormat.mp4),
      ExportFormat.mp4,
    );

    expect(exportCodecFromWire('h264'), ExportCodec.h264);
    expect(
      exportCodecFromWire('legacy', fallback: ExportCodec.hevc),
      ExportCodec.hevc,
    );

    expect(exportBitratePresetFromWire('high'), ExportBitratePreset.high);
    expect(
      exportBitratePresetFromWire(
        'legacy',
        fallback: ExportBitratePreset.medium,
      ),
      ExportBitratePreset.medium,
    );
  });

  test('enum wire values stay backward-compatible', () {
    expect(ExportFormat.mov.wireValue, 'mov');
    expect(ExportFormat.mp4.wireValue, 'mp4');
    expect(ExportFormat.gif.wireValue, 'gif');

    expect(ExportCodec.hevc.wireValue, 'hevc');
    expect(ExportCodec.h264.wireValue, 'h264');

    expect(ExportBitratePreset.auto.wireValue, 'auto');
    expect(ExportBitratePreset.low.wireValue, 'low');
    expect(ExportBitratePreset.medium.wireValue, 'medium');
    expect(ExportBitratePreset.high.wireValue, 'high');
  });
}
