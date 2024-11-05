part of '../model.dart';

class OrgComment extends OrgLeafNode {
  OrgComment(this.indent, this.start, this.content);

  final String indent;
  final String start;
  final String content;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      start.contains(pattern) ||
      content.contains(pattern);

  @override
  _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(start)
      ..write(content);
  }
}
