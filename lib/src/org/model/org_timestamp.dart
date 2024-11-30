part of '../model.dart';

class OrgDiaryTimestamp extends OrgLeafNode with SingleContentElement {
  OrgDiaryTimestamp(this.content);

  // TODO(aaron): Expose actual data
  @override
  final String content;

  @override
  String toString() => 'OrgDiaryTimestamp';
}

typedef OrgDate = ({String year, String month, String day, String dayName});
typedef OrgTime = ({String hour, String minute});

/// A timestamp, like `[2020-05-05 Tue]`
class OrgSimpleTimestamp extends OrgLeafNode {
  OrgSimpleTimestamp(
    this.prefix,
    this.date,
    this.time,
    Iterable<String> repeaterOrDelay,
    this.suffix,
  ) : repeaterOrDelay = List.unmodifiable(repeaterOrDelay);

  final String prefix;
  final OrgDate date;
  final OrgTime? time;
  final List<String> repeaterOrDelay;
  final String suffix;

  @override
  String toString() => 'OrgSimpleTimestamp';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(prefix)
      ..write(date.year)
      ..write('-')
      ..write(date.month)
      ..write('-')
      ..write(date.day)
      ..write(' ')
      ..write(date.dayName);
    if (time != null) {
      buf
        ..write(' ')
        ..write(time!.hour)
        ..write(':')
        ..write(time!.minute);
    }
    if (repeaterOrDelay.isNotEmpty) {
      buf.write(' ');
      buf.write(repeaterOrDelay.join(' '));
    }
    buf.write(suffix);
  }

  @override
  bool contains(Pattern pattern) =>
      prefix.contains(pattern) ||
      date.year.contains(pattern) ||
      date.month.contains(pattern) ||
      date.day.contains(pattern) ||
      date.dayName.contains(pattern) ||
      time?.hour.contains(pattern) == true ||
      time?.minute.contains(pattern) == true ||
      repeaterOrDelay.any((item) => item.contains(pattern)) ||
      suffix.contains(pattern);

  OrgSimpleTimestamp copyWith({
    String? prefix,
    OrgDate? date,
    OrgTime? time,
    Iterable<String>? repeaterOrDelay,
    String? suffix,
  }) =>
      OrgSimpleTimestamp(
        prefix ?? this.prefix,
        date ?? this.date,
        time ?? this.time,
        repeaterOrDelay ?? this.repeaterOrDelay,
        suffix ?? this.suffix,
      );
}

class OrgDateRangeTimestamp extends OrgParentNode {
  OrgDateRangeTimestamp(this.start, this.delimiter, this.end);

  final OrgSimpleTimestamp start;
  final String delimiter;
  final OrgSimpleTimestamp end;

  @override
  List<OrgNode> get children => [start, end];

  @override
  String toString() => 'OrgDateRangeTimestamp';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..visit(start)
      ..write(delimiter)
      ..visit(end);
  }

  @override
  bool contains(Pattern pattern) =>
      start.contains(pattern) ||
      delimiter.contains(pattern) ||
      end.contains(pattern);

  @override
  OrgDateRangeTimestamp fromChildren(List<OrgNode> children) => copyWith(
        start: children.first as OrgSimpleTimestamp,
        end: children.last as OrgSimpleTimestamp,
      );

  OrgDateRangeTimestamp copyWith({
    OrgSimpleTimestamp? start,
    String? delimiter,
    OrgSimpleTimestamp? end,
  }) =>
      OrgDateRangeTimestamp(
        start ?? this.start,
        delimiter ?? this.delimiter,
        end ?? this.end,
      );
}

class OrgTimeRangeTimestamp extends OrgLeafNode {
  OrgTimeRangeTimestamp(
    this.prefix,
    this.date,
    this.timeStart,
    this.timeEnd,
    Iterable<String> repeaterOrDelay,
    this.suffix,
  ) : repeaterOrDelay = List.unmodifiable(repeaterOrDelay);

  final String prefix;
  final OrgDate date;
  final OrgTime timeStart;
  final OrgTime timeEnd;
  final List<String> repeaterOrDelay;
  final String suffix;

  @override
  String toString() => 'OrgTimeRangeTimestamp';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(prefix)
      ..write(date.year)
      ..write('-')
      ..write(date.month)
      ..write('-')
      ..write(date.day)
      ..write(' ')
      ..write(date.dayName)
      ..write(' ')
      ..write(timeStart.hour)
      ..write(':')
      ..write(timeStart.minute)
      ..write('-')
      ..write(timeEnd.hour)
      ..write(':')
      ..write(timeEnd.minute);
    if (repeaterOrDelay.isNotEmpty) {
      buf.write(' ');
      buf.write(repeaterOrDelay.join(' '));
    }
    buf.write(suffix);
  }

  @override
  bool contains(Pattern pattern) =>
      prefix.contains(pattern) ||
      date.year.contains(pattern) ||
      date.month.contains(pattern) ||
      date.day.contains(pattern) ||
      date.dayName.contains(pattern) ||
      timeStart.hour.contains(pattern) ||
      timeStart.minute.contains(pattern) ||
      timeEnd.hour.contains(pattern) ||
      timeEnd.minute.contains(pattern) ||
      repeaterOrDelay.contains(pattern) ||
      suffix.contains(pattern);

  OrgTimeRangeTimestamp copyWith({
    String? prefix,
    OrgDate? date,
    OrgTime? timeStart,
    OrgTime? timeEnd,
    Iterable<String>? repeaterOrDelay,
    String? suffix,
  }) =>
      OrgTimeRangeTimestamp(
        prefix ?? this.prefix,
        date ?? this.date,
        timeStart ?? this.timeStart,
        timeEnd ?? this.timeEnd,
        repeaterOrDelay ?? this.repeaterOrDelay,
        suffix ?? this.suffix,
      );
}
