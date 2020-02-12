class OrgHeadline {
  OrgHeadline(
    this.stars,
    this.keyword,
    this.priority,
    this.title, [
    Iterable<String> tags = const [],
  ]) : tags = List.unmodifiable(tags ?? const []);
  final String stars;
  final String keyword;
  final String priority;
  final String title;
  final List<String> tags;

  int get level => stars.length;
}

class OrgSection {
  OrgSection(
    this.headline,
    this.content, [
    Iterable<OrgSection> children = const [],
  ]) : children = List.unmodifiable(children ?? const []);
  final OrgHeadline headline;
  final String content;
  final List<OrgSection> children;

  int get level => headline.level;

  OrgSection copyWith(
          {OrgHeadline headline,
          String content,
          Iterable<OrgSection> children}) =>
      OrgSection(headline ?? this.headline, content ?? this.content,
          children ?? this.children);
}
