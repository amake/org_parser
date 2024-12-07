part of '../model.dart';

mixin OrgLink on OrgNode {
  /// Where the link points
  String get location;
}

/// A link, like
/// ```
/// https://example.com
/// ```
class OrgPlainLink extends OrgLeafNode with OrgLink {
  OrgPlainLink(this.location);

  /// Where the link points
  @override
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
class OrgBracketLink extends OrgParentNode with OrgLink {
  OrgBracketLink(this.location, this.description);

  /// Where the link points
  @override
  final String location;

  /// The user-visible text
  final OrgContent? description;

  @override
  bool contains(Pattern pattern) =>
      location.contains(pattern) || description?.contains(pattern) == true;

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
            .toMarkup()
            .replaceAll(']]', ']\u200b]')
            .replaceAll(RegExp(r']$'), ']\u200b'));
    }
    buf.write(']]');
  }

  @override
  List<OrgNode> get children => description == null ? const [] : [description!];

  @override
  OrgParentNode fromChildren(List<OrgNode> children) =>
      copyWith(description: children.single as OrgContent);

  OrgBracketLink copyWith({
    String? location,
    OrgContent? description,
  }) =>
      OrgBracketLink(
        location ?? this.location,
        description ?? this.description,
      );
}
