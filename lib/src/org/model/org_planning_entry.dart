part of '../model.dart';

/// A planning keyword, like `SCHEDULED:` or `DEADLINE:`
class OrgPlanningKeyword extends OrgLeafNode with SingleContentElement {
  OrgPlanningKeyword(this.content);

  @override
  final String content;

  @override
  String toString() => 'OrgKeyword';
}

/// A planning line, like
/// ```
/// SCHEDULED: <2021-12-09 Thu>
/// ```
/// or
/// ```
/// CLOSED: [2021-12-09 Thu 12:02]
/// ```
class OrgPlanningEntry extends OrgParentNode {
  OrgPlanningEntry(
    this.keyword,
    this.separator,
    this.value, [
    super.id,
  ]);

  final OrgPlanningKeyword keyword;
  final String separator;
  final OrgNode value;

  @override
  List<OrgNode> get children => [keyword, value];

  @override
  OrgPlanningEntry fromChildren(List<OrgNode> children) => copyWith(
        keyword: children[0] as OrgPlanningKeyword,
        value: children[1],
      );

  @override
  bool contains(Pattern pattern) =>
      keyword.contains(pattern) ||
      separator.contains(pattern) ||
      value.contains(pattern);

  @override
  String toString() => 'OrgPlanningEntry';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..visit(keyword)
      ..write(separator)
      ..visit(value);
  }

  OrgPlanningEntry copyWith({
    OrgPlanningKeyword? keyword,
    String? separator,
    OrgNode? value,
    String? id,
  }) =>
      OrgPlanningEntry(
        keyword ?? this.keyword,
        separator ?? this.separator,
        value ?? this.value,
        id ?? this.id,
      );
}
