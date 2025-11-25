part of '../model.dart';

/// ```
/// #+BEGIN: myblockfunc :parameter1 value1 :parameter2 value2
/// ...
/// #+END:
/// ```
class OrgDynamicBlock extends OrgParentNode with OrgElement {
  OrgDynamicBlock(
    this.indent,
    this.header,
    this.body,
    this.footer,
    this.trailing, [
    super.id,
  ]);

  @override
  final String indent;
  final String header;
  final OrgContent body;
  final String footer;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [body];

  @override
  OrgDynamicBlock fromChildren(List<OrgNode> children) =>
      copyWith(body: children.single as OrgContent);

  @override
  bool contains(Pattern pattern) =>
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern);

  @override
  String toString() => 'OrgDynamicBlock';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(header)
      ..visit(body)
      ..write(footer)
      ..write(trailing);
  }

  @override
  OrgDynamicBlock copyWith({
    String? type,
    String? indent,
    String? header,
    OrgContent? body,
    String? footer,
    String? trailing,
    String? id,
  }) =>
      OrgDynamicBlock(
        indent ?? this.indent,
        header ?? this.header,
        body ?? this.body,
        footer ?? this.footer,
        trailing ?? this.trailing,
        id ?? this.id,
      );
}
