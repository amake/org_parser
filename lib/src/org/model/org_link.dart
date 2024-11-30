part of '../model.dart';

/// A link, like
/// ```
/// https://example.com
/// ```
class OrgLink extends OrgLeafNode {
  OrgLink(this.location);

  /// Where the link points
  final String location;

  @override
  bool contains(Pattern pattern) => location.contains(pattern);

  @override
  String toString() => 'OrgLink';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf.write(location);
  }
}

/// A bracketed link, like
/// ```
/// [[https://example.com][An example]]
/// ```
/// or
/// ```
/// [[https://example.com]]
/// ```
class OrgBracketLink extends OrgLink {
  OrgBracketLink(super.location, this.description);

  /// The user-visible text
  final String? description;

  @override
  bool contains(Pattern pattern) =>
      super.contains(pattern) || description?.contains(pattern) == true;

  @override
  String toString() => 'OrgLink';

  @override
  void _toMarkupImpl(OrgSerializer buf) {
    buf
      ..write('[[')
      ..write(location
          // Backslash must be first
          .replaceAll(r'\', r'\\')
          .replaceAll(r'[', r'\[')
          .replaceAll(r']', r'\]'));
    if (description != null) {
      buf
        ..write('][')
        ..write(description!
            .replaceAll(']]', ']\u200b]')
            .replaceAll(RegExp(r']$'), ']\u200b'));
    }
    buf.write(']]');
  }
}
