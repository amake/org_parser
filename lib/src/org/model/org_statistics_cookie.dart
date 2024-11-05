part of '../model.dart';

sealed class OrgStatisticsCookie extends OrgLeafNode {
  OrgStatisticsCookie(this.leading, this.trailing);

  final String leading;
  final String trailing;

  bool get done;

  OrgStatisticsCookie update({required int done, required int total});
}

class OrgStatisticsFractionCookie extends OrgStatisticsCookie {
  OrgStatisticsFractionCookie(
    super.leading,
    this.numerator,
    this.separator,
    this.denominator,
    super.trailing,
  );

  final String numerator;
  final String separator;
  final String denominator;

  @override
  bool get done => numerator.isNotEmpty && numerator == denominator;

  @override
  OrgStatisticsCookie update({required int done, required int total}) =>
      copyWith(numerator: done.toString(), denominator: total.toString());

  @override
  String toString() => 'OrgStatisticsFractionCookie';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(numerator)
      ..write(separator)
      ..write(denominator)
      ..write(trailing);
  }

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      numerator.contains(pattern) ||
      separator.contains(pattern) ||
      denominator.contains(pattern) ||
      trailing.contains(pattern);

  OrgStatisticsFractionCookie copyWith({
    String? leading,
    String? numerator,
    String? separator,
    String? denominator,
    String? trailing,
  }) =>
      OrgStatisticsFractionCookie(
        leading ?? this.leading,
        numerator ?? this.numerator,
        separator ?? this.separator,
        denominator ?? this.denominator,
        trailing ?? this.trailing,
      );
}

class OrgStatisticsPercentageCookie extends OrgStatisticsCookie {
  OrgStatisticsPercentageCookie(
    super.leading,
    this.percentage,
    this.suffix,
    super.trailing,
  );

  final String percentage;
  final String suffix;

  @override
  bool get done => percentage == '100';

  @override
  OrgStatisticsCookie update({required int done, required int total}) =>
      copyWith(
        percentage: done == 0 ? '0' : (done / total * 100).round().toString(),
      );

  @override
  String toString() => 'OrgStatisticsPercentageCookie';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(percentage)
      ..write(suffix)
      ..write(trailing);
  }

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      percentage.contains(pattern) ||
      suffix.contains(pattern) ||
      trailing.contains(pattern);

  OrgStatisticsPercentageCookie copyWith({
    String? leading,
    String? percentage,
    String? suffix,
    String? trailing,
  }) =>
      OrgStatisticsPercentageCookie(
        leading ?? this.leading,
        percentage ?? this.percentage,
        suffix ?? this.suffix,
        trailing ?? this.trailing,
      );
}
