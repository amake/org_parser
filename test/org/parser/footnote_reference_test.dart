import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('footnote reference', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.footnoteReference()).end();
    test('simple', () {
      var result = parser.parse('[fn:1]');
      final named = result.value as OrgFootnoteReference;
      expect(named.isDefinition, isFalse);
      expect(named.leading, '[fn:');
      expect(named.name, '1');
      expect(named.definition?.delimiter, isNull);
      expect(named.definition, isNull);
      expect(named.trailing, ']');
    });
    test('with definition', () {
      final result = parser.parse('[fn:: who /what/ why]');
      final anonymous = result.value as OrgFootnoteReference;
      expect(anonymous.isDefinition, isFalse);
      expect(anonymous.leading, '[fn:');
      expect(anonymous.name, isNull);
      expect(anonymous.definition?.delimiter, ':');
      final defText0 = anonymous.definition!.value.children[0] as OrgPlainText;
      expect(defText0.content, ' who ');
      expect(anonymous.trailing, ']');
    });
    test('with name', () {
      final result = parser.parse('[fn:abc123: when /where/ how]');
      final inline = result.value as OrgFootnoteReference;
      expect(inline.isDefinition, isFalse);
      expect(inline.leading, '[fn:');
      expect(inline.name, 'abc123');
      expect(inline.definition?.delimiter, ':');
      final defText0 = inline.definition!.value.children[0] as OrgPlainText;
      expect(defText0.content, ' when ');
      expect(inline.trailing, ']');
    });
  });
}
