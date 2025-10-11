part of '../model.dart';

/// Extracts the radio targets from the given [tree].
Set<String> extractRadioTargets(
  OrgTree tree,
) {
  final results = <String>{};
  tree.visit<OrgRadioTarget>((target) {
    final t = target.body.toLowerCase().trim();
    if (t.isNotEmpty) {
      results.add(t);
    }
    return true;
  });
  return results;
}

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

  @override
  void _toPlainTextImpl(OrgSerializer buf) {
    buf.write(body);
  }
}

/// A word linkified to point to a radio target. This can only appear in a
/// parsed tree if radio targets were supplied to the parser.
class OrgRadioLink extends OrgLeafNode with SingleContentElement {
  OrgRadioLink(this.content);

  /// Where the link points
  @override
  final String content;

  @override
  String toString() => 'OrgRadioLink';
}
