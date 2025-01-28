part of '../model.dart';

/// A "meta" line, like
/// ```
/// #+KEYWORD: some-named-thing
/// ```
///
/// TODO(aaron): Should this be renamed to `OrgKeyword`?
class OrgMeta extends OrgParentNode with OrgElement {
  OrgMeta(this.indent, this.key, this.value, this.trailing);

  @override
  final String indent;

  /// The key, including the leading `#+` and trailing `:`.
  final String key;
  final OrgContent? value;
  @override
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      key.contains(pattern) ||
      value?.contains(pattern) == true ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgMeta';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(indent)
      ..write(key);
    if (value != null) {
      buf.visit(value!);
    }
    buf.write(trailing);
  }

  @override
  List<OrgNode> get children => (value == null) ? const [] : [value!];

  @override
  OrgParentNode fromChildren(List<OrgNode> children) =>
      copyWith(value: children.singleOrNull as OrgContent?);

  OrgMeta copyWith({
    String? indent,
    String? key,
    OrgContent? value,
    String? trailing,
  }) {
    return OrgMeta(
      indent ?? this.indent,
      key ?? this.key,
      value ?? this.value,
      trailing ?? this.trailing,
    );
  }
}
