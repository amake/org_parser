part of '../model.dart';

/// A "meta" line, like
/// ```
/// #+KEYWORD: some-named-thing
/// ```
///
/// TODO(aaron): Should this be renamed to `OrgKeyword`?
class OrgMeta extends OrgLeafNode with IndentedElement {
  OrgMeta(this.indent, this.keyword, this.trailing);

  @override
  final String indent;
  final String keyword;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) {
    return indent.contains(pattern) ||
        keyword.contains(pattern) ||
        trailing.contains(pattern);
  }

  @override
  String toString() => 'OrgMeta';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(keyword)
      ..write(trailing);
  }
}
