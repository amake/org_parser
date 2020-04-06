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

  bool contains(Pattern pattern, {bool includeChildren = true}) {
    if (content != null && content.contains(pattern)) {
      return true;
    }
    return includeChildren && children.any((child) => child.contains(pattern));
  }
}

class OrgHeadline {
  OrgHeadline(
    this.stars,
    this.keyword,
    this.priority,
    this.title,
    this.rawTitle, [
    Iterable<String> tags = const [],
  ]) : tags = List.unmodifiable(tags ?? const []);
  final String stars;
  final String keyword;
  final String priority;
  final OrgContent title;

  // For resolving links
  final String rawTitle;
  final List<String> tags;

  int get level => stars.length;

  bool contains(Pattern pattern) =>
      keyword != null && keyword.contains(pattern) ||
      title != null && title.contains(pattern) ||
      tags.any((tag) => tag.contains(pattern));
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

  @override
  bool contains(Pattern pattern, {bool includeChildren = true}) =>
      headline.contains(pattern) ||
      super.contains(pattern, includeChildren: includeChildren);
}

// ignore: one_member_abstracts
abstract class OrgContentElement {
  bool contains(Pattern pattern);
}

mixin SingleContentElement {
  String get content;

  bool contains(Pattern pattern) => content.contains(pattern);
}

class OrgContent extends OrgContentElement {
  OrgContent(Iterable<OrgContentElement> children)
      : children = List.unmodifiable(children),
        assert(children != null);

  final List<OrgContentElement> children;

  @override
  bool contains(Pattern pattern) =>
      children.any((child) => child.contains(pattern));
}

class OrgPlainText extends OrgContentElement with SingleContentElement {
  OrgPlainText(this.content) : assert(content != null);
  @override
  final String content;
}

class OrgLink extends OrgContentElement {
  OrgLink(this.location, this.description) : assert(location != null);
  final String location;
  final String description;

  @override
  bool contains(Pattern pattern) =>
      location.contains(pattern) ||
      description != null && description.contains(pattern);
}

class OrgMarkup extends OrgContentElement with SingleContentElement {
  OrgMarkup(this.content, this.style)
      : assert(content != null),
        assert(style != null);
  @override
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
  OrgMeta(this.indent, this.keyword, this.trailing)
      : assert(indent != null),
        assert(keyword != null),
        assert(trailing != null);

  final String indent;
  final String keyword;
  final String trailing;

  @override
  bool contains(Pattern pattern) {
    return indent.contains(pattern) ||
        keyword.contains(pattern) ||
        trailing.contains(pattern);
  }
}

class OrgBlock extends OrgContentElement {
  OrgBlock(this.indent, this.header, this.body, this.footer)
      : assert(indent != null),
        assert(header != null),
        assert(body != null),
        assert(footer != null);
  final String indent;
  final String header;
  final OrgContentElement body;
  final String footer;

  @override
  bool contains(Pattern pattern) =>
      header.contains(pattern) ||
      body.contains(pattern) ||
      footer.contains(pattern);
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

  @override
  bool contains(Pattern pattern) => rows.any((row) => row.contains(pattern));
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

  @override
  bool contains(Pattern pattern) => false;
}

class OrgTableCellRow extends OrgTableRow {
  OrgTableCellRow(String indent, Iterable<OrgContent> cells)
      : cells = List.unmodifiable(cells ?? const []),
        super(indent);

  final List<OrgContent> cells;

  @override
  int get cellCount => cells.length;

  @override
  bool contains(Pattern pattern) => cells.any((cell) => cell.contains(pattern));
}

class OrgTimestamp extends OrgContentElement with SingleContentElement {
  OrgTimestamp(this.content) : assert(content != null);

  // TODO(aaron): Expose actual data
  @override
  final String content;
}

class OrgKeyword extends OrgContentElement with SingleContentElement {
  OrgKeyword(this.content) : assert(content != null);

  @override
  final String content;
}

class OrgFixedWidthArea extends OrgContentElement {
  OrgFixedWidthArea(this.indent, this.content)
      : assert(indent != null),
        assert(content != null);

  final String indent;
  final String content;

  @override
  bool contains(Pattern pattern) {
    return indent.contains(pattern) || content.contains(pattern);
  }
}

class OrgList extends OrgContentElement {
  OrgList(Iterable<OrgListItem> items) : items = List.unmodifiable(items ?? []);
  final List<OrgListItem> items;

  @override
  bool contains(Pattern pattern) => items.any((item) => item.contains(pattern));
}

class OrgListItem extends OrgContentElement {
  OrgListItem(this.indent, this.bullet, this.checkbox, this.body)
      : assert(indent != null),
        assert(bullet != null);

  final String indent;
  final String bullet;
  final String checkbox;
  final OrgContent body;

  @override
  bool contains(Pattern pattern) =>
      indent.contains(pattern) ||
      bullet.contains(pattern) ||
      checkbox != null && checkbox.contains(pattern) ||
      body != null && body.contains(pattern);
}

class OrgListUnorderedItem extends OrgListItem {
  OrgListUnorderedItem(
    String indent,
    String bullet,
    String checkbox,
    this.tag,
    OrgContent body,
  ) : super(indent, bullet, checkbox, body);

  final String tag;

  @override
  bool contains(Pattern pattern) =>
      tag != null && tag.contains(pattern) || super.contains(pattern);
}

class OrgListOrderedItem extends OrgListItem {
  OrgListOrderedItem(
    String indent,
    String bullet,
    this.counterSet,
    String checkbox,
    OrgContent body,
  ) : super(indent, bullet, checkbox, body);

  final String counterSet;

  @override
  bool contains(Pattern pattern) =>
      counterSet != null && counterSet.contains(pattern) ||
      super.contains(pattern);
}
