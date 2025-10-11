import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('footnote reference', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.footnoteReference()).end();
    test('simple', () {
      final markup = '[fn:1]';
      var result = parser.parse(markup);
      final named = result.value as OrgFootnoteReference;
      expect(named.contains('1'), isTrue);
      expect(named.contains('あ'), isFalse);
      expect(named.toMarkup(), markup);
      expect(named.toPlainText(), '[1]');
    });
    test('with definition', () {
      final markup = '[fn:: who /what/ why]';
      final result = parser.parse(markup);
      final anonymous = result.value as OrgFootnoteReference;
      expect(anonymous.contains('who'), isTrue);
      expect(anonymous.contains('あ'), isFalse);
      expect(anonymous.toMarkup(), markup);
      expect(anonymous.toPlainText(), '[: who what why]');
    });
    test('with name', () {
      final markup = '[fn:abc123: when /where/ how]';
      final result = parser.parse(markup);
      final inline = result.value as OrgFootnoteReference;
      expect(inline.contains('abc123'), isTrue);
      expect(inline.contains('あ'), isFalse);
      expect(inline.toMarkup(), markup);
      expect(inline.toPlainText(), '[abc123: when where how]');
    });
  });
}
