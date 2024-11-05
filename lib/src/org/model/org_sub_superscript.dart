part of '../model.dart';

// TODO(aaron): Add sealed superclass

class OrgSubscript extends OrgParentNode {
  OrgSubscript(this.leading, this.body, this.trailing);

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
  String toString() => 'OrgSubscript';

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..visit(body)
      ..write(trailing);
  }

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

class OrgSuperscript extends OrgParentNode {
  OrgSuperscript(this.leading, this.body, this.trailing);

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
  String toString() => 'OrgSuperscript';

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..visit(body)
      ..write(trailing);
  }

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
