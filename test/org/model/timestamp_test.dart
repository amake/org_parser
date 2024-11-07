import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('timestamps', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.timestamp()).end();
    test('date', () {
      final markup = '<2020-03-12 Wed>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.toMarkup(), markup);
    });
    test('date and time', () {
      final markup = '<2020-03-12 Wed 8:34>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.toMarkup(), markup);
    });
    test('with repeater', () {
      final markup = '<2020-03-12 Wed 8:34 +1w>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('+1w'), isTrue);
      expect(result.toMarkup(), markup);
    });
    test('with multiple repeaters', () {
      final markup = '<2020-03-12 Wed 8:34 +1w --2d>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('+1w'), isTrue);
      expect(result.contains('--2d'), isTrue);
      expect(result.toMarkup(), markup);
    });
    test('inactive', () {
      final markup = '[2020-03-12 Wed 18:34 .+1w --12d]';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+1w'), isTrue);
      expect(result.contains('--12d'), isTrue);
      expect(result.toMarkup(), markup);
    });
    test('time range', () {
      final markup = '[2020-03-12 Wed 18:34-19:35 .+1w --12d]';
      final result = parser.parse(markup).value as OrgTimeRangeTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+1w'), isTrue);
      expect(result.contains('--12d'), isTrue);
      expect(result.toMarkup(), markup);
    });
    test('date range', () {
      final markup =
          '[2020-03-11 Wed 18:34 .+1w --12d]--[2020-03-12 Wed 18:34 .+1w --12d]';
      final result = parser.parse(markup).value as OrgDateRangeTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('11'), isTrue);
      expect(result.contains('12'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+1w'), isTrue);
      expect(result.contains('--12d'), isTrue);
      expect(result.toMarkup(), markup);
    });
    test('sexp', () {
      final markup = '<%%(what (the (f)))>';
      final result = parser.parse(markup).value as OrgDiaryTimestamp;
      expect(result.contains('what'), isTrue);
      expect(result.toMarkup(), markup);
    });
  });
}
