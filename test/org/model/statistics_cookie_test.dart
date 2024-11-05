import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('markups', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.statsCookie()).end();
    group('percentage', () {
      test('simple', () {
        final markup = '[50%]';
        final result =
            parser.parse(markup).value as OrgStatisticsPercentageCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('50'), isTrue);
        expect(result.done, isFalse);
        final updated = result.update(done: 1, total: 3);
        expect(updated.toMarkup(), '[33%]');
      });
      test('empty', () {
        final markup = '[%]';
        final result =
            parser.parse(markup).value as OrgStatisticsPercentageCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('%'), isTrue);
        expect(result.done, isFalse);
      });
      test('done', () {
        final markup = '[100%]';
        final result =
            parser.parse(markup).value as OrgStatisticsPercentageCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('100'), isTrue);
        expect(result.done, isTrue);
      });
      test('not done', () {
        final markup = '[0%]';
        final result =
            parser.parse(markup).value as OrgStatisticsPercentageCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('0'), isTrue);
        expect(result.done, isFalse);
      });
    });
    group('fraction', () {
      test('simple', () {
        final markup = '[1/2]';
        final result =
            parser.parse(markup).value as OrgStatisticsFractionCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('1'), isTrue);
        expect(result.done, isFalse);
        final updated = result.update(done: 2, total: 3);
        expect(updated.toMarkup(), '[2/3]');
      });
      test('empty', () {
        final markup = '[/]';
        final result =
            parser.parse(markup).value as OrgStatisticsFractionCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('/'), isTrue);
        expect(result.done, isFalse);
      });
      test('vacuous done', () {
        final markup = '[0/0]';
        final result =
            parser.parse(markup).value as OrgStatisticsFractionCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('0'), isTrue);
        expect(result.done, isTrue);
      });
      test('partial', () {
        final markup = '[/2]';
        final result =
            parser.parse(markup).value as OrgStatisticsFractionCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('2'), isTrue);
        expect(result.done, isFalse);
      });
      test('done', () {
        final markup = '[2/2]';
        final result =
            parser.parse(markup).value as OrgStatisticsFractionCookie;
        expect(result.toMarkup(), markup);
        expect(result.contains('2'), isTrue);
        expect(result.done, isTrue);
      });
    });
  });
}
