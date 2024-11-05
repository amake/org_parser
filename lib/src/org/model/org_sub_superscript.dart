part of '../model.dart';

sealed class OrgSubSuperscript extends OrgParentNode {
  OrgSubSuperscript(this.leading, this.body, this.trailing);

  final String leading;
  final OrgContent body;
  final String trailing;

  @override
  List<OrgNode> get children => [body];

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      body.contains(pattern) ||
      trailing.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..visit(body)
      ..write(trailing);
  }
}

class OrgSubscript extends OrgSubSuperscript {
  OrgSubscript(super.leading, super.body, super.trailing);

  @override
  String toString() => 'OrgSubscript';

  @override
  OrgSubscript fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single as OrgContent);

  OrgSubscript copyWith({
    String? leading,
    OrgContent? body,
    String? trailing,
  }) =>
      OrgSubscript(
        leading ?? this.leading,
        body ?? this.body,
        trailing ?? this.trailing,
      );
}

class OrgSuperscript extends OrgSubSuperscript {
  OrgSuperscript(super.leading, super.body, super.trailing);

  @override
  String toString() => 'OrgSuperscript';

  @override
  OrgSuperscript fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single as OrgContent);

  OrgSuperscript copyWith({
    String? leading,
    OrgContent? body,
    String? trailing,
  }) =>
      OrgSuperscript(
        leading ?? this.leading,
        body ?? this.body,
        trailing ?? this.trailing,
      );
}
