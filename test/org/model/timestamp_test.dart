import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart' hide predicate;
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
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.repeats, isFalse);
      expect(result.hasDelay, isFalse);
      expect(result.dateTime, DateTime(2020, 03, 12));
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(), '2020-03-12 Wed');
    });
    test('date and time', () {
      final markup = '<2020-03-12 Wed 8:34>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.repeats, isFalse);
      expect(result.hasDelay, isFalse);
      expect(result.dateTime, DateTime(2020, 03, 12, 08, 34));
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(), '2020-03-12 Wed 8:34');
    });
    test('with repeater', () {
      final markup = '<2020-03-12 Wed 8:34 +1w>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('w'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.repeats, isTrue);
      expect(result.hasDelay, isFalse);
      expect(result.dateTime, DateTime(2020, 03, 12, 08, 34));
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(), '2020-03-12 Wed 8:34 +1w');
    });
    test('with repeater (min/max)', () {
      final markup = '<2020-03-12 Wed 8:34 +1w/2w>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('w'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.repeats, isTrue);
      expect(result.hasDelay, isFalse);
      expect(result.dateTime, DateTime(2020, 03, 12, 08, 34));
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(), '2020-03-12 Wed 8:34 +1w/2w');
    });
    test('with multiple repeaters', () {
      final markup = '<2020-03-12 Wed 8:34 +1w --2d>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('w'), isTrue);
      expect(result.contains('--'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.dateTime, DateTime(2020, 03, 12, 08, 34));
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(), '2020-03-12 Wed 8:34 +1w --2d');
    });
    test('inactive', () {
      final markup = '[2020-03-12 Wed 18:34 .+1w --12d]';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+'), isTrue);
      expect(result.contains('--'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isFalse);
      expect(result.repeats, isTrue);
      expect(result.hasDelay, isTrue);
      expect(result.dateTime, DateTime(2020, 03, 12, 18, 34));
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(), '2020-03-12 Wed 18:34 .+1w --12d');
    });
    test('time range', () {
      final markup = '[2020-03-12 Wed 18:34-19:35 .+1w --12d]';
      final result = parser.parse(markup).value as OrgTimeRangeTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+'), isTrue);
      expect(result.contains('12'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isFalse);
      expect(result.repeats, isTrue);
      expect(result.hasDelay, isTrue);
      expect(result.startDateTime, DateTime(2020, 03, 12, 18, 34));
      expect(result.endDateTime, DateTime(2020, 03, 12, 19, 35));
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(), '2020-03-12 Wed 18:34-19:35 .+1w --12d');
    });
    test('date range', () {
      final markup =
          '[2020-03-11 Wed 18:34 .+1w --12d]--[2020-03-12 Wed 18:34 .+1w --12d]';
      final result = parser.parse(markup).value as OrgDateRangeTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('11'), isTrue);
      expect(result.contains('12'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+'), isTrue);
      expect(result.contains('d'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isFalse);
      expect(result.start.repeats, isTrue);
      expect(result.start.hasDelay, isTrue);
      expect(result.end.repeats, isTrue);
      expect(result.end.hasDelay, isTrue);
      expect(result.start.dateTime, DateTime(2020, 03, 11, 18, 34));
      expect(result.end.dateTime, DateTime(2020, 03, 12, 18, 34));
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(),
          '2020-03-11 Wed 18:34 .+1w --12d--2020-03-12 Wed 18:34 .+1w --12d');
    });
    test('sexp', () {
      final markup = '<%%(what (the (f)))>';
      final result = parser.parse(markup).value as OrgDiaryTimestamp;
      expect(result.contains('what'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.toMarkup(), markup);
      expect(result.toPlainText(), '<%%(what (the (f)))>');
    });
    group("generic timestamp tests", () {
      test('OrgSimpleTimestamp', () {
        final markup = '<2025-05-30>';
        final result = parser.parse(markup).value as OrgTimestamp;

        expect(result.isActive, isTrue);
        expect(result, isA<OrgTimestamp>());
        expect(result, isA<OrgSimpleTimestamp>());
        expect(result, isNot(isA<OrgDateRangeTimestamp>()));
        expect(result, isNot(isA<OrgTimeRangeTimestamp>()));
        expect(result.toMarkup(), markup);
        expect(result.toPlainText(), '2025-05-30');
      });
      test('OrgTimeRangeTimestamp', () {
        final markup = '<2025-05-30 15:00-16:00>';
        final result = parser.parse(markup).value as OrgTimestamp;

        expect(result.isActive, isTrue);
        expect(result, isA<OrgTimestamp>());
        expect(result, isA<OrgTimeRangeTimestamp>());
        expect(result, isNot(isA<OrgSimpleTimestamp>()));
        expect(result, isNot(isA<OrgDateRangeTimestamp>()));
        expect(result.toMarkup(), markup);
        expect(result.toPlainText(), '2025-05-30 15:00-16:00');
      });
      test('OrgDateRangeTimestamp', () {
        final markup = '[2025-05-30]--[2025-06-30]';
        final result = parser.parse(markup).value as OrgTimestamp;

        expect(result.isActive, isFalse);
        expect(result, isA<OrgTimestamp>());
        expect(result, isA<OrgDateRangeTimestamp>());
        expect(result, isNot(isA<OrgSimpleTimestamp>()));
        expect(result, isNot(isA<OrgTimeRangeTimestamp>()));
        expect(result.toMarkup(), markup);
        expect(result.toPlainText(), '2025-05-30--2025-06-30');
      });
      test('Exhaustivity', () {
        final markup = '[2025-05-30]--[2025-06-30]';
        final result = parser.parse(markup).value as OrgTimestamp;

        final type = switch (result) {
          OrgTimeRangeTimestamp() => result.toString(),
          OrgDateRangeTimestamp() => result.toString(),
          OrgSimpleTimestamp() => result.toString(),
        };
        expect(type, isNotEmpty);
      });
    });
    group('bump', () {
      Matcher bumpsTo(String expected, [DateTime? now]) =>
          predicate((String markup) {
            final result = parser.parse(markup).value as OrgTimestamp;
            final bumped = result.bumpRepetition(now);
            return bumped.toMarkup() == expected;
          }, "bumps to '$expected'");
      test('Non-bumpable', () {
        final markup = '<2020-03-12 Wed 8:34 --2d>';
        expect(markup, bumpsTo(markup));
      });
      group('Simple bump (+)', () {
        test('hour', () {
          expect('<2020-03-12 Wed 8:34 +1h --2d>',
              bumpsTo('<2020-03-12 Thu 09:34 +1h --2d>'));
        });
        test('hours', () {
          expect('<2020-03-12 Wed 8:34 +3h --2d>',
              bumpsTo('<2020-03-12 Thu 11:34 +3h --2d>'));
        });
        test('day', () {
          expect('<2020-03-12 Wed 8:34 +1d --2d>',
              bumpsTo('<2020-03-13 Fri 08:34 +1d --2d>'));
        });
        test('days', () {
          expect('<2020-03-12 Wed 8:34 +3d --2d>',
              bumpsTo('<2020-03-15 Sun 08:34 +3d --2d>'));
        });
        test('week', () {
          expect('<2020-03-12 Wed 8:34 +1w --2d>',
              bumpsTo('<2020-03-19 Thu 08:34 +1w --2d>'));
        });
        test('weeks', () {
          expect('<2020-03-12 Wed 8:34 +2w --2d>',
              bumpsTo('<2020-03-26 Thu 08:34 +2w --2d>'));
        });
        test('month', () {
          expect('<2020-03-12 Wed 8:34 +1m --2d>',
              bumpsTo('<2020-04-12 Sun 08:34 +1m --2d>'));
        });
        test('months', () {
          expect('<2020-03-12 Wed 8:34 +2m --2d>',
              bumpsTo('<2020-05-12 Tue 08:34 +2m --2d>'));
        });
        test('year', () {
          expect('<2020-03-12 Wed 8:34 +1y --2d>',
              bumpsTo('<2021-03-12 Fri 08:34 +1y --2d>'));
        });
        test('years', () {
          expect('<2020-03-12 Wed 8:34 +2y --2d>',
              bumpsTo('<2022-03-12 Sat 08:34 +2y --2d>'));
        });
      });
      group('Bump past now (++)', () {
        test('hour', () {
          final now = DateTime(2020, 03, 12, 10, 00);
          expect('<2020-03-12 Wed 8:34 ++1h --2d>',
              bumpsTo('<2020-03-12 Thu 10:34 ++1h --2d>', now));
        });
        test('hours', () {
          final now = DateTime(2020, 03, 12, 12, 00);
          expect('<2020-03-12 Wed 8:34 ++3h --2d>',
              bumpsTo('<2020-03-12 Thu 14:34 ++3h --2d>', now));
        });
        test('day', () {
          final now = DateTime(2020, 03, 14, 08, 00);
          expect('<2020-03-12 Wed 8:34 ++1d --2d>',
              bumpsTo('<2020-03-14 Sat 08:34 ++1d --2d>', now));
        });
        test('days', () {
          final now = DateTime(2020, 03, 16, 08, 00);
          expect('<2020-03-12 Wed 8:34 ++3d --2d>',
              bumpsTo('<2020-03-18 Wed 08:34 ++3d --2d>', now));
        });
        test('week', () {
          final now = DateTime(2020, 03, 20, 08, 00);
          expect('<2020-03-12 Wed 8:34 ++1w --2d>',
              bumpsTo('<2020-03-26 Thu 08:34 ++1w --2d>', now));
        });
        test('weeks', () {
          final now = DateTime(2020, 04, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 ++2w --2d>',
              bumpsTo('<2020-04-09 Thu 08:34 ++2w --2d>', now));
        });
        test('month', () {
          final now = DateTime(2020, 05, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 ++1m --2d>',
              bumpsTo('<2020-05-12 Tue 08:34 ++1m --2d>', now));
        });
        test('months', () {
          final now = DateTime(2020, 06, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 ++2m --2d>',
              bumpsTo('<2020-07-12 Sun 08:34 ++2m --2d>', now));
        });
        test('year', () {
          final now = DateTime(2021, 04, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 ++1y --2d>',
              bumpsTo('<2022-03-12 Sat 08:34 ++1y --2d>', now));
        });
        test('years', () {
          final now = DateTime(2023, 04, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 ++2y --2d>',
              bumpsTo('<2024-03-12 Tue 08:34 ++2y --2d>', now));
        });
        test('future', () {
          // Now is in the past of the timestamp, so just bump once.
          final now = DateTime(2020, 03, 12, 8, 00);
          expect('<2020-03-12 Wed 8:34 ++1h --2d>',
              bumpsTo('<2020-03-12 Thu 09:34 ++1h --2d>', now));
        });
      });
      group('Bump from now (.+)', () {
        test('hour', () {
          final now = DateTime(2020, 03, 13, 10, 00);
          expect('<2020-03-12 Wed 8:34 .+1h --2d>',
              bumpsTo('<2020-03-13 Fri 11:00 .+1h --2d>', now));
        });
        test('hours', () {
          final now = DateTime(2020, 03, 13, 12, 00);
          expect('<2020-03-12 Wed 8:34 .+3h --2d>',
              bumpsTo('<2020-03-13 Fri 15:00 .+3h --2d>', now));
        });
        test('day', () {
          final now = DateTime(2020, 03, 14, 08, 00);
          expect('<2020-03-12 Wed 8:34 .+1d --2d>',
              bumpsTo('<2020-03-15 Sun 08:34 .+1d --2d>', now));
        });
        test('days', () {
          final now = DateTime(2020, 03, 16, 08, 00);
          expect('<2020-03-12 Wed 8:34 .+3d --2d>',
              bumpsTo('<2020-03-19 Thu 08:34 .+3d --2d>', now));
        });
        test('week', () {
          final now = DateTime(2020, 03, 20, 08, 00);
          expect('<2020-03-12 Wed 8:34 .+1w --2d>',
              bumpsTo('<2020-03-27 Fri 08:34 .+1w --2d>', now));
        });
        test('weeks', () {
          final now = DateTime(2020, 04, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 .+2w --2d>',
              bumpsTo('<2020-04-15 Wed 08:34 .+2w --2d>', now));
        });
        test('month', () {
          final now = DateTime(2020, 05, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 .+1m --2d>',
              bumpsTo('<2020-06-01 Mon 08:34 .+1m --2d>', now));
        });
        test('months', () {
          final now = DateTime(2020, 06, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 .+2m --2d>',
              bumpsTo('<2020-08-01 Sat 08:34 .+2m --2d>', now));
        });
        test('year', () {
          final now = DateTime(2021, 04, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 .+1y --2d>',
              bumpsTo('<2022-04-01 Fri 08:34 .+1y --2d>', now));
        });
        test('years', () {
          final now = DateTime(2023, 04, 01, 08, 00);
          expect('<2020-03-12 Wed 8:34 .+2y --2d>',
              bumpsTo('<2025-04-01 Tue 08:34 .+2y --2d>', now));
        });
        test('future', () {
          // Now is in the past of the timestamp
          final now = DateTime(2020, 03, 12, 8, 00);
          expect('<2020-03-12 Wed 8:34 .+1h --2d>',
              bumpsTo('<2020-03-12 Thu 09:00 .+1h --2d>', now));
        });
      });
    });
  });
}
