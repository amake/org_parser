part of '../model.dart';

/// A horizontal rule, like
/// ```
/// -----
/// ```
class OrgHorizontalRule extends OrgLeafNode {
  OrgHorizontalRule(this.content, this.trailing);

  final String content;
  final String trailing;

  @override
  String toString() => 'OrgMacroReference';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(content)
      ..write(trailing);
  }

  @override
  bool contains(Pattern pattern) =>
      content.contains(pattern) || trailing.contains(pattern);
}
