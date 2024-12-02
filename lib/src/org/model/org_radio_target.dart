part of '../model.dart';

/// A link target, like
/// ```
/// <<<target>>>
/// ```
class OrgRadioTarget extends OrgLeafNode {
  OrgRadioTarget(this.leading, this.body, this.trailing);

  final String leading;
  final String body;
  final String trailing;

  @override
  bool contains(Pattern pattern) =>
      leading.contains(pattern) ||
      body.contains(pattern) ||
      trailing.contains(pattern);

  @override
  String toString() => 'OrgRadioTarget';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write(leading)
      ..write(body)
      ..write(trailing);
  }
}
