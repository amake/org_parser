part of '../model.dart';

/// An Org section. May have nested sections, like
///
/// ```
/// * TODO [#A] COMMENT Title :tag1:tag2:
/// content
/// ** Sub section
/// more content
/// ```
class OrgSection extends OrgTree {
  OrgSection(
    this.headline,
    super.content, [
    super.sections,
    super.id,
  ]);
  final OrgHeadline headline;

  /// The section's tags. Convenience accessor for tags of [headline].
  List<String> get tags => headline.tags?.values ?? const [];

  /// Returns the tags of this section and all parent sections.
  List<String> tagsWithInheritance(OrgTree doc) =>
      doc
          .find((node) => identical(node, this))
          ?.path
          .whereType<OrgSection>()
          .fold<List<String>>([], (acc, node) => acc..addAll(node.tags)) ??
      const [];

  @override
  List<OrgNode> get children => [headline, ...super.children];

  @override
  OrgSection fromChildren(List<OrgNode> children) {
    final headline = children.first as OrgHeadline;
    if (children.length < 2) {
      return copyWith(headline: headline);
    }
    final content =
        children[1] is OrgContent ? children[1] as OrgContent : null;
    final sections = content == null ? children.skip(1) : children.skip(2);
    return copyWith(
      headline: headline,
      content: content,
      sections: sections.cast(),
    );
  }

  @override
  int get level => headline.level;

  /// A section may be empty if it has no content or sub-sections
  bool get isEmpty => content == null && sections.isEmpty;

  OrgSection copyWith({
    OrgHeadline? headline,
    OrgContent? content,
    Iterable<OrgSection>? sections,
    String? id,
  }) =>
      OrgSection(
        headline ?? this.headline,
        content ?? this.content,
        sections ?? this.sections,
        id ?? this.id,
      );

  @override
  bool contains(Pattern pattern, {bool includeChildren = true}) =>
      headline.contains(pattern) ||
      super.contains(pattern, includeChildren: includeChildren);

  @override
  String toString() => 'OrgSection';
}
