import 'dart:math';

bool isOrgLocalSectionUrl(String url) => url.startsWith('*');

/// Return the title of the section pointed to by the URL. The URL must be one
/// for which [isOrgLocalSectionUrl] returns true.
String parseOrgLocalSectionUrl(String url) {
  assert(isOrgLocalSectionUrl(url));
  return url.substring(1);
}

abstract class OrgTree {
  OrgTree(this.content, [Iterable<OrgSection> children])
      : children = List.unmodifiable(children ?? const []);
  final OrgContent content;
  final List<OrgSection> children;

  int get level;
}

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

class OrgSection extends OrgTree {
  OrgSection(
    this.headline,
    OrgContent content, [
    Iterable<OrgSection> children,
  ]) : super(content, children);
  final OrgHeadline headline;

  @override
  int get level => headline.level;

  bool get isEmpty => content == null && children.isEmpty;

  OrgSection copyWith({
    OrgHeadline headline,
    OrgContent content,
    Iterable<OrgSection> children,
  }) =>
      OrgSection(
        headline ?? this.headline,
        content ?? this.content,
        children ?? this.children,
      );
}

abstract class OrgContentElement {}

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
  OrgTable(Iterable<OrgTableRow> rows)
      : rows = List.unmodifiable(rows ?? const []);

  final List<OrgTableRow> rows;

  String get indent => rows.isEmpty ? '' : rows.first.indent;

  bool get rectangular =>
      rows
          .map((row) => row.cellCount)
          .where((count) => count >= 0)
          .toSet()
          .length <
      2;

  int get columnCount => rows.map((row) => row.cellCount).reduce(max);
}

abstract class OrgTableRow extends OrgContentElement {
  OrgTableRow(this.indent) : assert(indent != null);

  final String indent;

  int get cellCount;
}

class OrgTableDividerRow extends OrgTableRow {
  OrgTableDividerRow(String indent) : super(indent);

  @override
  int get cellCount => -1;
}

class OrgTableCellRow extends OrgTableRow {
  OrgTableCellRow(String indent, Iterable<OrgContent> cells)
      : cells = List.unmodifiable(cells ?? const []),
        super(indent);

  final List<OrgContent> cells;

  @override
  int get cellCount => cells.length;
}

class OrgTimestamp extends OrgContentElement {
  OrgTimestamp(this.content) : assert(content != null);

  // TODO(aaron): Expose actual data
  final String content;
}

class OrgKeyword extends OrgContentElement {
  OrgKeyword(this.content) : assert(content != null);

  final String content;
}

class OrgFixedWidthArea extends OrgContentElement {
  OrgFixedWidthArea(this.content) : assert(content != null);

  final String content;
}
