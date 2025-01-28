part of '../model.dart';

/// A "meta" line, like
/// ```
/// #+KEYWORD: some-named-thing
/// ```
///
/// TODO(aaron): Should this be renamed to `OrgKeyword`?
class OrgMeta extends OrgLeafNode with OrgElement {
  OrgMeta(this.indent, this.key, this.value, this.trailing);

  @override
  final String indent;

  /// The key, including the leading `#+` and trailing `:`.
  final String key;
  final String value;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      key.contains(pattern) ||
      value.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgMeta';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(key)
      ..write(value)
      ..write(trailing);
  }
}
