part of '../model.dart';

class OrgParagraph extends OrgParentNode with OrgElement {
  OrgParagraph(this.indent, this.body, this.trailing, [super.id]);

  @override
  final String indent;
  final OrgContent body;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [body];

  @override
  OrgParagraph fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single as OrgContent);

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      body.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgParagraph';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..visit(body)
      ..write(trailing);
  }

  @override
  OrgParagraph copyWith({
    String? indent,
    OrgContent? body,
    String? trailing,
    String? id,
  }) =>
      OrgParagraph(
        indent ?? this.indent,
        body ?? this.body,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}
