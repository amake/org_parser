part of '../model.dart';

/// A horizontal rule, like
/// ```
/// -----
/// ```
class OrgHorizontalRule extends OrgLeafNode with OrgElement {
  OrgHorizontalRule(this.indent, this.content, this.trailing);

  @override
  final String indent;
  final String content;
  @override
  final String trailing;

  @override
  String toString() => 'OrgMacroReference';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(content)
      ..write(trailing);
  }

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      content.contains(pattern) ||
      trailing.contains(pattern);

  @override
  OrgHorizontalRule copyWith({
    String? indent,
    String? content,
    String? trailing,
  }) =>
      OrgHorizontalRule(
        indent ?? this.indent,
        content ?? this.content,
        trailing ?? this.trailing,
      );
}
