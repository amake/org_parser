part of '../model.dart';

/// A fixed-width area, like
/// ```
/// : result of source block, or whatever
/// ```
class OrgFixedWidthArea extends OrgLeafNode with OrgElement {
  OrgFixedWidthArea(this.indent, this.content, this.trailing);

  @override
  final String indent;
  final String content;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      content.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgFixedWidthArea';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(content)
      ..write(trailing);
  }

  @override
  OrgFixedWidthArea copyWith({
    String? indent,
    String? content,
    String? trailing,
  }) =>
      OrgFixedWidthArea(
        indent ?? this.indent,
        content ?? this.content,
        trailing ?? this.trailing,
      );
}
