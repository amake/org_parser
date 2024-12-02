part of '../model.dart';

/// A link target, like
/// ```
/// <<target>>
/// ```
class OrgLinkTarget extends OrgLeafNode {
  OrgLinkTarget(this.leading, this.body, this.trailing);

  final String leading;
  final String body;
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      body.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgLinkTarget';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(body)
      ..write(trailing);
  }
}
