part of '../model.dart';

class OrgDiaryTimestamp extends OrgLeafNode with SingleContentElement {
  OrgDiaryTimestamp(this.content);

  // TODO(aaron): Expose actual data
  @override
  final String content;

  @override
  String toString() => 'OrgDiaryTimestamp';
}

class OrgTimestampModifier extends OrgLeafNode {
  OrgTimestampModifier(this.prefix, this.value, this.unit, this.suffix);

  final String prefix;
  final String value;
  final String unit;
  final ({String delimiter, String value, String unit})? suffix;

  bool get isRepeater => prefix == '+' || prefix == '.+' || prefix == '++';
  bool get isDelay => prefix == '-' || prefix == '--';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(prefix)
      ..write(value)
      ..write(unit);
    if (suffix != null) {
      buf
        ..write(suffix!.delimiter)
        ..write(suffix!.value)
        ..write(suffix!.unit);
    }
  }

  @override
  bool contains(Pattern pattern) =>
      prefix.contains(pattern) ||
      value.contains(pattern) ||
      unit.contains(pattern) ||
      (suffix != null &&
          (suffix!.delimiter.contains(pattern) ||
              suffix!.value.contains(pattern) ||
              suffix!.unit.contains(pattern)));

  @override
  String toString() => 'OrgTimestampModifier';
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

extension OrgModifierUtils on DateTime {
  DateTime addModifier(int value, String unit) => switch (unit) {
        'h' => copyWith(hour: hour + value),
        'd' => copyWith(day: day + value),
        'w' => copyWith(day: day + (value * 7)),
        'm' => copyWith(month: month + value),
        'y' => copyWith(year: year + value),
        _ => throw UnimplementedError('Unknown unit: $unit'),
      };

  OrgDate toOrgDate() => (
        year: year.toString().padLeft(4, '0'),
        month: month.toString().padLeft(2, '0'),
        day: day.toString().padLeft(2, '0'),
        dayName: _weekdayNames[weekday - 1],
      );

  OrgTime toOrgTime() => (
        hour: hour.toString().padLeft(2, '0'),
        minute: minute.toString().padLeft(2, '0'),
      );
}

typedef OrgDate = ({String year, String month, String day, String? dayName});
typedef OrgTime = ({String hour, String minute});

sealed class OrgTimestamp extends OrgNode {
  bool get isActive;
  bool get repeats;
  bool get hasDelay;
}

/// A timestamp, like `[2020-05-05 Tue]`
class OrgSimpleTimestamp extends OrgParentNode implements OrgTimestamp {
  OrgSimpleTimestamp(
    this.prefix,
    this.date,
    this.time,
    Iterable<OrgTimestampModifier> modifiers,
    this.suffix,
  ) : modifiers = List.unmodifiable(modifiers);

  final String prefix;
  final OrgDate date;
  final OrgTime? time;
  final List<OrgTimestampModifier> modifiers;
  final String suffix;

  @override
  List<OrgNode> get children => modifiers;

  @override
  OrgSimpleTimestamp fromChildren(List<OrgNode> children) => copyWith(
        modifiers: children.cast<OrgTimestampModifier>(),
      );

  @override
  bool get isActive => prefix == '<' && suffix == '>';
  @override
  bool get repeats => modifiers.any((m) => m.isRepeater);
  @override
  bool get hasDelay => modifiers.any((m) => m.isDelay);

  OrgSimpleTimestamp bumpRepetition([DateTime? now]) {
    if (!repeats) return this;
    now ??= DateTime.now();
    final repeater = modifiers.firstWhere((m) => m.isRepeater);
    final value = int.parse(repeater.value);
    var newDateTime = dateTime;
    switch (repeater.prefix) {
      case '+':
        newDateTime = newDateTime.addModifier(value, repeater.unit);
      case '++':
        // If already in the future, bump once. Otherwise bump until in the
        // future.
        do {
          newDateTime = newDateTime.addModifier(value, repeater.unit);
        } while (newDateTime.isBefore(now));
      case '.+':
        newDateTime = now.addModifier(value, repeater.unit);
        if (repeater.unit != 'h') {
          // Preserve the time of day for non-hourly repeaters
          newDateTime = newDateTime.copyWith(
            hour: dateTime.hour,
            minute: dateTime.minute,
          );
        }
      default:
        throw UnimplementedError('Unknown repeater prefix: ${repeater.prefix}');
    }
    return copyWith(
      date: newDateTime.toOrgDate(),
      time: time == null ? null : newDateTime.toOrgTime(),
    );
  }

  @override
  String toString() => 'OrgSimpleTimestamp';

  DateTime get dateTime => DateTime(
        int.parse(date.year),
        int.parse(date.month),
        int.parse(date.day),
        time == null ? 0 : int.parse(time!.hour),
        time == null ? 0 : int.parse(time!.minute),
      );

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf.write(prefix);
    _toPlainTextImpl(buf);
    buf.write(suffix);
  }

  @override
  void _toPlainTextImpl(OrgSerializer buf) {
    buf
      ..write(date.year)
      ..write('-')
      ..write(date.month)
      ..write('-')
      ..write(date.day);
    if (date.dayName != null) {
      buf
        ..write(' ')
        ..write(date.dayName!);
    }
    if (time != null) {
      buf
        ..write(' ')
        ..write(time!.hour)
        ..write(':')
        ..write(time!.minute);
    }
    if (modifiers.isNotEmpty) {
      buf.write(' ');
      for (var i = 0; i < modifiers.length; i++) {
        if (i > 0) buf.write(' ');
        buf.visit(modifiers[i]);
      }
    }
  }

  @override
  bool contains(Pattern pattern) =>
      prefix.contains(pattern) ||
      date.year.contains(pattern) ||
      date.month.contains(pattern) ||
      date.day.contains(pattern) ||
      date.dayName?.contains(pattern) == true ||
      time?.hour.contains(pattern) == true ||
      time?.minute.contains(pattern) == true ||
      modifiers.any((item) => item.contains(pattern)) ||
      suffix.contains(pattern);

  OrgSimpleTimestamp copyWith({
    String? prefix,
    OrgDate? date,
    OrgTime? time,
    Iterable<OrgTimestampModifier>? modifiers,
    String? suffix,
  }) =>
      OrgSimpleTimestamp(
        prefix ?? this.prefix,
        date ?? this.date,
        time ?? this.time,
        modifiers ?? this.modifiers,
        suffix ?? this.suffix,
      );
}

class OrgDateRangeTimestamp extends OrgParentNode implements OrgTimestamp {
  OrgDateRangeTimestamp(this.start, this.delimiter, this.end);

  final OrgSimpleTimestamp start;
  final String delimiter;
  final OrgSimpleTimestamp end;

  @override
  bool get isActive => start.isActive && end.isActive;
  @override
  bool get repeats => start.repeats || end.repeats;
  @override
  bool get hasDelay => start.hasDelay || end.hasDelay;

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

class OrgTimeRangeTimestamp extends OrgParentNode implements OrgTimestamp {
  OrgTimeRangeTimestamp(
    this.prefix,
    this.date,
    this.timeStart,
    this.timeEnd,
    Iterable<OrgTimestampModifier> modifiers,
    this.suffix,
  ) : modifiers = List.unmodifiable(modifiers);

  final String prefix;
  final OrgDate date;
  final OrgTime timeStart;
  final OrgTime timeEnd;
  final List<OrgTimestampModifier> modifiers;
  final String suffix;

  @override
  List<OrgNode> get children => modifiers;

  @override
  OrgTimeRangeTimestamp fromChildren(List<OrgNode> children) => copyWith(
        modifiers: children.cast<OrgTimestampModifier>(),
      );

  @override
  bool get isActive => prefix == '<' && suffix == '>';
  @override
  bool get repeats => modifiers.any((m) => m.isRepeater);
  @override
  bool get hasDelay => modifiers.any((m) => m.isDelay);

  DateTime get startDateTime => DateTime(
        int.parse(date.year),
        int.parse(date.month),
        int.parse(date.day),
        int.parse(timeStart.hour),
        int.parse(timeStart.minute),
      );

  DateTime get endDateTime => DateTime(
        int.parse(date.year),
        int.parse(date.month),
        int.parse(date.day),
        int.parse(timeEnd.hour),
        int.parse(timeEnd.minute),
      );

  @override
  String toString() => 'OrgTimeRangeTimestamp';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf.write(prefix);
    _toPlainTextImpl(buf);
    buf.write(suffix);
  }

  @override
  void _toPlainTextImpl(OrgSerializer buf) {
    buf
      ..write(date.year)
      ..write('-')
      ..write(date.month)
      ..write('-')
      ..write(date.day);
    if (date.dayName != null) {
      buf
        ..write(' ')
        ..write(date.dayName!);
    }
    buf
      ..write(' ')
      ..write(timeStart.hour)
      ..write(':')
      ..write(timeStart.minute)
      ..write('-')
      ..write(timeEnd.hour)
      ..write(':')
      ..write(timeEnd.minute);
    if (modifiers.isNotEmpty) {
      buf.write(' ');
      for (var i = 0; i < modifiers.length; i++) {
        if (i > 0) buf.write(' ');
        buf.visit(modifiers[i]);
      }
    }
  }

  @override
  bool contains(Pattern pattern) =>
      prefix.contains(pattern) ||
      date.year.contains(pattern) ||
      date.month.contains(pattern) ||
      date.day.contains(pattern) ||
      date.dayName?.contains(pattern) == true ||
      timeStart.hour.contains(pattern) ||
      timeStart.minute.contains(pattern) ||
      timeEnd.hour.contains(pattern) ||
      timeEnd.minute.contains(pattern) ||
      modifiers.any((m) => m.contains(pattern)) ||
      suffix.contains(pattern);

  OrgTimeRangeTimestamp copyWith({
    String? prefix,
    OrgDate? date,
    OrgTime? timeStart,
    OrgTime? timeEnd,
    Iterable<OrgTimestampModifier>? modifiers,
    String? suffix,
  }) =>
      OrgTimeRangeTimestamp(
        prefix ?? this.prefix,
        date ?? this.date,
        timeStart ?? this.timeStart,
        timeEnd ?? this.timeEnd,
        modifiers ?? this.modifiers,
        suffix ?? this.suffix,
      );
}
