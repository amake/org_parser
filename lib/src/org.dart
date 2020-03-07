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
  final OrgContent title;
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

  bool get isEmpty => content == null && children.isEmpty;

  OrgSection copyWith(
          {OrgHeadline headline,
          String content,
          Iterable<OrgSection> children}) =>
      OrgSection(headline ?? this.headline, content ?? this.content,
          children ?? this.children);
}

class OrgContentElement {}

class OrgContent extends OrgContentElement {
  OrgContent(Iterable<OrgContentElement> children)
      : children = List.unmodifiable(children),
        assert(children != null);

  final List<OrgContentElement> children;
}

class OrgPlainText extends OrgContentElement {
  OrgPlainText(this.content) : assert(content != null);
  final String content;
}

class OrgLink extends OrgContentElement {
  OrgLink(this.location, this.description) : assert(location != null);
  final String location;
  final String description;
}

class OrgMarkup extends OrgContentElement {
  OrgMarkup(this.content, this.style) : assert(style != null);
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

class OrgMeta extends OrgContentElement {
  OrgMeta(this.content) : assert(content != null);
  final String content;
}

class OrgBlock extends OrgContentElement {
  OrgBlock(this.header, this.body, this.footer)
      : assert(header != null),
        assert(body != null),
        assert(footer != null);
  final String header;
  final OrgContentElement body;
  final String footer;
}

class OrgTable extends OrgContentElement {
  OrgTable(Iterable<String> rows) : rows = List.unmodifiable(rows ?? const []);

  // TODO(aaron): Expose cells
  final List<String> rows;
}
