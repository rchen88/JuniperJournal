import 'package:flutter_test/flutter_test.dart';
import 'package:juniper_journal/src/features/project/utils/journal_embed_codec.dart';

void main() {
  group('JournalEmbedCodec', () {
    test('encodes and decodes math url', () {
      const latex = r'x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}';

      final encoded = JournalEmbedCodec.encodeMathUrl(latex);
      expect(JournalEmbedCodec.isMathUrl(encoded), isTrue);

      final decoded = JournalEmbedCodec.decodeMathUrl(encoded);
      expect(decoded, latex);
    });

    test('creates empty table with expected dimensions and defaults', () {
      final table = JournalEmbedCodec.createEmptyTable(2, 3);

      expect(table.rows, 2);
      expect(table.cols, 3);
      expect(table.cells.length, 2);
      expect(table.cells[0].length, 3);
      expect(table.cells[1].length, 3);
      expect(table.cells[0][0], '');
      expect(table.cells[1][2], '');
    });

    test('encodes and decodes table url', () {
      final table = JournalTableEmbedData(
        rows: 2,
        cols: 2,
        cells: const [
          ['a', 'b'],
          ['c', 'd'],
        ],
      );

      final encoded = JournalEmbedCodec.encodeTableUrl(table);
      expect(JournalEmbedCodec.isTableUrl(encoded), isTrue);

      final decoded = JournalEmbedCodec.decodeTableUrl(encoded);
      expect(decoded.rows, 2);
      expect(decoded.cols, 2);
      expect(decoded.cells, const [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    });

    test('url type guards return false for null and unknown schemes', () {
      expect(JournalEmbedCodec.isMathUrl(null), isFalse);
      expect(JournalEmbedCodec.isTableUrl(null), isFalse);
      expect(
        JournalEmbedCodec.isMathUrl('https://example.com/image.png'),
        isFalse,
      );
      expect(JournalEmbedCodec.isTableUrl('math://abc'), isFalse);
    });
  });
}
