part of '../model.dart';

class OrgComment extends OrgLeafNode with OrgElement {
  OrgComment(this.indent, this.start, this.content, this.trailing);

  @override
  final String indent;
  final String start;
  final String content;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      start.contains(pattern) ||
      content.contains(pattern) ||
      trailing.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(start)
      ..write(content)
      ..write(trailing);
  }

  @override
  OrgComment copyWith({
    String? indent,
    String? start,
    String? content,
    String? trailing,
  }) =>
      OrgComment(
        indent ?? this.indent,
        start ?? this.start,
        content ?? this.content,
        trailing ?? this.trailing,
      );
}
