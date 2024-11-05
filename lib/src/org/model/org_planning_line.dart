part of '../model.dart';

/// A planning keyword, like `SCHEDULED:` or `DEADLINE:`
///
/// TODO(aaron): Rename this to "OrgPlanningKeyword"?
class OrgKeyword extends OrgLeafNode with SingleContentElement {
  OrgKeyword(this.content);

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
class OrgPlanningLine extends OrgParentNode with IndentedElement {
  OrgPlanningLine(
    this.indent,
    this.keyword,
    this.body,
    this.trailing, [
    super.id,
  ]);

  @override
  final String indent;
  final OrgKeyword keyword;
  final OrgContent body;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [keyword, body];

  @override
  OrgPlanningLine fromChildren(List<OrgNode> children) => copyWith(
        keyword: children[0] as OrgKeyword,
        body: children[1] as OrgContent,
      );

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      keyword.contains(pattern) ||
      body.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgPlanningLine';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..visit(keyword)
      ..visit(body)
      ..write(trailing);
  }

  OrgPlanningLine copyWith({
    String? indent,
    OrgKeyword? keyword,
    OrgContent? body,
    String? trailing,
    String? id,
  }) =>
      OrgPlanningLine(
        indent ?? this.indent,
        keyword ?? this.keyword,
        body ?? this.body,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}
