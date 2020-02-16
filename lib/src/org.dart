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
  final OrgContent content;
  final List<OrgSection> children;

  int get level => headline.level;

  OrgSection copyWith(
          {OrgHeadline headline,
          String content,
          Iterable<OrgSection> children}) =>
      OrgSection(headline ?? this.headline, content ?? this.content,
          children ?? this.children);
}

class OrgContent {
  OrgContent(Iterable<OrgContent> children)
      : children = List.unmodifiable(children),
        assert(children != null);

  final List<OrgContent> children;
}

class OrgPlainText extends OrgContent {
  OrgPlainText(this.content)
      : assert(content != null),
        super(const []);
  final String content;
}

class OrgLink extends OrgContent {
  OrgLink(this.location, this.description)
      : assert(location != null),
        super(const []);
  final String location;
  final String description;
}

class OrgMarkup extends OrgContent {
  OrgMarkup(this.content, this.style)
      : assert(style != null),
        super(const []);
  final String content;
  final OrgStyle style;
}

enum OrgStyle {
  bold,
  verbatim,
  italic,
  strikeThrough,
  underline,
  code,
}
