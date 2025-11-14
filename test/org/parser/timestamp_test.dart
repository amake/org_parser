import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart' hide predicate;
import 'package:test/test.dart';

Matcher matchesModifier(OrgTimestampModifier modifier) =>
    predicate<OrgTimestampModifier>(
      (m) =>
          m.prefix == modifier.prefix &&
          m.value == modifier.value &&
          m.unit == modifier.unit &&
          m.suffix?.delimiter == modifier.suffix?.delimiter &&
          m.suffix?.value == modifier.suffix?.value &&
          m.suffix?.unit == modifier.suffix?.unit,
      'matches modifier ${modifier.toMarkup()}',
    );

void main() {
  group('timestamps', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.timestamp()).end();
    test('date', () {
      final result =
          parser.parse('<2020-03-12 Wed>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNull);
      expect(result.modifiers, isEmpty);
      expect(result.suffix, '>');
    });
    test('date without day of week', () {
      final result = parser.parse('<2020-03-12>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, isNull);
      expect(result.time, isNull);
      expect(result.modifiers, isEmpty);
      expect(result.suffix, '>');
    });
    test('date and time', () {
      final result =
          parser.parse('<2020-03-12 Wed 8:34>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNotNull);
      expect(result.time!.hour, '8');
      expect(result.time!.minute, '34');
      expect(result.modifiers, isEmpty);
      expect(result.suffix, '>');
    });
    test('date and time without day of week', () {
      final result =
          parser.parse('<2020-03-12 8:34>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, isNull);
      expect(result.time, isNotNull);
      expect(result.time!.hour, '8');
      expect(result.time!.minute, '34');
      expect(result.modifiers, isEmpty);
      expect(result.suffix, '>');
    });
    test('with repeater', () {
      final result =
          parser.parse('<2020-03-12 Wed 8:34 +1w>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNotNull);
      expect(result.time!.hour, '8');
      expect(result.time!.minute, '34');
      expect(result.modifiers.single.prefix, '+');
      expect(result.modifiers.single.value, '1');
      expect(result.modifiers.single.unit, 'w');
      expect(result.modifiers.single.suffix, isNull);
      expect(result.suffix, '>');
    });
    test('with multiple repeaters', () {
      final result = parser.parse('<2020-03-12 Wed 8:34 +1w --2d>').value
          as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNotNull);
      expect(result.time!.hour, '8');
      expect(result.time!.minute, '34');
      expect(result.modifiers, [
        matchesModifier(OrgTimestampModifier('+', '1', 'w', null)),
        matchesModifier(OrgTimestampModifier('--', '2', 'd', null))
      ]);
      expect(result.suffix, '>');
    });
    test('inactive', () {
      final result = parser.parse('[2020-03-12 Wed 18:34 .+1w --12d]').value
          as OrgSimpleTimestamp;
      expect(result.prefix, '[');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNotNull);
      expect(result.time!.hour, '18');
      expect(result.time!.minute, '34');
      expect(result.modifiers, [
        matchesModifier(OrgTimestampModifier('.+', '1', 'w', null)),
        matchesModifier(OrgTimestampModifier('--', '12', 'd', null))
      ]);
      expect(result.suffix, ']');
    });
    test('time range', () {
      final result = parser
          .parse('[2020-03-12 Wed 18:34-19:35 .+1w --12d]')
          .value as OrgTimeRangeTimestamp;
      expect(result.prefix, '[');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.timeStart.hour, '18');
      expect(result.timeStart.minute, '34');
      expect(result.timeEnd.hour, '19');
      expect(result.timeEnd.minute, '35');
      expect(result.modifiers, [
        matchesModifier(OrgTimestampModifier('.+', '1', 'w', null)),
        matchesModifier(OrgTimestampModifier('--', '12', 'd', null))
      ]);
      expect(result.suffix, ']');
    });
    test('time range without day of week', () {
      final result = parser.parse('[2020-03-12 18:34-19:35 .+1w --12d]').value
          as OrgTimeRangeTimestamp;
      expect(result.prefix, '[');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, isNull);
      expect(result.timeStart.hour, '18');
      expect(result.timeStart.minute, '34');
      expect(result.timeEnd.hour, '19');
      expect(result.timeEnd.minute, '35');
      expect(result.modifiers, [
        matchesModifier(OrgTimestampModifier('.+', '1', 'w', null)),
        matchesModifier(OrgTimestampModifier('--', '12', 'd', null))
      ]);
      expect(result.suffix, ']');
    });
    test('date range', () {
      final result = parser
          .parse(
              '[2020-03-11 Wed 18:34 .+1w --12d]--[2020-03-12 Wed 18:34 .+1w --12d]')
          .value as OrgDateRangeTimestamp;
      final start = result.start as OrgSimpleTimestamp;
      expect(start.prefix, '[');
      expect(start.date.year, '2020');
      expect(start.date.month, '03');
      expect(start.date.day, '11');
      expect(start.date.dayName, 'Wed');
      expect(start.time!.hour, '18');
      expect(start.time!.minute, '34');
      expect(start.modifiers, [
        matchesModifier(OrgTimestampModifier('.+', '1', 'w', null)),
        matchesModifier(OrgTimestampModifier('--', '12', 'd', null))
      ]);
      expect(start.suffix, ']');
      expect(result.delimiter, '--');
      final end = result.end as OrgSimpleTimestamp;
      expect(end.prefix, '[');
      expect(end.date.year, '2020');
      expect(end.date.month, '03');
      expect(end.date.day, '12');
      expect(end.date.dayName, 'Wed');
      expect(end.time!.hour, '18');
      expect(end.time!.minute, '34');
      expect(end.modifiers, [
        matchesModifier(OrgTimestampModifier('.+', '1', 'w', null)),
        matchesModifier(OrgTimestampModifier('--', '12', 'd', null))
      ]);
      expect(end.suffix, ']');
    });
    test('date range with time range', () {
      final result = parser
          .parse(
              '[2020-03-11 Wed 18:34-19:34 .+1w --12d]--[2020-03-12 Wed 18:34-19:34 .+1w --12d]')
          .value as OrgDateRangeTimestamp;
      final start = result.start as OrgTimeRangeTimestamp;
      expect(start.prefix, '[');
      expect(start.date.year, '2020');
      expect(start.date.month, '03');
      expect(start.date.day, '11');
      expect(start.date.dayName, 'Wed');
      expect(start.timeStart.hour, '18');
      expect(start.timeStart.minute, '34');
      expect(start.timeEnd.hour, '19');
      expect(start.timeEnd.minute, '34');
      expect(start.modifiers, [
        matchesModifier(OrgTimestampModifier('.+', '1', 'w', null)),
        matchesModifier(OrgTimestampModifier('--', '12', 'd', null))
      ]);
      expect(start.suffix, ']');
      expect(result.delimiter, '--');
      final end = result.end as OrgTimeRangeTimestamp;
      expect(end.prefix, '[');
      expect(end.date.year, '2020');
      expect(end.date.month, '03');
      expect(end.date.day, '12');
      expect(end.date.dayName, 'Wed');
      expect(end.timeStart.hour, '18');
      expect(end.timeStart.minute, '34');
      expect(end.timeEnd.hour, '19');
      expect(end.timeEnd.minute, '34');
      expect(end.modifiers, [
        matchesModifier(OrgTimestampModifier('.+', '1', 'w', null)),
        matchesModifier(OrgTimestampModifier('--', '12', 'd', null))
      ]);
      expect(end.suffix, ']');
    });
    test('sexp', () {
      final result =
          parser.parse('<%%(what (the (f))) foo>').value as OrgDiaryTimestamp;
      expect(result.content, '<%%(what (the (f))) foo>');
    });
  });
}
